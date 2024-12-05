import 'dart:async';
import 'dart:convert';

import 'package:web3dart/json_rpc.dart';
import 'package:web3dart/provider.dart';

final class GTHTTPProvider extends Provider {
  GTHTTPProvider(this.uri) : super();

  final Uri uri;

  int _sequence = 0;

  @override
  Future<RPCResponse> send(String method, List<dynamic> params) async {
    final data = await GTWeb3DartRPCClient.instance.post(
      uri: uri,
      body: {
        'id': ++_sequence,
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
      },
    ).then((value) {
      if(value['data'] is String) {
        return jsonDecode(value['data']) as Map;
      } else {
        return (value['data'] as Map).cast();
      }
    });
    if (data.containsKey('error')) {
      final error = data['error'];
      final code;
      if(error['code'] is String) {
        code = int.parse(error['code']);
      } else {
        code = error['code'] as int;
      }
      final message = error['message'] as String;
      final errorData = error['data'];

      throw RPCError(code, message, errorData);
    }
    final id;
    if(data['id'] is String) {
        id = int.parse(data['id']);
      } else {
        id = data['id'] as int;
      }
    final result = data['result'];
    return RPCResponse(id, result);
  }

  @override
  Future<SubscriptionResponse> subscribe(
    String method,
    List params, {
    FutureOr<void> Function(String subscription)? onCancel,
  }) {
    throw Exception('HttpProvider does not support subscriptions');
  }

  @override
  Future connect() {
    return Future.value();
  }

  @override
  Future disconnect() {
    return Future.value();
  }

  @override
  bool isConnected() {
    return true;
  }

  static bool isEnabled() {
    return GTWeb3DartRPCClient._instance != null;
  }
}

abstract class GTWeb3DartRPCClient {
  const GTWeb3DartRPCClient();

  Future<Map<String, dynamic>> post({
    required Uri uri,
    required dynamic body,
    Map<String, String> headers = const {'Content-Type': 'application/json'},
  });

  static void init(GTWeb3DartRPCClient client) {
    _instance = client;
  }

  static GTWeb3DartRPCClient? _instance;

  static GTWeb3DartRPCClient get instance {
    assert(_instance != null, 'GTWeb3DartRPCClient is not initialized');
    return _instance!;
  }
}
