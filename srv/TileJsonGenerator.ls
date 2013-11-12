/*
    This module provides method for generating the UTFGrid JSON. First, all
    exportable fields (paths) should be loaded by getExportableIndex and colored
    with getColorByIndex. Then, canvas with a such colored tile should be passed
    to generateJson, which outputs the resulting UTFGrid JSON.
*/

module.exports = class TileJsonGenerator
    exportables: null
    colorInterval: 5 # this is used to better differentiate between areas
    jsonGranularity: 4 # side length of one cell in UTFGrid
    ->
        @exportables = [ null ]

    generateJson: (canvas) ->
        ctx = canvas.getContext \2d
        keys = [ "0" ]
        data = { "0": null}
        grid = for y in [0 til canvas.height by @jsonGranularity]
            cols = for x in [0 til canvas.width by @jsonGranularity]
                id = @getJsonCellId ctx, x, y
                index = keys.indexOf id
                if index == -1
                    len = keys.push id
                    data[id] = JSON.parse @exportables[id]
                    index = len - 1
                chr = @idToChar index
                chr
            cols.join ''
        {grid, keys, data}

    getExportableIndex: (str) ->
        index = @exportables.indexOf str
        if index != -1
            return index
        length = @exportables.push str
        return length - 1

    getColorByIndex: (index) ->
        index *= @colorInterval
        color = index.toString 16
        while color.length < 6
            color = "0" + color
        "#" + color

    getJsonCellId: (ctx, x, y) ->
        # due to anti-aliasing of the image, getting the CellID does require a little guesswork
        scores = {}
        attemptCount = @jsonGranularity ^ 2
        for dx in [0 til @jsonGranularity]
            for dy in [0 til @jsonGranularity]
                if @getCellIdAtPixel ctx, x + dx, y + dy
                    scores[that] ?= 0
                    scores[that]++
        maxScore = -Infinity
        maxScoreId = null
        for id, score of scores
            if score >= attemptCount / 2
                # directly return id if over half the area is cover by that color
                return id
            else if score > maxScore
                maxScore = score
                maxScoreId = id
        if maxScore >= attemptCount / 4
            # if over 1/4th of area is of this color, guess we're right
            return maxScoreId
        return 0

    getCellIdAtPixel: (ctx, x, y) ->
        {data} = ctx.getImageData x, y, 1, 1
        [r, g, b] = data
        id = (r .<<. 16) .|. (g .<<. 8) .|. b
        id /= @colorInterval
        if @exportables[id]
            id
        else
            null

    idToChar: (id) -> # UTFGrid standard
        id += 32
        if id >= 34 then id += 1
        if id >= 92 then id += 1
        String.fromCharCode id

