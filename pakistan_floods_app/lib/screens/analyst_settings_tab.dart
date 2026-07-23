import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../models/app_state.dart';
import '../utils/file_helper.dart';

class AnalystSettingsTab extends StatefulWidget {
  final VoidCallback onStateModified;
  const AnalystSettingsTab({super.key, required this.onStateModified});
  @override
  State<AnalystSettingsTab> createState() => _AnalystSettingsTabState();
}

class _AnalystSettingsTabState extends State<AnalystSettingsTab> {
  final _serverIpCtrl = TextEditingController();
  bool _isChecking = false;
  String _pingTime = '';

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isProcessingData = false;

  @override
  void initState() {
    super.initState();
    _serverIpCtrl.text = AppState().serverIp;
    _nameCtrl.text = AppState().userName;
    _emailCtrl.text = AppState().officerEmail;
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final start = DateTime.now();
    final res = await ApiService.getStats(_serverIpCtrl.text.trim());
    final end = DateTime.now();
    if (mounted) {
      setState(() {
        _isChecking = false;
        if (res['success'] == true) {
          _pingTime = '${end.difference(start).inMilliseconds} ms';
          AppState().serverIp = _serverIpCtrl.text.trim();
          widget.onStateModified();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected • $_pingTime'), backgroundColor: const Color(0xFF16A34A)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection failed'), backgroundColor: Color(0xFFEF4444)));
        }
      });
    }
  }

  Future<void> _downloadDataset() async {
    setState(() => _isProcessingData = true);
    final res = await ApiService.downloadDataset(AppState().serverIp);
    if (mounted) {
      setState(() => _isProcessingData = false);
      if (res.statusCode == 200) {
        await FileHelper.saveFile(res.bodyBytes, 'pakistan_floods_training_data.csv');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Training dataset exported to device.'), backgroundColor: Color(0xFF16A34A)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed. Ensure backend is synced.'), backgroundColor: Color(0xFFEF4444)));
      }
    }
  }

  Future<void> _uploadDataset() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _isProcessingData = true);
      final res = await ApiService.uploadDataset(AppState().serverIp, result.files.single.bytes!, result.files.single.name);
      if (mounted) {
        setState(() => _isProcessingData = false);
        if (res['success'] == true) {
          widget.onStateModified(); // Trigger UI recalculations/reports update
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom dataset uploaded. Ready for retraining.'), backgroundColor: Color(0xFF16A34A)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: ${res['message']}'), backgroundColor: const Color(0xFFEF4444)));
        }
      }
    }
  }

  Future<void> _forceRetrain() async {
    setState(() => _isProcessingData = true);
    final res = await ApiService.forceRetrain(AppState().serverIp);
    if (mounted) {
      setState(() => _isProcessingData = false);
      if (res['success'] == true) {
        widget.onStateModified();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Model retrained! New R²: ${(res['r2'] * 100).toStringAsFixed(1)}%'), backgroundColor: const Color(0xFF16A34A)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Retraining failed: ${res['message']}'), backgroundColor: const Color(0xFFEF4444)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 24),
          _card('Network Tunnel', Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: _serverIpCtrl, decoration: const InputDecoration(labelText: 'Server Domain / IP'))),
              const SizedBox(width: 16),
              SizedBox(width: 180, child: ElevatedButton(onPressed: _isChecking ? null : _checkConnection, child: _isChecking ? const CircularProgressIndicator(color: Colors.white) : const Text('Test Connection')))
            ])
          ])),
          const SizedBox(height: 24),
          _card('Model & Dataset Operations', Column(children: [
            const Text('Upload local CSV datasets (with appropriate formatted schemas) for on-the-fly model training updates, or extract the live dataset payload representing the latest backend intelligence.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            const SizedBox(height: 24),
            Row(
              children: [
                 Expanded(child: OutlinedButton.icon(onPressed: _isProcessingData ? null : _downloadDataset, icon: const Icon(Icons.download_rounded, size: 18), label: const Text('Export Training Set\n(CSV)', textAlign: TextAlign.center, style: TextStyle(height: 1.2, fontSize: 13)))),
                 const SizedBox(width: 12),
                 Expanded(child: OutlinedButton.icon(onPressed: _isProcessingData ? null : _uploadDataset, icon: const Icon(Icons.upload_file_rounded, size: 18), label: const Text('Upload Dataset\n(CSV)', textAlign: TextAlign.center, style: TextStyle(height: 1.2, fontSize: 13)))),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessingData ? null : _forceRetrain,
              icon: _isProcessingData ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.psychology_rounded, size: 20),
              label: const Text('Force Cloud Model Retraining'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            )
          ])),
          const SizedBox(height: 24),
          _card('Profile Signature', Column(children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Officer Call Sign', suffixIcon: Icon(Icons.edit, size: 16))),
            const SizedBox(height: 16),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Notification Email', suffixIcon: Icon(Icons.edit, size: 16))),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () {
              AppState().userName = _nameCtrl.text;
              AppState().officerEmail = _emailCtrl.text;
              widget.onStateModified();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile synced'), backgroundColor: Color(0xFF10B981)));
            }, child: const Text('Save Profile'))
          ])),
        ],
      ),
    );
  }

  Widget _card(String title, Widget c) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 24),
        c
      ]),
    );
  }
}
