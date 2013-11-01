require! {
    zlib
    async
    canvg
    Canvas:canvas
    fs
    jsdom.jsdom
    optimist.argv
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

existingDirs = {}
filename = argv.f
zoomLevel = argv.z
tileJsonGenerator = new TileJsonGenerator
(err, content) <~ fs.readFile "#__dirname/../data/#filename.svg"
(err) <~ fs.mkdir "#__dirname/../data/#filename"
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
console.log "#zoomLevel: start"
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

tileCountOffsetX = Math.floor x0 / 256
tileCountOffsetY = Math.floor y0 / 256

opts =
    offsetX: offsetX
    offsetY: offsetY
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes

createImages = (svg, cb) ->
    canvas = new Canvas width + offsetX, height + offsetY
    canvg canvas, svg, opts
    tilesDone = 0
    tileMaker = new TileMaker canvas, [256, 256], zoomLevel
        ..on \tile (z, x, y, canvas) ->
            x += tileCountOffsetX
            y += tileCountOffsetY
            buffer = canvas.toBuffer!
            if not existingDirs["#filename/#z"]
                fs.mkdirSync "#__dirname/../data/#filename/#z"
                existingDirs["#filename/#z"] := true
            if not existingDirs["#filename/#z/#x"]
                fs.mkdirSync "#__dirname/../data/#filename/#z/#x"
                existingDirs["#filename/#z/#x"] := true
            <~ fs.writeFile "#__dirname/../data/#filename/#z/#x/#y.png", buffer
            tilesDone++
            cb! if tilesDone == tileCount

    tileCount = tileMaker.makeTiles!

    #<~ fs.writeFile "#__dirname/../test.png", canvas.toBuffer!

createJsons = (svg, cb) ->
    canvas = new Canvas width + offsetX, height + offsetY
    canvg canvas, svg, opts
    tilesDone = 0
    tileMaker = new TileMaker canvas, [256, 256], zoomLevel
        ..on \tile (z, x, y, canvas) ->
            x += tileCountOffsetX
            y += tileCountOffsetY
            tjson = tileJsonGenerator.generateJson canvas
            data = JSON.stringify tjson
            <~ fs.writeFile "#__dirname/../data/#filename/#z/#x/#y.json", data
            (err, compressed) <~ zlib.gzip data
            <~ fs.writeFile "#__dirname/../data/#filename/#z/#x/#y.json.gz", compressed
            tilesDone++
            cb! if tilesDone == tileCount

    tileCount = tileMaker.makeTiles!

console.log "#zoomLevel: tiles"
<~ createImages originalImage
console.log "#zoomLevel: JSON"
<~ createJsons contouredExportsImage
console.log "#zoomLevel: done"
console.log "All done, cooling down..."
setTimeout process.exit, 2000
