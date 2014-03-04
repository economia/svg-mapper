# SVG mapper

Ever had a complex GeoJSON with thousands of features and some dataset that integrates perfectly with [D3](http://d3js.org/), just to discover that rendering it takes ages and requires megabytes of data (like this [electoral map](http://datasklad.ihned.cz/volebni-mapa/www/) of Czech republic)? That's why we developed SVG Mapper. Utilizing [node-canvas](https://github.com/learnboost/node-canvas) and [CanVG](http://code.google.com/p/canvg/), it slices provided SVG into bitmap tiles for use e.g. in [Leaflet](http://leafletjs.com/), with interactivity provided by [UTFGrid](https://www.mapbox.com/developers/utfgrid/). The result is a zoomable, interactive [map](http://staticmaps.ihned.cz/volby-mapy-2013/www/index.html) compatible with Google and OpenStreetMap tiles.

Written in [LiveScript](http://livescript.net/), compiles to JavaScript.

Please note it is quite resource intensive (easily takes a gigabyte of RAM per thread) and **does not support CSS** styled content, all elements must have all their properties set by inline attributes.

## Usage in a nutshell

* Draw SVG with d3.geo.mercator projection. Annotate the <svg> with `data-bounds` attribute, indicating its maximum north, west, south and east coordinates.
* For each required path (geo/topoJSON feature), add `data-export` attribute with stringified JSON of the interactive data (what should be displayed on hover, what should be done on click etc.)
* Run the [command-line utility](#step-by-step-usage) to generate tiles - both imagery and UTFGrid JSONs
* Integrate the new layer into your existing Leaflet deployment. You may want [Leaflet.utfgrid](https://github.com/danzel/Leaflet.utfgrid) if you don't use it already.

See [this page](http://datasklad.ihned.cz/svgmapper-example/leaflet.html) for an example of it all running together.

## Step by step usage

Install the NPM package (or clone the repo, install [LiveScript](http://livescript.net/) and run `slake build`, then you can access the CLI by `node bin/cli.js`)

    npm install -g svg-mapper

Then, you need the annoted SVG. For an example how to generate one from geoJSON and some predefined data, see [example/generator.html](example/generator.html). You can get the SVG itself from that page using [SVG Crowbar](http://nytimes.github.io/svg-crowbar/) or download it [directly from the examples folder](./example/example.svg).

Now you need to run the command line utility

    svg-mapper path/to/svg.svg -z 6-8

svg-mapper takes following parameters:

* z - Zoomlevels to generate, in a from-to (inclusive) format. -z 6-8 will generate zoomlevels 6,7 and 8. Required.
* c - Number of threads to use. Should be roughly the same as your logical core count (including HyperThreaded cores). Optional, defaults to 4.
* s - Maximum size of "big image" - one that is later sliced into tiles (see [Modus operandi](#modus-operandi)). Units are "number of tiles", that means the image will be at most 256 * (number) pixels wide/tall. Bigger values equal better performance, but more memory requirements. Optional, defaults to 19, which takes ~2GB RAM per thread.

Now your tiles should be generated into a directory with the same name as the original SVG, sans the ".svg" suffix - see [example/output](example/output) directory. It is ready to be plugged into Leaflet as any other layer. See the [output example](example/leaflet.html) for details on how to do this.

## Modus operandi
First of all, the whole SVG is rendered to a "big image" canvas with correct scale for a given zoom level and with appropriate offset from top and left sides to correctly align with Web Mercator tiles. See [this image](example/big.png) for an example of Czech Republic at zoomlevel 6. This image is then sliced into tiles 256x256px (like [this one](example/output/6/34/21.png) and one [below it](example/output/6/34/22.png)), which are put in corresponding directories.

If the SVG at that zoomlevel is bigger than the maximum specified with `-s` parameter (default 19 * 255 = 4845px), then even these "big images" are generated in tiles. Due to canvas init time and SVG rendering time, this tiling comes with significant performance penalties, so low `-s` values are not recommended.

Then, the UTFGrid needs to be generated. The biggest issue here is area detection - with possible overlaying paths, it can get quite complex. This is why SVGMapper uses **color based detection** on a **rendered SVG** rather than computational point-in-polygon detection. First, it selects all paths with `data-export` attribute and changes their fill color to a unique shade. This shade is later detected on a per-pixel basis and appropriate UTFGrid JSON is generated. For an example of how this works, see [this image](example/big_dataContoured.png). Tiling and "big image"-wise, UTFGrid follows the same principles as map imagery.

Note that due to rendering antialiasing, there is a `colorInterval` property in [TileJsonGenerator](ls/TileJsonGenerator.ls) that dictates the minimum step between two shades. By default it is set to 5, meaning you can use 256^3 / 5 = **3.3M different export values**. Also note that same export values share the same shade, as seen in the [image above](example/big_dataContoured.png) with the westernmost area (*Karlovarsky region*) and the very center area (*Prague region*). That image also has the colorInterval bumped to 18 for increased clarity and human readability.

## Common errors
* Unexpected token - this hapens when the data-export is not valid JSON string. Make sure to use JSON.stringify on any data-export values.

## Known limitations / TODO

* No CSS style support

## Licence (MIT)
Copyright (c) 2014 Economia, a.s.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
