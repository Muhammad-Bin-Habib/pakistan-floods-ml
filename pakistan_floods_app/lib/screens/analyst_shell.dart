import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';
import 'analyst_overview_tab.dart';
import 'analyst_simulation_tab.dart';
import 'analyst_ingestion_tab.dart';
import 'analyst_trends_tab.dart';
import 'analyst_settings_tab.dart';
import 'login_screen.dart';

class AnalystShell extends StatefulWidget {
  const AnalystShell({super.key});

  @override
  State<AnalystShell> createState() => _AnalystShellState();
}

class _AnalystShellState extends State<AnalystShell> {
  int _currentIndex = 0;
  late List<Widget> _tabs;
  
  bool _isOnline = false;
  String _lastSyncedTime = '18:28:01 (2026-07-11)';
  String _modelR2Label = '63.2%';

  @override
  void initState() {
    super.initState();
    _rebuildTabs();
    _checkSystemMetricsStatus();
  }

  Future<void> _checkSystemMetricsStatus() async {
    final ip = AppState().serverIp;
    final res = await ApiService.getStats(ip);
    if (res['success'] == true && mounted) {
      setState(() {
        _isOnline = true;
        final modelR2 = res['model_metrics']?['r2']?.toString() ?? '0.6319';
        _modelR2Label = (double.tryParse(modelR2) != null) 
            ? '${(double.parse(modelR2) * 100).toStringAsFixed(1)}%' 
            : '63.2%';
        _lastSyncedTime = 'Just now';
      });
    }
  }

  void _rebuildTabs() {
    setState(() {
      _tabs = [
        AnalystOverviewTab(
          onNavigateToIngestion: () {
            setState(() => _currentIndex = 2);
          },
        ),
        const AnalystSimulationTab(),
        const AnalystIngestionTab(),
        const AnalystTrendsTab(),
        AnalystSettingsTab(
          onStateModified: () {
            _checkSystemMetricsStatus();
            _rebuildTabs();
          },
        ),
      ];
    });
  }

  void _logout() {
    const prNavy = Color(0xFF1B365D);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'LOGOUT SESSION',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: prNavy),
        ),
        content: const Text(
          'Terminate operational terminal. Confirmed actions will flush security sessions.',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.black38, fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () {
              AppState().isLoggedIn = false;
              AppState().isGovernmentUser = false;
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC53030), // Colorblind-accessible red
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('DISCONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const prNavy = Color(0xFF1B365D);
    const scForest = Color(0xFF2D6A4F);
    const bgLight = Color(0xFFF1F5F9);
    const borderSlate = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Persistent Command Agency Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: borderSlate, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: prNavy, size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NDMA DISASTER INTELLIGENCE CONSOLE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: prNavy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text(
                                'OPERATING PICTURE: ACTIVE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: scForest,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black26,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'OFFICER: ${AppState().userName.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Connectivity Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isOnline ? scForest.withOpacity(0.08) : const Color(0xFFC53030).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _isOnline ? scForest.withOpacity(0.3) : const Color(0xFFC53030).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnline ? scForest : const Color(0xFFC53030),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isOnline ? 'SYSTEM CONNECTED' : 'OFFLINE SIMULATOR',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: _isOnline ? scForest : const Color(0xFFC53030),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFC53030), size: 20),
                        tooltip: 'Disconnect session',
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Operations Status Strip (Nielsen Heuristics: Visibility of system status)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFEDF2F7),
                border: Border(
                  bottom: BorderSide(color: borderSlate, width: 1.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.update_rounded, color: Color(0xFF475569), size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'DATA PROVENANCE: $_lastSyncedTime',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, color: Color(0xFF475569), size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'MODEL ACCURACY (R²): $_modelR2Label',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9E6),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFFFE0B2), width: 1.0),
                ),
              ),
              child: const Row(
                children: [
                   Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 14),
                   SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       'PROTOTYPE / ESTIMATION ESTIMATOR DISCLAIMER: This system is a predictive simulation tool. Calculations represent machine learning estimates only and should not be used as the sole basis for high-stakes operational planning or direct emergency dispatch. Actual flood impacts may deviate significantly.',
                       style: TextStyle(
                         fontSize: 9,
                         fontWeight: FontWeight.normal,
                         color: Color(0xFF92400E),
                         height: 1.3,
                       ),
                     ),
                   ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _tabs,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: prNavy,
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard_outlined, size: 20),
            activeIcon: Icon(Icons.space_dashboard_rounded, size: 20),
            label: 'OVERVIEW',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined, size: 20),
            activeIcon: Icon(Icons.analytics_rounded, size: 20),
            label: 'SIMULATION',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.publish_sharp, size: 20),
            activeIcon: Icon(Icons.publish_rounded, size: 20),
            label: 'INGESTION',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_sharp, size: 20),
            activeIcon: Icon(Icons.timeline_rounded, size: 20),
            label: 'TRENDS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_input_component_outlined, size: 20),
            activeIcon: Icon(Icons.settings_input_component_sharp, size: 20),
            label: 'CONTROLS',
          ),
        ],
      ),
    );
  }
}
