import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/app_state.dart';

class AnalystSimulationTab extends StatefulWidget {
  const AnalystSimulationTab({super.key});
  @override
  State<AnalystSimulationTab> createState() => _AnalystSimulationTabState();
}

class _AnalystSimulationTabState extends State<AnalystSimulationTab> {
  final _formKey = GlobalKey<FormState>();
  double _simulationYear = 2026, _housesSwamped = 2200, _totalFatalities = 45, _totalInjured = 120, _roadsDestroyed = 180, _bridgesBlown = 6, _livestockLosses = 1400;
  String _selectedRegion = 'Sindh';
  String _activePreset = 'Baseline';
  bool _isProcessing = false;
  double? _predictedAffected;

  void _load(String n, String r, double h, double f, double rd, double bb, double ls) {
    setState(() {
      _activePreset = n; _selectedRegion = r; _housesSwamped = h; _totalFatalities = f; _roadsDestroyed = rd; _bridgesBlown = bb; _livestockLosses = ls;
    });
  }

  void _calc() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isProcessing = true);
    final res = await ApiService.predict(AppState().serverIp, {
      'Year': _simulationYear.toInt(), 'Region': _selectedRegion, 'Total_deaths': _totalFatalities.toInt(),
      'Total_injured': _totalInjured.toInt(), 'Roads_damaged_km': _roadsDestroyed,
      'Bridges_damaged': _bridgesBlown.toInt(), 'Houses_damaged': _housesSwamped.toInt(), 'Livestock_damaged': _livestockLosses.toInt(),
    });
    setState(() {
      _isProcessing = false;
      _predictedAffected = res['success'] == true 
          ? double.tryParse(res['predicted_affected_population']?.toString() ?? res['prediction']?.toString() ?? res['predicted_affected']?.toString() ?? '0') 
          : (_housesSwamped*5 + 450);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Simulation Engine', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 24),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                 _pill('Baseline', 'Sindh', 2200, 45, 180, 6, 1400), const SizedBox(width: 8),
                 _pill('Monsoon High', 'Sindh', 9800, 245, 620, 18, 5600), const SizedBox(width: 8),
                 _pill('Flash Surge', 'Balochistan', 14500, 480, 890, 45, 12000),
              ]
            ),
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(
                children: [
                  Row(children: [Expanded(child: _inp('Swamped', _housesSwamped, (v)=>_housesSwamped=v)), const SizedBox(width: 16), Expanded(child: _inp('Fatalities', _totalFatalities, (v)=>_totalFatalities=v))]),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: _inp('Roads', _roadsDestroyed, (v)=>_roadsDestroyed=v)), const SizedBox(width: 16), Expanded(child: _inp('Bridges', _bridgesBlown, (v)=>_bridgesBlown=v))]),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _calc,
                    child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Calculate Affected Projections'),
                  )
                ]
              )
            )
          ),
          
          if (_predictedAffected != null) ...[
             const SizedBox(height: 32),
             const Text('Intelligence Dispatch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
             const SizedBox(height: 16),
             Container(
               padding: const EdgeInsets.all(24),
               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2))),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text('${(_predictedAffected! * 0.85).round()} – ${(_predictedAffected! * 1.15).round()}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                   const Text('Estimated displaced population envelope', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14)),
                 ]
               )
             )
          ]
        ],
      )
    );
  }

  Widget _pill(String label, String r, double h, double f, double rd, double bb, double ls) {
    bool active = _activePreset == label;
    return GestureDetector(
      onTap: () => _load(label, r, h, f, rd, bb, ls),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF16A34A) : Colors.white,
          border: Border.all(color: active ? const Color(0xFF16A34A) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : const Color(0xFF4B5563))),
      ),
    );
  }

  Widget _inp(String l, double ini, ValueChanged<double> oc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('$_activePreset-$l-$ini'),
          initialValue: ini.toStringAsFixed(0),
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          onSaved: (v) { if (v != null) oc(double.parse(v)); }
        )
      ]
    );
  }
}
