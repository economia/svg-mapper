require! {
    zlib
    async
    canvg
    Canvas:canvas
    fs
    jsdom.jsdom
    optimist
    $ : jquery
    './TileMaker'
    './TileJsonGenerator'
}
optimist
    .usage "Usage: $0 -f [filename] -z [num]"
    .demand ["f" "z"]
    .describe "f" "SVG file to use"
    .describe "z" "Zoom level to generate"
argv = optimist.argv

# following globals are for Leaflet, which depends on them
global.document = jsdom "<html><head></head><body>hello world</body></html>"
global.window = global.document.parentWindow
global.navigator = {userAgent: "webkit"}
require! L: leaflet


filename = argv.f
zoomLevel = argv.z
tileJsonGenerator = new TileJsonGenerator
dirname = filename.replace /\.svg$/i ""
(err, content) <~ fs.readFile "#filename"
(err) <~ fs.mkdir "#dirname"
console.log "Starting #filename"
content .= toString!
$content = $ "<div></div>"
$content.html content
$content.find "style" .remove! # CSS styles are unsupported - they would interfere with color-based area detection

fixCdata = (str) -> # for some reason, $.html mangles CDATA declaration
    str.replace "![CDATA[" "<![CDATA["
originalImage = fixCdata $content.html!

$exportables = $content.find "[data-export]"
$exportables.each ->
    # assign each exportable area a unique color, which will then be used to match the area with the data
    $ele = $ @
    exportable = $ele.attr \data-export
    index = tileJsonGenerator.getExportableIndex exportable
    color = tileJsonGenerator.getColorByIndex index
    $ele.attr \fill color

contouredExportsImage = fixCdata $content.html!
bounds = $content.find "svg" .attr \data-bounds
if not bounds
    console.error "No data-bounds attribute found in SVG file (should be north,west,south,east)"
    process.exit!

[north, west, south, east] = bounds.split /[, ;]/g .map parseFloat
# find what the pixel coordinates would be on a full world map at the given zoomlevel
{x:x0, y:y0} = L.CRS.EPSG3857.latLngToPoint do
    new L.LatLng north, west
    zoomLevel
{x:x1, y:y1} = L.CRS.EPSG3857.latLngToPoint do
    new L.LatLng south, east
    zoomLevel

# number of pixels the first pixel of the image is offset from the left-upper most corner of the left-uppermost tile
offsetX = x0 % 256
offsetY = y0 % 256
# width and height of the full image that will be sliced into tiles
width  = Math.abs x0 - x1
height = Math.abs y0 - y1
# numbering of the first tile - we won't usually start at the prime meridian, North Pole
tileNumberOffsetX = Math.floor x0 / 256
tileNumberOffsetY = Math.floor y0 / 256

canvasOptions = # options for the big image which will then be sliced to 256x256 tiles
    offsetX: offsetX
    offsetY: offsetY
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes

directoriesCreated = {}
createImages = (svg, cb) ->
    # first, generate the big image
    canvas = new Canvas width + offsetX, height + offsetY
    canvg canvas, svg, canvasOptions
    tilesDone = 0
    # then slice it up!
    tileMaker = new TileMaker canvas, [256, 256], zoomLevel
        ..on \tile (z, x, y, canvas) ->
            x += tileNumberOffsetX
            y += tileNumberOffsetY
            buffer = canvas.toBuffer!
            if not directoriesCreated["#dirname/#z"]
                fs.mkdirSync "#dirname/#z"
                directoriesCreated["#dirname/#z"] := true
            if not directoriesCreated["#dirname/#z/#x"]
                fs.mkdirSync "#dirname/#z/#x"
                directoriesCreated["#dirname/#z/#x"] := true
            <~ fs.writeFile "#dirname/#z/#x/#y.png", buffer
            tilesDone++
            cb! if tilesDone == tileCount

    tileCount = tileMaker.makeTiles!


createJsons = (svg, cb) ->
    canvas = new Canvas width + offsetX, height + offsetY
    canvg canvas, svg, canvasOptions
    tilesDone = 0
    tileMaker = new TileMaker canvas, [256, 256], zoomLevel
        ..on \tile (z, x, y, canvas) ->
            x += tileNumberOffsetX
            y += tileNumberOffsetY
            tjson = tileJsonGenerator.generateJson canvas
            data = JSON.stringify tjson
            <~ fs.writeFile "#dirname/#z/#x/#y.json", data
            (err, compressed) <~ zlib.gzip data
            <~ fs.writeFile "#dirname/#z/#x/#y.json.gz", compressed
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
