import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/download_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiService();
  late final _manager = DownloadManager(_api);
  final _ctrl = TextEditingController();

  Map<String, dynamic>? _info;
  int? _height;
  bool _busy = false;
  double _progress = 0;
  String? _error;
  final List<String> _history = [];

  Future<void> _analyze() async {
    setState(() { _busy = true; _error = null; _info = null; });
    try {
      final info = await _api.analyze(_ctrl.text.trim());
      final hs = (info['heights'] as List).cast<int>();
      setState(() { _info = info; _height = hs.isNotEmpty ? hs.first : null; });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    setState(() { _busy = true; _error = null; _progress = 0; });
    try {
      await _manager.downloadToGallery(
        _info!['media_url'], _height, (p) => setState(() => _progress = p));
      setState(() => _history.insert(0, _info!['title'] ?? 'Vidéo'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enregistrée dans la galerie ✔')));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heights = (_info?['heights'] as List?)?.cast<int>() ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Video Downloader')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
              labelText: 'Collez le lien de la vidéo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link)),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _analyze,
          icon: const Icon(Icons.search),
          label: const Text('Analyser'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (_info != null) ...[
          const SizedBox(height: 16),
          if (_info!['thumbnail'] != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(_info!['thumbnail'], errorBuilder: (_, __, ___) => const SizedBox())),
          const SizedBox(height: 8),
          Text(_info!['title'] ?? '', style: Theme.of(context).textTheme.titleMedium),
          if (heights.isNotEmpty)
            DropdownButton<int>(
              value: _height,
              isExpanded: true,
              items: heights.map((h) => DropdownMenuItem(value: h, child: Text('${h}p'))).toList(),
              onChanged: _busy ? null : (v) => setState(() => _height = v),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _download,
            icon: const Icon(Icons.download),
            label: const Text('Télécharger'),
          ),
        ],
        if (_busy) Padding(
          padding: const EdgeInsets.only(top: 16),
          child: LinearProgressIndicator(value: _progress > 0 ? _progress : null),
        ),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Historique', style: Theme.of(context).textTheme.titleSmall),
          ..._history.map((t) => ListTile(dense: true, leading: const Icon(Icons.check_circle_outline), title: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis))),
        ],
      ]),
    );
  }
}
