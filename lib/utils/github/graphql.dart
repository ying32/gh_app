import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;

import 'cache_github.dart';

/// GraphQL查询
/// https://docs.github.com/zh/graphql/reference/queries
/// API
/// https://cli.github.com/manual/gh_api
///
/// GitHub GraphQL API 文档
/// https://docs.github.com/zh/graphql
class GitHubGraphQL {
  GitHubGraphQL({
    this.auth = const Authentication.anonymous(),
    this.endpoint = 'https://api.github.com/graphql',
  }) : _github = CacheGitHub(
            auth: auth, endpoint: endpoint, version: '', isGraphQL: true);

  /// Authentication Information
  Authentication auth;

  /// API Endpoint
  final String endpoint;

  /// github实例
  final CacheGitHub _github;

  /// 一个查询
  /// ```json
  /// {
  ///   "query": "query MyQuery($id: string) { thing(id: $id) { id name created } }",
  ///   "variables": {
  ///     "id": "thing_123"
  ///   },
  ///   "operationName": "MyQuery"
  /// }
  ///
  /// ```
  Future<T> query<S, T>(
    String body, {
    int? statusCode,
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    JSONConverter<S, T?>? convert,
  }) async {
    //convert ??= (input) => input as T?;
    headers ??= {};
    //headers.putIfAbsent('Accept', () => v3ApiMimeType);
    final response = await _query(body,
        headers: headers, params: params, statusCode: statusCode, fail: fail);
    final json = jsonDecode(response.body);

    // 有错误，这个错误在定义了[statusCode]时会解析
    // {"message":"Problems parsing JSON","documentation_url":"https://docs.github.com/graphql","status":"400"}
    // 实际为422错误，但没有哈
    // {"errors":[{"path":["query","DSD"],"extensions":{"code":"undefinedField","typeName":"Query","fieldName":"DSD"},"locations":[{"line":11,"column":4}],"message":"Field 'DSD' doesn't exist on type 'Query'"}]}
    // 这个错误貌似依然返回200？
    if (json['errors'] != null && statusCode == 200) {
      // 按理说应该状态码返回422，但没返回的原因是啥？？？？
      //response = response.o = 422;
      // 有错误了，这里他错误了也会返回个200，造成原来的解析不了
      _github.handleStatusCode(http.Response.bytes(response.bodyBytes, 422,
          headers: response.headers, isRedirect: response.isRedirect));
    }
    // 实际数据节点
    final data = json['data']; // ?? json
    if (data == null) {
      // ???
    }
    if (convert == null) {
      return data;
    }
    final returnValue = convert(data) as T;
    return returnValue;
  }

  String _encodeQuery(String text) =>
      text.replaceAll('"', r'\"').replaceAll("\r", "").replaceAll('\n', r"\n");

  //  "Content-Type: application/json",
  //   "Accept: application/vnd.github.v4.idl"
  /// 查询方法，先不公开，嗯，也许另有打算吧
  Future<http.Response> _query(
    String body, {
    int? statusCode,
    void Function(http.Response response)? fail,
    Map<String, String>? headers,
    Map<String, dynamic>? params,
  }) async =>
      _request('{ "query": "${_encodeQuery(body)}" }',
          statusCode: statusCode, fail: fail, headers: headers, params: params);

  // Future<http.Response> _mutation(
  //   String body, {
  //   int? statusCode,
  //   void Function(http.Response response)? fail,
  //   Map<String, String>? headers,
  //   Map<String, dynamic>? params,
  // }) async =>
  //     _request(
  //         '{ "query": "${body.replaceAll('"', r'\"').replaceAll(RegExp(r'\r|\n'), r"\n")}" }',
  //         statusCode: statusCode,
  //         fail: fail,
  //         headers: headers,
  //         params: params);

  /// 忽略path字段，强制为[endpoint]，本可不这样做的，但是他内部的[request]方法在判断[path]时
  /// 附加了一个”/“符号，造成服务端识为这是一个rest API。
  /// 暂时不公开，之后再看吧
  Future<http.Response> _request(
    String body, {
    Map<String, String>? headers,
    Map<String, dynamic>? params,
    int? statusCode,
    void Function(http.Response response)? fail,
  }) async {
    if (kDebugMode) {
      // print("body: $body");
    }
    return _github.request("POST", endpoint,
        headers: headers,
        params: params,
        body: body,
        statusCode: statusCode,
        fail: fail,
        preview: null);
  }
}
