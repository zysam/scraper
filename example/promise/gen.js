// Generated by CoffeeScript 1.9.2
(function() {
  'use strict';
  var STATUS_CODES, Urls, co, fs, getHeader, http, status;

  http = require('http');

  fs = require('fs');

  co = require('co');

  STATUS_CODES = http.STATUS_CODES;

  getHeader = function(url) {
    var promise;
    return promise = new Promise(function(resolve, reject) {
      var req;
      console.log('loading : %s', url);
      req = http.get(url, function(res) {
        var body;
        body = '';
        if (res.statusCode === 200 || res.statusCode === 302) {
          return resolve(res);
        } else {
          return reject('!200 : ' + STATUS_CODES[res.statusCode]);
        }
      });
      return req.on('error', function(err) {
        return reject('req error : %s', err);
      });
    });
  };

  Urls = [];

  (function() {
    var i, j, results;
    results = [];
    for (i = j = 1; j < 50; i = ++j) {
      results.push(Urls.push('http://www.baidu.com'));
    }
    return results;
  })();

  status = function*(url) {
    var res;
    res = (yield getHeader(url));
    status = res.statusCode || 404;
    return [url, status];
  };

  co(function*() {
    var res;
    res = (yield getHeader(url));
    Urls.map(status);
    return console.log('done');
  })["catch"](function(e) {
    return console.log('[err]' + e);
  });

}).call(this);

//# sourceMappingURL=gen.js.map
