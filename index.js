var koa = require('koa'),
    app = koa(),
    routing = require('koa-routing'),
    sharp = require('sharp'),
    request = require('request'),
    stream = require('stream');

// Setup routing
app.use(routing(app));

function params (obj) {
    return _.map(obj, function(value, key) {
        return key + "=" + value;
    }).join("&");
}

function getSnapshot(callback) {

    if (!this.query) {
        callback("query parameters are required!", null);
    } else {
        console.log("requesting screenshot...");

        // Makes sure that the image comes back as a buffer
        request.defaults({ encoding: null });

        var width = this.query.width ? parseInt(this.query.width, 10) : 400;
        var height = this.query.height ? parseInt(this.query.height, 10) : 400;
        var src = this.query.src || 'http://enliten-manet.herokuapp.com';

        var transform = sharp()
          .resize(width, height)
          .crop(sharp.gravity.north)
          .png()
          .quality(100)
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

        request(src + '?' + params({
            quality: 1,
            width:1280,
            url: this.query.url
        })).pipe(transform);

    }

}

// response
app.route('/query')
    .get(function*(next) {
        console.log("query", this.query);
        this.type = 'image/png';
        this.body = yield getSnapshot;
        console.log(this);
        this.set('Text-Encoding','ISO-8859-1' );
    });

app.listen(process.env.PORT || 3000);

process.on('uncaughtException', function(err) {
    // handle the error safely
    console.log(err)
})
