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
  String _pingTime = '42 ms';

  @override
  void initState() {
    super.initState();
    _rebuildTabs();
    _checkSystemMetricsStatus();
  }

  Future<void> _checkSystemMetricsStatus() async {
    final ip = AppState().serverIp;
    final start = DateTime.now();
    final res = await ApiService.getStats(ip);
    final end = DateTime.now();
    
    if (res['success'] == true && mounted) {
      setState(() {
        _isOnline = true;
        _pingTime = '${end.difference(start).inMilliseconds} ms';
        final modelR2 = res['model_metrics']?['r2']?.toString() ?? '0.5954';
        _modelR2Label = (double.tryParse(modelR2) != null) 
            ? '${(double.parse(modelR2) * 100).toStringAsFixed(1)}%' 
            : '59.5%';
        _lastSyncedTime = 'Just now';
      });
    } else {
      if(mounted) {
        setState(() {
          _isOnline = false;
        });
      }
    }
  }

  void _rebuildTabs() {
    setState(() {
      _tabs = [
        AnalystOverviewTab(onNavigateToIngestion: () => setState(() => _currentIndex = 2)),
        const AnalystSimulationTab(),
        const AnalystIngestionTab(),
        const AnalystTrendsTab(),
        AnalystSettingsTab(onStateModified: () {
          _checkSystemMetricsStatus();
          _rebuildTabs();
        }),
      ];
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to securely disconnect your terminal session?', style: TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              AppState().isLoggedIn = false;
              AppState().isGovernmentUser = false;
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Disconnect'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const prGreen = Color(0xFF16A34A);
    const borderSlate = Color(0xFFE5E7EB);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1025;

    Widget mainContent = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: Column(
          children: [
            // Top App Bar Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: borderSlate, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isDesktop)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: prGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.shield_outlined, color: prGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'NDMA Intelligence',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Text(
                          'Intelligence Workspace',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Session: ${AppState().userName}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isOnline ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'Connected • $_pingTime' : 'Offline Mode',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFF6B7280), size: 22),
                        tooltip: 'Sign Out',
                        splashRadius: 20,
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Experimental Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBEB),
                border: Border(bottom: BorderSide(color: Color(0xFFFDE68A), width: 1)),
              ),
              child: const Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is a predictive simulation platform. Verify machine learning estimates before dispatch.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF92400E)),
                      ),
                    ),
                 ],
              ),
            ),
            
            // Tab Context
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _tabs,
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                   _buildSidebar(),
                   const VerticalDivider(width: 1, thickness: 1, color: borderSlate),
                   Expanded(child: mainContent),
                ],
              )
            : mainContent,
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF16A34A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.water_drop_rounded, color: Color(0xFF16A34A), size: 24),
                ),
                const SizedBox(width: 12),
                const Text('FloodGuard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sidebarItem(0, Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Overview'),
          _sidebarItem(1, Icons.analytics_outlined, Icons.analytics_rounded, 'Simulator'),
          _sidebarItem(2, Icons.add_box_outlined, Icons.add_box_rounded, 'Ingestion'),
          _sidebarItem(3, Icons.trending_up_rounded, Icons.trending_up, 'Trends & Core'),
          _sidebarItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Model Accuracy:\\n$_modelR2Label', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), height: 1.5)),
          )
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData outline, IconData filled, String label) {
    bool isActive = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF16A34A).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isActive ? filled : outline, color: isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280), size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF16A34A) : const Color(0xFF4B5563),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF16A34A),
        unselectedItemColor: const Color(0xFF6B7280),
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.space_dashboard_outlined), activeIcon: Icon(Icons.space_dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics_rounded), label: 'Simulator'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box_rounded), label: 'Ingest'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), activeIcon: Icon(Icons.trending_up), label: 'Trends'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
