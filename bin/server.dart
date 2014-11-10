// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shelf/shelf.dart';
import 'package:shelf_appengine/shelf_appengine.dart' as shelf_ae;
import 'package:appengine/appengine.dart' as ae;

/// This is a sample application.
///
/// It's in the bin directory to follow the convention of Dart applications.
void main() {
  var cascade = new Cascade()
      .add(_handler)
      .add(shelf_ae.assetHandler);

  var handler = const Pipeline()
      .addMiddleware(_rootRewriter)
      .addHandler(cascade.handler);

  shelf_ae.serve(handler);
}

/// If a request comes in for the root path, rewrites the path to request
/// `index.html`.
Handler _rootRewriter(Handler innerHandler) {
  return (Request request) {
    if (request.url.pathSegments.isEmpty) {
      request = request.change(url: request.url.replace(path: '/index.html'));
    }
    return innerHandler(request);
  };
}

_handler(Request request) {
  if (request.method != 'GET' || !request.url.path.startsWith('/memcache')) {
    return new Response.notFound('not found');
  }

  var memcache = ae.context.services.memcache;

  var headers = {'Content-Type' : 'text/plain' };

  var memcacheKey = 'count-${request.requestedUri}';

  return memcache.increment(memcacheKey).then((value) {
    var body = '''Hello from Shelf
Requested url: ${request.requestedUri}
        Count: $value
          Key: $memcacheKey''';

    return new Response.ok(body, headers: headers);
  });
}
