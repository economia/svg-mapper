require! {
    fs
    child_process.exec
    async
    optimist.argv
}
numCores = (parseInt argv.c, 10) || 8
(err, files) <~ fs.readdir "#__dirname/../data/"
files .= filter -> /svg$/.test it
files .= map -> it.replace ".svg" ""

tasks = []
files.forEach (file, cb) ->
    [6 to 10].forEach (zoomLevel, cb) ->
        tasks.push do
            (cb) ->
                console.log "Starting #file #zoomLevel"
                (err, stdout, stderr) <~ exec "lsc #__dirname/map.ls -f #file -z #zoomLevel"
                console.error err if err
                console.error stderr if stderr
                console.log "Done #file #zoomLevel"
                cb!
<~ async.parallelLimit tasks, numCores

<~ async.each files, (file, cb) ->
    console.log "Moving #file.svg"
    <~ fs.rename "#__dirname/../data/#file.svg", "#__dirname/../data/done/#file.svg"
    console.error err if err
    cb!
console.log "Done!"
