var koa = require('koa'),
    app = koa(),
    routing = require('koa-routing'),
    sharp = require('sharp'),
    request = require('request'),
    stream = require('stream');

// Setup routing
app.use(routing(app));

function getSnapshot(callback) {

    if (!this.query) {
        callback("query parameters are required!", null);
    } else {
        console.log("requesting screenshot...");
        
        // Makes sure that the image comes back as a buffer
        request.defaults({ encoding: null });
        // request('http://enliten-manet.herokuapp.com?url=' + this.query.url, function(error, response, buffer) {
                
        //     if(error) {
        //         console.log("request error ", error);
        //     }

        //     if (!error && response.statusCode == 200) {
        //         console.log("received buffer.. processing...");
        //         console.log("type of buffer ", typeof buffer);
        //         console.log("is response a buffer", Buffer.isBuffer(buffer));
        //         console.log("create buffer", Buffer.isBuffer(new Buffer(buffer, 'binary')));
               



        //     }
        // })

        var transform = sharp()
          .resize(400, 400)
          .crop(sharp.gravity.north)
          .png()
          .toBuffer(function(err, outputBuffer, info) {
            if (err) {
              throw err;
            }
            console.log("done processing...returning response");
            // outputBuffer contains 200px high progressive JPEG image data,
            // auto-rotated using EXIF Orientation tag
            // info.width and info.height contain the dimensions of the resized image
            callback(null, outputBuffer);
          });

        request('http://enliten-manet.herokuapp.com?url=' + this.query.url).pipe(transform);  

    }


}

// response
app.route('/query')
    .get(function*(next) {
        console.log("query", this.query);
        this.type = 'image/png';
        this.body = yield getSnapshot;

    });

app.listen(process.env.PORT || 3000);

process.on('uncaughtException', function(err) {
    // handle the error safely
    console.log(err)
})
