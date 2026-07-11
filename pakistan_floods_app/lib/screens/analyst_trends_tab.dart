import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/app_state.dart';
import '../utils/file_helper.dart';

class AnalystTrendsTab extends StatefulWidget {
  const AnalystTrendsTab({super.key});

  @override
  State<AnalystTrendsTab> createState() => _AnalystTrendsTabState();
}

class _AnalystTrendsTabState extends State<AnalystTrendsTab> {
  String _selectedRegion = 'Sindh';
  final List<String> _regions = ['Sindh', 'KP', 'Punjab', 'Balochistan', 'AJ&K', 'GB', 'ICT'];
  
  bool _isLoadingProjections = true;
  bool _isLoadingRegions = true;
  List<dynamic> _projections = [];
  bool _isDownloadingReport = false;
  bool _isEmailingReport = false;

  @override
  void initState() {
    super.initState();
    _fetchRegions();
    _fetchProjections();
  }

  Future<void> _fetchRegions() async {
    setState(() => _isLoadingRegions = true);
    final res = await ApiService.getRegions(AppState().serverIp);
    if (res['success'] == true && mounted) {
      setState(() {
        _isLoadingRegions = false;
        final List<String> apiRegs = List<String>.from(res['regions']);
        for (var reg in apiRegs) {
          if (!_regions.contains(reg)) {
            _regions.add(reg);
          }
        }
      });
    } else {
      if (mounted) {
        setState(() => _isLoadingRegions = false);
      }
    }
  }

  Future<void> _fetchProjections() async {
    setState(() {
      _isLoadingProjections = true;
    });

    final ip = AppState().serverIp;
    final res = await ApiService.getProjections(ip, _selectedRegion);

    if (mounted) {
      setState(() {
        _isLoadingProjections = false;
        if (res['success'] == true) {
          _projections = res['projections'] ?? [];
        } else {
          _projections = _generateLocalProjections(_selectedRegion);
        }
      });
    }
  }

