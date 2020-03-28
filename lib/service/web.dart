import 'dart:convert';
import 'package:http/http.dart' as http;

class Response {
  final int status;
  final Map<String, dynamic> body;

  Response({this.status = 200, this.body = const {}}) {
    print("Response body:");
    body.forEach((key, value) {
      print("[$key] $value");
     });
  }
}

class Web {
  static const String HTTP_PROTOCOL = "http://";

  Future<Response> get(String address, String contextPath, {Map<String, String> parameters}) async {
    if (!address.startsWith(HTTP_PROTOCOL)) {
      address = HTTP_PROTOCOL + address;
    }

    String parametersStr = "";
    if (parameters != null) {
      parametersStr += "?";
      parameters.forEach((key, value) => parametersStr += key + "=" + value + "&");
      parametersStr = parametersStr.substring(0, parametersStr.length - 1);
    }

    String fullAddress = address + contextPath + parametersStr;
    print("[WEB] GET on $fullAddress");
    return http.get(fullAddress)
      .then((response) => Response(status: response.statusCode, body: json.decode(response.body)))
      .catchError((error) => print(error));
  }
}