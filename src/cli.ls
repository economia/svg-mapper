require! {
    fs
    child_process.exec
    async
    "./utils"
    optimist
}
optimist
    .usage "Usage: $0 [svg file] -z [num] -s [num] -c [num] [--only-jsons | --only-tiles]"
    .demand 1
    .demand <[z]>
    .describe "z" "Zoomlevel boundaries (inclusive), eg. 5-8"
    .describe "c" "Number of CPU cores to use"
    .default "c" 4
    .describe "s" "Maximum size of image before slicing"
    .default "s" 19
    .alias "z" "zoom"
    .alias "c" "cores"

argv = optimist.argv

subSize = +argv.s || 19

subMaxWidth  = subSize * 256
subMaxHeight = subSize * 256
skipTiles = skipJsons = false
if argv["only-jsons"] then skipTiles = true
if argv["only-tiles"] then skipJsons = true

cores = +argv.c || 4
unless argv.z?match /[0-9]-[0-9]+/
    console.log "Invalid zoomlevel boundaries, use eg. -z 5-8"
    return
zoomLevelBoundaries = argv.z.split "-" .map -> parseInt it, 10

absoluteOrRelative = optimist.argv._?0
absoluteAddress =
    | fs.existsSync absoluteOrRelative => absoluteOrRelative
    | fs.existsSync "#{process.cwd!}/#{absoluteOrRelative}" => "#{process.cwd!}/#{absoluteOrRelative}"
    | otherwise => throw new Error "File not found: #absoluteOrRelative"

stat = fs.statSync absoluteAddress
svgSuffixRegex = /\.svg$/
files = if stat.isDirectory!
    fs.readdirSync absoluteAddress
        .filter -> svgSuffixRegex.test it
        .map -> absoluteAddress + "/" + it
else
    [absoluteAddress]

commands = []
<~ async.eachSeries files, (file, cb) ->
    dir = file.replace svgSuffixRegex, ''
    dir += "/"
    (err) <~ fs.mkdir dir
    if err
        console.log "Directory already exists or is not creatable, skipping: #dir"
        cb!
        return
    console.log "Generating metadata for #file"
    <~ utils.generateMetadata file, dir
    {bounds} = "#dir/data.json" |> fs.readFileSync |> JSON.parse
    zoomLevelDataCurry = (zoomLevel) -> utils.getZoomlevelData bounds, subMaxWidth, subMaxHeight, zoomLevel
    zoomLevels = [zoomLevelBoundaries.0 to zoomLevelBoundaries.1].map zoomLevelDataCurry
    console.log "Creating directories"
    <~ utils.createDirectories dir, zoomLevels
    commands ++= utils.generateCommands dir, subSize, zoomLevels, {skipTiles, skipJsons}
    cb!
i = 0

len = commands.length
processing = {}
console.log "Starting tile generation. Using #cores cores to do #len jobs."
<~ async.eachLimit commands, cores, (cmd, cb) ->
    index = ++i
    processing[index] = true
    process.stdout.write "Started job ##{index} of #{len} total.\n"
    (err, stdout, stderr) <~ exec cmd
    process.stdout.write "Done job ##index."
    delete processing[index]
    out = for pindex of processing
        pindex
    if out.length
        process.stdout.write " Still processing jobs #" + out.join ", "
        process.stdout.write ". Jobs remaining: #{len - i}."
    process.stdout.write "\n"
    console.log that if stderr
    cb!
console.log "All done, tiles are now in same directory as #absoluteAddress"
