require! {
    fs
    child_process.exec
    async
    optimist
}
optimist
    .usage "Usage: $0 -c [num] -f [num] -t [num]"
    .demand ['f', 't']
    .describe "c" "Number of processes to launch in parallel. Should be equivalent to number of cores available. Defaults to 8"
    .describe "f" "Lowest zoomlevel to generate"
    .describe "t" "Highest zoomlevel to generate"
    .default 'c' 8
argv = optimist.argv

numCores = argv.c
dir = "#__dirname/../data/"
(err, files) <~ fs.readdir dir
files .= filter -> /svg$/.test it

tasks = []
if not files.length
    console.error "No SVG files found in data dir - #dir"
files.forEach (file, cb) ->
    [argv.f to argv.t].forEach (zoomLevel, cb) ->
        tasks.push do
            (cb) ->
                console.log "Starting #file #zoomLevel"
                (err, stdout, stderr) <~ exec "lsc #__dirname/map.ls -f #dir/#file -z #zoomLevel"
                console.error err if err
                console.error stderr if stderr
                console.log "Done #file #zoomLevel"
                cb!
<~ async.parallelLimit tasks, numCores

<~ async.each files, (file, cb) ->
    console.log "Moving #file"
    <~ fs.rename "#__dirname/../data/#file", "#__dirname/../data/done/#file"
    console.error err if err
    cb!
console.log "Done!"
