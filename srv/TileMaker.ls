require! {
    Canvas:canvas
    events.EventEmitter
}
module.exports = class TileMaker extends EventEmitter
    (@sourceCanvas, @tileWidth, @tileHeight, @zoomLevel = null) ->

    makeTiles: ->
        sourceContext = @sourceCanvas.getContext \2d
        tile = new Canvas @tileWidth, @tileHeight
        tileCtx = tile.getContext \2d
        cols = Math.ceil @sourceCanvas.width / @tileWidth
        rows = Math.ceil @sourceCanvas.height / @tileHeight
        tileCount = Math.max cols, rows
        z = @zoomLevel || Math.ceil log2 tileCount
        console.log "Generating zoomlevel #z"
        for x in [0 til cols]
            for y in [0 til rows]
                offX = x * @tileWidth
                offY = y * @tileHeight
                imageData = sourceContext.getImageData do
                    offX
                    offY
                    @tileWidth
                    @tileHeight
                tileCtx.putImageData imageData, 0, 0
                @emit \tile z, x, y, tile.toBuffer!

log2 = (val) ->
    Math.log val / Math.LN2
