import 'dart:io';
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
  bool? _isOnline;
  String _checkMsg = '';

  bool _isRetraining = false;
  Map<String, dynamic>? _retrainResult;

  bool _isUploadingDataset = false;
  bool _isDownloadingDataset = false;
  String? _datasetOpResult;
  bool? _datasetOpSuccess;

  // Officer profile editing text controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _stationCtrl = TextEditingController();

  bool _isEmailingDataset = false;

  @override
  void initState() {
    super.initState();
    _serverIpCtrl.text = AppState().serverIp;
    
    // Autofill officer profile inputs from current AppState
    _nameCtrl.text = AppState().userName.isNotEmpty ? AppState().userName : 'EOC Officer';
    _emailCtrl.text = AppState().officerEmail;
    _batchCtrl.text = AppState().officerBatchId;
    _stationCtrl.text = AppState().officerStation;
    
    _checkConnection(silent: true);
  }

  @override
  void dispose() {
    _serverIpCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _batchCtrl.dispose();
    _stationCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnection({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isChecking = true;
        _isOnline = null;
        _checkMsg = '';
      });
    }

    final ip = _serverIpCtrl.text.trim();
    final res = await ApiService.getStats(ip);

    if (mounted) {
      setState(() {
        _isChecking = false;
        if (res['success'] == true) {
          _isOnline = true;
          _checkMsg = 'Successfully connected to backend EOC stats portal!';
          AppState().serverIp = ip;
          widget.onStateModified();
        } else {
          _isOnline = false;
          _checkMsg = 'Failed to establish tunnel. Verify endpoint availability.';
        }
      });
    }
  }

  Future<void> _forceModelRetrain() async {
    // Add confirmation with warning preview (Heuristic: User Control & Freedom)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'WARNING: TRIGGER LINEAR MODEL RETRAINING',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFC53030), letterSpacing: 0.8),
        ),
        content: const Text(
          'This action forces the remote server to scrape the raw dataset, execute regression solver gradients, and overwrite live coefficient matrices immediately. Confirmed calibration operations are irreversible. Proceed?',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ABORT PROCESS', style: TextStyle(color: Colors.black38, fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC53030)),
            child: const Text('FORCE EXECUTION', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRetraining = true;
      _retrainResult = null;
    });

    final ip = AppState().serverIp;
    final res = await ApiService.forceRetrain(ip);

    if (mounted) {
      setState(() {
        _isRetraining = false;
        _retrainResult = res;
        if (res['success'] == true) {
          widget.onStateModified();
        }
      });
    }
  }

  Future<void> _exportDataset() async {
    setState(() {
      _isDownloadingDataset = true;
      _datasetOpResult = null;
      _datasetOpSuccess = null;
    });

    final ip = AppState().serverIp;
    try {
      final response = await ApiService.downloadDataset(ip);
      if (response.statusCode == 200) {
        final path = await FileHelper.saveFile(
          response.bodyBytes,
          'pakistan_floods_updated.csv',
        );

        setState(() {
          _isDownloadingDataset = false;
          if (path != null) {
            _datasetOpSuccess = true;
            _datasetOpResult = '✔️ DATASET EXPORTED SUCCESSFUL:\n$path';
          } else {
            _datasetOpSuccess = false;
            _datasetOpResult = '❌ LOCAL SYSTEM DIRECTORY WRITES FAULTED.';
          }
        });
      } else {
        setState(() {
          _isDownloadingDataset = false;
          _datasetOpSuccess = false;
          _datasetOpResult = '❌ SERVER DATABASE DUMP FAILED: Status ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isDownloadingDataset = false;
        _datasetOpSuccess = false;
        _datasetOpResult = '❌ NETWORK FAULT: $e';
      });
    }
  }

  Future<void> _importCustomDataset() async {
    setState(() {
      _isUploadingDataset = true;
      _datasetOpResult = null;
      _datasetOpSuccess = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploadingDataset = false;
          _datasetOpSuccess = false;
          _datasetOpResult = '❌ IMPORT ABORTED: No file selected.';
        });
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);

      if (bytes == null) {
        setState(() {
          _isUploadingDataset = false;
          _datasetOpSuccess = false;
          _datasetOpResult = '❌ ACCESS ERROR: File content was not readable.';
        });
        return;
      }

      final ip = AppState().serverIp;
      final responseObj = await ApiService.uploadDataset(ip, bytes, file.name);

      setState(() {
        _isUploadingDataset = false;
        _datasetOpSuccess = responseObj['success'] ?? false;
        _datasetOpResult = responseObj['success'] == true
            ? '✔️ CUSTOM DATABASE COMMITTED! Calculation targets re-aligned.'
            : '❌ DATA PARSE FAILURE: ${responseObj['message']}';
      });

      if (responseObj['success'] == true) {
        widget.onStateModified();
      }
    } catch (e) {
      setState(() {
        _isUploadingDataset = false;
        _datasetOpSuccess = false;
        _datasetOpResult = '❌ CRITICAL SYSTEM INTERCEPT: $e';
      });
    }
  }

  Future<void> _emailDataset(String format) async {
    setState(() {
      _isEmailingDataset = true;
      _datasetOpResult = null;
      _datasetOpSuccess = null;
    });

    final ip = AppState().serverIp;
    try {
      final res = await ApiService.emailExport(
        ip: ip,
        email: AppState().officerEmail,
        type: 'dataset',
        format: format,
        officerName: AppState().userName.isNotEmpty ? AppState().userName : 'EOC Officer',
        batchId: AppState().officerBatchId,
      );

      setState(() {
        _isEmailingDataset = false;
        _datasetOpSuccess = res['success'] == true;
        _datasetOpResult = res['success'] == true
            ? '📧 EMAIL COMPLETE: ${res['message']}'
            : '❌ EMAIL DISPATCH FAILED: ${res['message']}';
      });
    } catch (e) {
      setState(() {
        _isEmailingDataset = false;
        _datasetOpSuccess = false;
        _datasetOpResult = '❌ EMAIL DISPATCH EXCEPTION: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderSlate = Color(0xFFCBD5E1);
    const prNavy = Color(0xFF1B365D);
    const scForest = Color(0xFF2D6A4F);
    const textDark = Color(0xFF0F172A);
    const textMuted = Color(0xFF475569);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 0. Secure Officer Profile Card (NDMA EOC)
          _buildCard(
            title: 'OFFICER CENTRAL PROFILE CONFIGURATION (EOC)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage session credentials and authorization signatures. Form targets below are used to sign telemetry logs, auto-generate report attributions, and route dispatches to your verified email.',
                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.45),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OFFICER CALL SIGN / NAME',
                            style: TextStyle(fontSize: 8, color: textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameCtrl,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DESTINATION EMAIL ADDRESS',
                            style: TextStyle(fontSize: 8, color: textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailCtrl,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EOC PERSONNEL BATCH ID',
                            style: TextStyle(fontSize: 8, color: textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _batchCtrl,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COMMAND DEPLOYMENT STATION',
                            style: TextStyle(fontSize: 8, color: textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _stationCtrl,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textDark),
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: prNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: prNavy),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        AppState().userName = _nameCtrl.text.trim();
                        AppState().officerEmail = _emailCtrl.text.trim();
                        AppState().officerBatchId = _batchCtrl.text.trim();
                        AppState().officerStation = _stationCtrl.text.trim();
                      });
                      widget.onStateModified();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            '🛡️ OFFICER EOC PROFILE SYNCHRONIZED SUCCESSFULLY!',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: scForest,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.badge_sharp, size: 14),
                    label: const Text(
                      'COMMIT & SYNCHRONIZE PROFILE CREDENTIALS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. Connection Configurations Box
          _buildCard(
            title: 'API NETWORK TUNNEL ENDPOINT',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set the Local Host / API endpoint mapping. Emulators map by default to 10.0.2.2:5000; physical deployment requires manual machine IP routes.',
                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.4),
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'ROUTING SERVER INET DOMAIN/IP',
                  style: TextStyle(fontSize: 9, color: textDark, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _serverIpCtrl,
                        style: const TextStyle(color: textDark, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 127.0.0.1:5000',
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isChecking ? null : () => _checkConnection(),
                      style: IconButton.styleFrom(
                        backgroundColor: prNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: _isChecking
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.flash_on_rounded, size: 18, color: Colors.white),
                    )
                  ],
                ),
                if (_checkMsg.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _isOnline == true ? Icons.check_circle_outline_sharp : Icons.error_outline_sharp,
                        color: _isOnline == true ? scForest : const Color(0xFFC53030),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _checkMsg.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: _isOnline == true ? scForest : const Color(0xFFC53030),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Calibrate model actions
          _buildCard(
            title: 'REGRESSION MODEL OVERWRITE CALIBRATION',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instruct the operational server to wipe gradient coefficients cache, scrape registered SITREPs inside CSV datasets, and recalculate predictors.',
                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.4),
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _isRetraining ? null : _forceModelRetrain,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD97706), width: 1.5), // Serious amber
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    icon: _isRetraining
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFFD97706), strokeWidth: 1.5))
                        : const Icon(Icons.autorenew_sharp, color: Color(0xFFD97706), size: 16),
                    label: const Text(
                      'FORCE SYSTEM MODEL RETRAINING',
                      style: TextStyle(color: Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),

                if (_retrainResult != null) ...[
                  const SizedBox(height: 16),
                  const Divider(color: borderSlate),
                  const SizedBox(height: 10),
                  Text(
                    _retrainResult!['success'] == true
                        ? '✔️ RETRAINING COMPLETE: System model refreshed.'
                        : '❌ RETRAINING FAULTED: Check server stack trace.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _retrainResult!['success'] == true ? scForest : const Color(0xFFC53030),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_retrainResult!['success'] == true) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CALIBRATED R²: ${((_retrainResult!['metrics']?['r2'] ?? 0.0) * 100).toStringAsFixed(2)}%',
                          style: const TextStyle(fontSize: 11, color: textDark, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'CALIBRATED RMSE: ${(_retrainResult!['metrics']?['rmse'] ?? 0.0).toStringAsFixed(1)}',
                          style: const TextStyle(fontSize: 11, color: textDark, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Dataset Integration & Custom Overwrites
          _buildCard(
            title: 'DATASET INTEGRATION & EXPORT PORTAL',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage disaster databases. Export the complete current telemetry dataset (CSV) to your computer, or overwrite the existing database model entirely by uploading a custom CSV file.',
                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.4),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _isDownloadingDataset ? null : _exportDataset,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: borderSlate, width: 1.5),
                          ),
                        ),
                        icon: _isDownloadingDataset 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: prNavy))
                          : const Icon(Icons.download_for_offline_outlined, color: prNavy, size: 16),
                        label: const Text(
                          'DOWNLOAD TELEMETRY CSV',
                          style: TextStyle(color: prNavy, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: borderSlate, width: 1.5),
                          ),
                        ),
                        onPressed: _isUploadingDataset ? null : _importCustomDataset,
                        icon: _isUploadingDataset 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: scForest))
                          : const Icon(Icons.upload_file_outlined, color: scForest, size: 16),
                        label: const Text(
                          'UPLOAD RE-ALIGNMENT CSV',
                          style: TextStyle(color: scForest, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: prNavy, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _isEmailingDataset ? null : () => _emailDataset('csv'),
                          icon: _isEmailingDataset
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: prNavy))
                              : const Icon(Icons.mail_outline_sharp, color: prNavy, size: 16),
                          label: const Text(
                            'EMAIL DATABASE CSV',
                            style: TextStyle(color: prNavy, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: prNavy, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            backgroundColor: Colors.white,
                          ),
                          onPressed: _isEmailingDataset ? null : () => _emailDataset('pdf'),
                          icon: _isEmailingDataset
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: prNavy))
                              : const Icon(Icons.picture_as_pdf_outlined, color: prNavy, size: 16),
                          label: const Text(
                            'EMAIL SUMMARY PDF',
                            style: TextStyle(color: prNavy, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_datasetOpResult != null) ...[
                  const SizedBox(height: 12),
                  const Divider(color: borderSlate),
                  const SizedBox(height: 8),
                  Text(
                    _datasetOpResult!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _datasetOpSuccess == true ? scForest : const Color(0xFFC53030),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    const borderSlate = Color(0xFFCBD5E1);
    const textDark = Color(0xFF0F172A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderSlate, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
