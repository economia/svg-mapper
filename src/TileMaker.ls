/*
    Slices provides sourceCanvas to tiles dimensioned tileWidth x tileHeight
    Emits Tile event with tile number (web mercator - zoomlevel/x/y) and Canvas
    containing the tile imagery
*/
require! {
    Canvas:canvas
    events.EventEmitter
}
module.exports = class TileMaker extends EventEmitter
    (@sourceCanvas, [@tileWidth, @tileHeight], @zoomLevel) ->

    makeTiles: ->
        sourceContext = @sourceCanvas.getContext \2d
        cols = Math.ceil @sourceCanvas.width / @tileWidth
        rows = Math.ceil @sourceCanvas.height / @tileHeight
        tileCount = cols * rows
        z = @zoomLevel
        process.nextTick ~>
            tile = new Canvas @tileWidth, @tileHeight
            tileCtx = tile.getContext \2d
            for x in [0 til cols]
                for y in [0 til rows]
                    offX = x * @tileWidth
                    offY = y * @tileHeight
                    imageData = sourceContext.getImageData do
                        offX
                        offY
                        @tileWidth
                        @tileHeight
                    tileCtx.clearRect 0, 0, @tileWidth, @tileHeight
                    tileCtx.putImageData imageData, 0, 0
                    @emit \tile z, x, y, tile

        return tileCount

log2 = (val) ->
    Math.log val / Math.LN2
