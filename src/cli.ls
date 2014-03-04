require! {
    fs
    child_process.exec
    async
    "./utils"
    optimist
}
optimist
    .usage "Usage: $0 [svg file] -z [from-to] [-s [num]] [-c [num]]"
    .demand 1
    .demand <[z]>
    .describe "z" "Zoomlevel boundaries (inclusive), eg. 5-8"
    .describe "c" "Number of CPU cores to use"
    .alias "z" "zoom"
    .alias "c" "cores"

argv = optimist.argv

subSize = argv.s || 19
subMaxWidth  = subSize * 256
subMaxHeight = subSize * 256

cores = (parseInt argv.c, 10) || 4

zoomLevelBoundaries = argv.z.split "-" .map -> parseInt it, 10
unless zoomLevelBoundaries[0] and zoomLevelBoundaries[1]
    throw new Error "Invalid zoomlevel boundaries, use eg. 5-8"

absoluteOrRelative = optimist.argv._?0
absoluteFileAddress =
    | fs.existsSync absoluteOrRelative => absoluteOrRelative
    | fs.existsSync "#{process.cwd!}/#{absoluteOrRelative}" => "#{process.cwd!}/#{absoluteOrRelative}"
    | otherwise => throw new Error "File not found: #absoluteOrRelative"

file = absoluteFileAddress
dir = absoluteFileAddress.split '/' .pop!.replace /\.svg$/ ''
dir += "/"
(err) <~ fs.mkdir dir
throw err if err
console.log "Generating metadata for #absoluteOrRelative"
<~ utils.generateMetadata file, dir
{bounds} = "#dir/data.json" |> fs.readFileSync |> JSON.parse
zoomLevelDataCurry = (zoomLevel) -> utils.getZoomlevelData bounds, subMaxWidth, subMaxHeight, zoomLevel
zoomLevels = [zoomLevelBoundaries.0 to zoomLevelBoundaries.1].map zoomLevelDataCurry
console.log "Creating directories"
<~ utils.createDirectories dir, zoomLevels
commands = utils.generateCommands dir, subSize, zoomLevels

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
console.log "All done, tiles are now in #{dir}"
