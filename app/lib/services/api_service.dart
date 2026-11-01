import 'package:dio/dio.dart';
import '../config.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: backendUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 10),
  ));

  /// Analyse une URL et renvoie titre, miniature, qualités.
  Future<Map<String, dynamic>> analyze(String url) async {
    try {
      final r = await _dio.post('/analyze', data: {'url': url});
      return Map<String, dynamic>.from(r.data);
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  /// Télécharge le fichier vers [savePath] avec suivi de progression.
  Future<void> download(String url, int? height, String savePath,
      void Function(double) onProgress) async {
    try {
      await _dio.download(
        '/download',
        savePath,
        queryParameters: {'url': url, if (height != null) 'height': height},
        onReceiveProgress: (got, total) {
          if (total > 0) onProgress(got / total);
        },
      );
    } on DioException catch (e) {
      throw Exception(_message(e));
    }
  }

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Serveur injoignable. Vérifiez config.dart et votre connexion.';
    }
    return 'Erreur réseau.';
  }
}
