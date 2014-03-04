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
    './utils'
}
optimist
    .usage "Usage: $0 -d [directory] -z [num] -m [image|json] "
    .demand ["d" "z" "m"]
    .describe "d" "Directory with prepared original.svg, exports.svg and data.json"
    .describe "z" "Zoom level to generate"
    .describe "m" "Mode, 'image' or 'json'"
    .describe "c" "Subimage index to generate, zero-based."
    .describe "s" "Subimage size in counts of tiles (= maximum width or height of sliced image)"

argv = optimist.argv

dirname    = argv.d
zoomLevel  = argv.z
mode       = argv.m
currentSub = argv.c || 0
subSize    = argv.s || 19
svgSource  = switch mode
    | "image" => "#dirname/original.svg"
    | "json"  => "#dirname/exports.svg"
    | _       => throw new Error "Unknown mode: #mode. Allowed modes are 'image' and 'json'."
svg = fs.readFileSync svgSource .toString!

{exportables, bounds} = "#dirname/data.json" |> fs.readFileSync |> JSON.parse
tileJsonGenerator = new TileJsonGenerator exportables

{width, height, firstTileNumberX, firstTileNumberY, offsetX, offsetY} = utils.getPixelDimensions do
    bounds
    zoomLevel

# Max dimensions of subimage (or supertile) - in cases where whole image would
# not fit into memory, it is sliced into very large tiles and then this tile
# is sliced into actual 256x256 webtiles. Dimensions have to be multiples of 256

subMaxWidth  = subSize * 256
subMaxHeight = subSize * 256

# number of columns of subimages the whole image will have
ySteps = Math.ceil height / subMaxHeight

# indices of currently generated subimage
xIndex = Math.floor currentSub / ySteps
yIndex = currentSub % ySteps

# how many pixels are "not drawn" - are to the left and top of this subimage...
notDrawableX = xIndex * subMaxWidth
notDrawableY = yIndex * subMaxHeight

# ...and the resulting offset of tile numbering
subFirstTileNumberX = firstTileNumberX + notDrawableX / 256
subFirstTileNumberY = firstTileNumberY + notDrawableY / 256

# how many pixels are remaining to the right and bottom of this subImage to the
# extents of the whole image
remainingX = width  + offsetX - notDrawableX
remainingY = height + offsetY - notDrawableY

# what are the dimensions of this subImage
subWidth  = Math.min remainingX, subMaxWidth
subHeight = Math.min remainingY, subMaxHeight

canvasOptions = # options for the (sub)image which will be sliced into 256x256 tiles
    offsetX: offsetX - notDrawableX
    offsetY: offsetY - notDrawableY
    scaleWidth: width
    scaleHeight: height
    ignoreDimensions: yes

# generating (sub)image
canvas = new Canvas subWidth, subHeight
canvg canvas, svg, canvasOptions
tilesDone = 0
fileSuffix = switch mode
    | "image" => "png"
    | "json"  => "json"

# slicing of (sub)image
tileMaker = new TileMaker canvas, [256, 256], zoomLevel
    ..on \tile (z, x, y, canvas) ->
        x += subFirstTileNumberX
        y += subFirstTileNumberY
        buffer = canvas.toBuffer!
        data = switch mode
            | "image" => buffer
            | "json"  => canvas |> tileJsonGenerator.generateJson |> JSON.stringify
        fs.writeFileSync "#dirname/#z/#x/#y.#fileSuffix", data
        tilesDone++
        if 0 is tilesDone % 25 => console.log "#{Math.round tilesDone / tileCount * 100}%"
        if tilesDone == tileCount
            # canVG has some issues quitting correctly, hence process.exit
            setTimeout process.exit, 1000
tileCount = tileMaker.makeTiles!
