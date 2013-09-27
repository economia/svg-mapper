module.exports = class TileJsonGenerator
    exportables: null
    colorInterval: 5
    jsonGranularity: 4 # 64 x 4 = 256
    ->
        @exportables = [ null ]
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

    generateJson: (canvas) ->
        ctx = canvas.getContext \2d
        keys = [ 0 ]
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
        # grid.join "\n"


    getJsonCellId: (ctx, x, y) ->
        scores = {}
        attemptCount = @jsonGranularity ^ 2
        for dx in [0 til @jsonGranularity]
            for dy in [0 til @jsonGranularity]
                if @getDataAtPixel ctx, x + dx, y + dy
                    scores[that] ?= 0
                    scores[that]++
        maxScore = -Infinity
        maxScoreId = null
        for id, score of scores
            return id if score >= attemptCount / 2
            if score > maxScore
                maxScore = score
                maxScoreId = id
        if maxScore >= attemptCount / 4
            return maxScoreId
        return 0

    getDataAtPixel: (ctx, x, y) ->
        {data} = ctx.getImageData x, y, 1, 1
        [r, g, b] = data
        id = (r .<<. 16) .|. (g .<<. 8) .|. b
        id /= @colorInterval
        if @exportables[id]
            id
        else
            null

    idToChar: (id) ->
        id += 32
        if id >= 34 then id += 1
        if id >= 92 then id += 1
        String.fromCharCode id

