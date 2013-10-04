require! {
    async
    canvg
    Canvas:canvas
    fs
    jsdom.jsdom
    $ : jquery
    './TileMaker'
    './TileJsonGenerator'
}
global.document = jsdom "<html><head></head><body>hello world</body></html>"
global.window = global.document.parentWindow
global.navigator = {userAgent: "webkit"}
require! L: leaflet

fixCdata = (str) ->
    str.replace "![CDATA[" "<![CDATA["

tileJsonGenerator = new TileJsonGenerator
filename = "protesty-2010"
(err, content) <~ fs.readFile "#__dirname/../data/#filename.svg"
fs.mkdir "#__dirname/../data/#filename"
console.log "Starting #filename"
content .= toString!
$content = $ "<div></div>"
$content.html content
$content.find "style" .remove!

originalImage = fixCdata $content.html!

$exportables = $content.find "[data-export]"
$exportables.each ->
    $ele = $ @
    exportable = $ele.attr \data-export
    index = tileJsonGenerator.getExportableIndex exportable
    color = tileJsonGenerator.getColorByIndex index
    $ele.attr \fill color

contouredExportsImage = fixCdata $content.html!
<~ async.eachSeries [6], (zoomLevel, cb) ->
    west = 12.09066916
    east = 18.859236427
    north = 51.055778242
    south = 48.55214327757924
    {x:x0, y:y0} = L.CRS.EPSG3857.latLngToPoint do
        new L.LatLng north, west
        zoomLevel
    {x:x1, y:y1} = L.CRS.EPSG3857.latLngToPoint do
        new L.LatLng south, east
        zoomLevel

    offsetX = x0 % 256
    offsetY = y0 % 256
    width   = Math.abs x0 - x1
    height  = Math.abs y0 - y1

    opts =
        offsetX: offsetX
        offsetY: offsetY
        scaleWidth: width
        scaleHeight: height
        ignoreDimensions: yes

    createImages = (svg, cb) ->
        canvas = new Canvas width + offsetX, height + offsetY
        canvg canvas, svg, opts
        buffer = canvas.toBuffer!
        <~ fs.writeFile "#__dirname/../data/#filename/test.png" buffer
        tilesDone = 0
        tileMaker = new TileMaker canvas, 256, 256, zoomLevel
            ..on \tile (z, x, y, canvas) ->
                buffer = canvas.toBuffer!
                <~ fs.mkdir "#__dirname/../data/#filename/#z"
                <~ fs.mkdir "#__dirname/../data/#filename/#z/#x"
                <~ fs.writeFile "#__dirname/../data/#filename/#z/#x/#y.png", buffer
                tilesDone++
                cb! if tilesDone == tileCount

        tileCount = tileMaker.makeTiles!

        #<~ fs.writeFile "#__dirname/../test.png", canvas.toBuffer!

    createJsons = (svg, cb) ->
        canvas = new Canvas width, height
        canvg canvas, svg, opts
        tilesDone = 0
        tileMaker = new TileMaker canvas, 256, 256, zoomLevel
            ..on \tile (z, x, y, canvas) ->
                tjson = tileJsonGenerator.generateJson canvas
                <~ fs.writeFile "#__dirname/../data/#filename/#z/#x/#y.json", JSON.stringify tjson#, null, "  "
                tilesDone++
                cb! if tilesDone == tileCount

        tileCount = tileMaker.makeTiles!

    console.log "Drawing tiles"
    <~ createImages originalImage
    # console.log "Computing JSONs"
    # <~ createJsons contouredExportsImage
    console.log "Done #zoomLevel"
    cb!

console.log "All done, cooling down..."
setTimeout process.exit, 2000
