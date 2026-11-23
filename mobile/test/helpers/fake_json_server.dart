import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers every request with the same status and JSON body,
/// and remembers the requests so tests can check them.
class FakeJsonServer implements HttpClientAdapter {
  FakeJsonServer(this.status, this.body);

  final int status;
  final String body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A Dio that talks to [server] instead of the network.
Dio dioFor(FakeJsonServer server) =>
    Dio(BaseOptions(baseUrl: 'http://test'))..httpClientAdapter = server;
