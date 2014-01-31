require! {
    fs
    child_process.exec
    async
    "./MetadataGenerator"
}

projectName = "prezidenti-circ-0"
file = "#__dirname/../data/#projectName.svg"

dir = "#__dirname/../data/#projectName"

console.log "Generating metadata #projectName"
<~ MetadataGenerator.generate file, dir

subSize = 19
subMaxWidth  = subSize * 256
subMaxHeight = subSize * 256

cmds = []
<~ async.each [6 to 13], (zoomLevel, cb) ->
    {bounds} = "#dir/data.json" |> fs.readFileSync |> JSON.parse
    {width, height, firstTileNumberX, lastTileNumberX} = MetadataGenerator.getPixelDimensions do
        bounds
        zoomLevel

    xSteps = Math.ceil width / subMaxWidth
    ySteps = Math.ceil height / subMaxHeight
    <~ fs.mkdir "#dir/#zoomLevel"
    <~ async.each [firstTileNumberX to lastTileNumberX], (x, cb) ->
        <~ fs.mkdir "#dir/#zoomLevel/#x"
        cb!

    for sub in [0 til xSteps * ySteps]
        cmds.push "lsc #__dirname/map.ls -d #dir -z #zoomLevel -c #sub -m json -s #subSize"
        cmds.push "lsc #__dirname/map.ls -d #dir -z #zoomLevel -c #sub -m image -s #subSize"
    cb!

i = 0
len = cmds.length
processing = {}
<~ async.eachLimit cmds, 8, (cmd, cb) ->
    index = ++i
    processing[index] = true
    console.log "#{index} / #{len}"
    (err, stdout, stderr) <~ exec cmd
    console.log "Done #index"
    delete processing[index]
    out = for pindex of processing
        pindex
    console.log out.join ", "
    console.log that if stderr
    cb!