  Future<void> _downloadProjectionsReport() async {
    setState(() {
      _isDownloadingReport = true;
    });

    final ip = AppState().serverIp;
    try {
      final response = await ApiService.downloadReport(ip, _selectedRegion);
      if (response.statusCode == 200) {
        final path = await FileHelper.saveFile(
          response.bodyBytes,
          '${_selectedRegion.toLowerCase()}_projections_report.csv',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                path != null 
                  ? 'REPORT SECURELY EXPORTED TO:\n$path'
                  : 'FAILED TO TARGET LOCAL DIRECTORY WRITES.',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
              ),
              backgroundColor: path != null ? const Color(0xFF2D6A4F) : const Color(0xFFC53030),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SERVER REPORT GENERATION FAILED: Status ${response.statusCode}'),
              backgroundColor: const Color(0xFFC53030),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NETWORK/IO EXCEPTION: $e'),
            backgroundColor: const Color(0xFFC53030),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingReport = false;
        });
      }
    }
  }

  Future<void> _emailProjectionsReport(String format) async {
    setState(() {
      _isEmailingReport = true;
    });

    final ip = AppState().serverIp;
    try {
      final res = await ApiService.emailExport(
        ip: ip,
        email: AppState().officerEmail,
        type: 'report',
        format: format,
        region: _selectedRegion,
        officerName: AppState().userName.isNotEmpty ? AppState().userName : 'EOC Officer',
        batchId: AppState().officerBatchId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['success'] == true
                  ? '📧 REPORT DISPATCHED SUCCESSFULLY TO ${AppState().officerEmail.toUpperCase()}'
                  : '❌ EMAIL TRANSMISSION FAILED: ${res['message']}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: res['success'] == true ? const Color(0xFF2D6A4F) : const Color(0xFFC53030),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('EMAIL NETWORK EXCEPTION: $e'),
            backgroundColor: const Color(0xFFC53030),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEmailingReport = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _generateLocalProjections(String region) {
    double baselinePop = 1200000;
    if (region == 'Sindh') baselinePop = 1450000;
    if (region == 'Punjab') baselinePop = 1870000;
    if (region == 'KP') baselinePop = 950000;
    if (region == 'Balochistan') baselinePop = 620000;

    List<Map<String, dynamic>> list = [];
    double current = baselinePop;
    for (int y = 2023; y <= 2030; y++) {
      list.add({
        'year': y,
        'predicted_affected': current.round(),
      });
      current *= 1.03;
    }
    return list;
  }

  double _getMinY() {
    return 0.0;
  }

  double _getMaxY() {
    if (_projections.isEmpty) return 3000000.0;
    double maxVal = _projections.map((p) => (p['predicted_affected'] ?? p['predicted_affected_population'] ?? 0.0).toDouble()).reduce((a, b) => a > b ? a : b);
    return (maxVal * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    const borderSlate = Color(0xFFCBD5E1);
    const prNavy = Color(0xFF1B365D);
    const textDark = Color(0xFF0F172A);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Province selector dropdown card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderSlate, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scope Province Analysis Boundary:',
                  style: TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                _isLoadingRegions
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5))
                    : DropdownButton<String>(
                        value: _selectedRegion,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: prNavy, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        underline: const SizedBox(),
                        items: _regions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() {
                              _selectedRegion = val;
                            });
                            _fetchProjections();
                          }
                        },
                      ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Download report block
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _isDownloadingReport ? null : _downloadProjectionsReport,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: borderSlate, width: 1.5),
                        ),
                      ),
                      icon: _isDownloadingReport 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: prNavy))
                        : const Icon(Icons.download_sharp, size: 16, color: prNavy),
                      label: const Text(
                        'DOWNLOAD REGIONAL REPORT CSV',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: prNavy, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: prNavy, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isEmailingReport ? null : () => _emailProjectionsReport('csv'),
                      icon: _isEmailingReport 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: prNavy))
                        : const Icon(Icons.mail_outline_sharp, size: 16, color: prNavy),
                      label: const Text(
                        'EMAIL REPORT CSV',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: prNavy, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC53030), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isEmailingReport ? null : () => _emailProjectionsReport('pdf'),
                      icon: _isEmailingReport 
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC53030)))
                        : const Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFFC53030)),
                      label: const Text(
                        'EMAIL SUMMARY PDF',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFC53030), letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Projections graph card
          const Text(
            'RISK GROWTH TIMELINE PROGRESSION (2023–2030)',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            height: 270,
            padding: const EdgeInsets.only(right: 24, left: 4, top: 20, bottom: 8),
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
            child: _isLoadingProjections
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B365D)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
                        getDrawingVerticalLine: (_) => const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              double valInM = value / 1000000;
                              return Text(
                                '${valInM.toStringAsFixed(1)}M',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: borderSlate, width: 1),
                      ),
                      minX: 2023,
                      maxX: 2030,
                      minY: _getMinY(),
                      maxY: _getMaxY(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _projections.map((p) {
                            final yr = p['year']?.toDouble() ?? 2023.0;
                            final val = (p['predicted_affected'] ?? p['predicted_affected_population'] ?? 0.0).toDouble();
                            return FlSpot(yr, val);
                          }).toList(),
                          isCurved: true,
                          color: prNavy, // Serious dark prussian blue line
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: prNavy.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Feature Importance section
          const Text(
            'LINEAR ESTIMATOR PARAMETERS COEFFICIENTS IMPORTANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          _buildImportanceList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildImportanceList() {
    const borderSlate = Color(0xFFCBD5E1);
    const scForest = Color(0xFF2D6A4F);
    
    final list = [
      {
        'factor': 'HOUSES SWAMPED (H_D)',
        'weight': 0.58,
        'gloss': 'House destruction serves as the strongest predictor of displacement rates.'
      },
      {
        'factor': 'TOTAL FATALITIES (T_D)',
        'weight': 0.22,
        'gloss': 'Fatality densities correspond directly with intense localized flash swells.'
      },
      {
        'factor': 'ROAD SYSTEMS DESTROYED (R_D)',
        'weight': 0.12,
        'gloss': 'Road damages directly restrict secondary evacuation routes.'
      },
      {
        'factor': 'BRIDGES BLOWN (B_D)',
        'weight': 0.05,
        'gloss': 'Bridge collapse represents critical isolation risks in river corridors.'
      },
      {
        'factor': 'LIVESTOCK LOSSES (L_D)',
        'weight': 0.03,
        'gloss': 'Minor indicator indicating rural agricultural disruption thresholds.'
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        children: list.map((item) {
          final factor = item['factor'] as String;
          final weight = item['weight'] as double;
          final gloss = item['gloss'] as String;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      factor,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    Text(
                      '${(weight * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: scForest, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: weight,
                    backgroundColor: const Color(0xFFEDF2F7),
                    color: scForest,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'EXPLANATION: $gloss',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 9.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
