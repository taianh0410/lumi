import 'api_client.dart';

class DioClient {
  DioClient._();

  static final instance = ApiClient.instance.dio;
}
