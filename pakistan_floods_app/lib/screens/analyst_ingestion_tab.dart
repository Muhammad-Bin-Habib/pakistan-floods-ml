import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/app_state.dart';

class AnalystIngestionTab extends StatefulWidget {
  const AnalystIngestionTab({super.key});
  @override
  State<AnalystIngestionTab> createState() => _AnalystIngestionTabState();
}

class _AnalystIngestionTabState extends State<AnalystIngestionTab> {
  final _formKey = GlobalKey<FormState>();
  String _selectedProvince = 'Sindh';
  int _year = 2024;
  double _affectedPop = 120000, _fatalities = 120, _housesDamaged = 8900, _roadsDamaged = 450, _bridgesDestroyed = 14, _livestockLost = 2800;
  bool _isSavingRef = false;
  String _warningMsg = '';

  void _runHeuristicChecksCheck() {
    String warn = '';
    if (_fatalities > _affectedPop) warn = 'Fatalities cannot exceed affected population.';
    else if (_housesDamaged > (_affectedPop / 2)) warn = 'House damage density anomaly flag.';
    setState(() => _warningMsg = warn);
  }

  Future<void> _submitIngestion() async {
    if (!_formKey.currentState!.validate() || _warningMsg.isNotEmpty) return;
    _formKey.currentState!.save();
    setState(() => _isSavingRef = true);

    final payload = {'region': _selectedProvince, 'year': _year, 'houses_damaged': _housesDamaged, 'total_deaths': _fatalities, 'roads_damaged': _roadsDamaged, 'bridges_destroyed': _bridgesDestroyed, 'livestock_lost': _livestockLost, 'affected_population': _affectedPop};
    final res = await ApiService.reportDisaster(AppState().serverIp, payload);

    if (mounted) {
      setState(() => _isSavingRef = false);
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFF10B981), content: Text('Record successfully committed to EOC database.'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 641;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Field Observations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 2, offset: const Offset(0, 1))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('All inputs are required for compliance tracking.', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                  const SizedBox(height: 24),
                  if (isDesktop) ...[
                    Row(children: [Expanded(child: _dd()), const SizedBox(width: 16), Expanded(child: _inp('Year', _year.toDouble(), (v) { _year = v.toInt(); _runHeuristicChecksCheck(); }))]),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: _inp('Displaced Pop *', _affectedPop, (v) { _affectedPop = v; _runHeuristicChecksCheck(); })), const SizedBox(width: 16), Expanded(child: _inp('Fatalities *', _fatalities, (v) { _fatalities = v; _runHeuristicChecksCheck(); }))]),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: _inp('Houses Swamped *', _housesDamaged, (v) { _housesDamaged = v; _runHeuristicChecksCheck(); })), const SizedBox(width: 16), Expanded(child: _inp('Roads Destroyed (km) *', _roadsDamaged, (v) { _roadsDamaged = v; _runHeuristicChecksCheck(); }))]),
                    const SizedBox(height: 16),
                    Row(children: [Expanded(child: _inp('Bridges *', _bridgesDestroyed, (v) { _bridgesDestroyed = v; _runHeuristicChecksCheck(); })), const SizedBox(width: 16), Expanded(child: _inp('Livestock *', _livestockLost, (v) { _livestockLost = v; _runHeuristicChecksCheck(); }))]),
                  ] else ...[
                    _dd(), const SizedBox(height: 16), _inp('Year', _year.toDouble(), (v) { _year = v.toInt(); _runHeuristicChecksCheck(); }), const SizedBox(height: 16),
                    _inp('Displaced Pop *', _affectedPop, (v) { _affectedPop = v; _runHeuristicChecksCheck(); }), const SizedBox(height: 16), _inp('Fatalities *', _fatalities, (v) { _fatalities = v; _runHeuristicChecksCheck(); }), const SizedBox(height: 16),
                    _inp('Houses Swamped *', _housesDamaged, (v) { _housesDamaged = v; _runHeuristicChecksCheck(); }), const SizedBox(height: 16), _inp('Roads Destroyed (km) *', _roadsDamaged, (v) { _roadsDamaged = v; _runHeuristicChecksCheck(); }), const SizedBox(height: 16),
                    _inp('Bridges *', _bridgesDestroyed, (v) { _bridgesDestroyed = v; _runHeuristicChecksCheck(); }), const SizedBox(height: 16), _inp('Livestock *', _livestockLost, (v) { _livestockLost = v; _runHeuristicChecksCheck(); })
                  ],
                  if (_warningMsg.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_warningMsg, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSavingRef ? null : _submitIngestion,
                    child: _isSavingRef ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Commit Record'),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _dd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Province *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProvince,
          items: ['Sindh', 'KP', 'Punjab', 'Balochistan', 'AJ&K', 'GB', 'ICT'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) { if (v != null) setState(() => _selectedProvince = v); },
        ),
      ],
    );
  }

  Widget _inp(String label, double init, ValueChanged<double> onCh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: init.toStringAsFixed(0),
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 15),
          validator: (v) => v == null || double.tryParse(v) == null ? 'Required' : null,
          onChanged: (v) { final p = double.tryParse(v); if (p != null && p >= 0) onCh(p); },
        ),
      ],
    );
  }
}
