import 'dart:io';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class DownloadManager {
  final ApiService api;
  DownloadManager(this.api);

  /// Télécharge puis enregistre la vidéo dans la galerie / pellicule.
  Future<void> downloadToGallery(
      String url, int? height, void Function(double) onProgress) async {
    if (!await Gal.hasAccess(toAlbum: true)) {
      final ok = await Gal.requestAccess(toAlbum: true);
      if (!ok) throw Exception('Permission refusée : accès à la galerie requis.');
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/vd_${DateTime.now().millisecondsSinceEpoch}.mp4';
    try {
      await api.download(url, height, path, onProgress);
      await Gal.putVideo(path, album: 'VideoDL');
    } finally {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }
}
