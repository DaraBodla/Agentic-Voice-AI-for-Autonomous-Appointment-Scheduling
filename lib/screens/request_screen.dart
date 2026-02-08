import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' hide Provider;
import '../models/models.dart';
import '../providers/job_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/location_provider.dart';
import '../utils/theme.dart';

class RequestScreen extends StatefulWidget {
  final VoidCallback onStarted;
  const RequestScreen({super.key, required this.onStarted});
  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  String _serviceType = 'dentist';
  late DateTime _startDate, _endDate;
  late TextEditingController _locationCtrl;
  int _maxProviders = 5;
  CampaignMode _mode = CampaignMode.swarm;
  double _earliestWeight = 0.4, _ratingWeight = 0.3, _distanceWeight = 0.3;
  bool _loading = false;
  bool _includeMyContacts = true;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    final loc = context.read<LocationProvider>();
    _locationCtrl = TextEditingController(text: loc.address.isNotEmpty ? loc.address : 'Downtown');
  }

  @override
  void dispose() { _locationCtrl.dispose(); super.dispose(); }

  Future<void> _startCampaign() async {
    setState(() => _loading = true);
    final cp = context.read<ContactProvider>();
    final loc = context.read<LocationProvider>();
    List<Provider> customProviders = _includeMyContacts ? cp.getProvidersForType(_serviceType) : [];

    final request = UserRequest(
      serviceType: _serviceType, timeWindowStart: _startDate, timeWindowEnd: _endDate,
      location: _locationCtrl.text.trim().isNotEmpty ? _locationCtrl.text.trim() : 'Downtown',
      latitude: loc.lat, longitude: loc.lng, maxProviders: _maxProviders, mode: _mode,
      preferences: Preferences(earliestWeight: _earliestWeight, ratingWeight: _ratingWeight, distanceWeight: _distanceWeight),
      customProviders: customProviders,
    );
    context.read<JobProvider>().startCampaign(request);
    widget.onStarted();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactProvider>();
    final loc = context.watch<LocationProvider>();
    final myContacts = cp.getByType(_serviceType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Start Campaign', style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 4),
        Text('AI will call multiple providers and find the best slot for you.', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim)),
        const SizedBox(height: 20),

        // Card
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lbl('SERVICE TYPE'), const SizedBox(height: 8),
            _serviceSelector(),
            const SizedBox(height: 18),

            if (myContacts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.accentDim, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.contacts, size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${myContacts.length} saved contact${myContacts.length > 1 ? 's' : ''}', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent))),
                  Switch(value: _includeMyContacts, onChanged: (v) => setState(() => _includeMyContacts = v), activeColor: AppColors.accent),
                ]),
              ),
              const SizedBox(height: 14),
            ],

            _lbl('TIME WINDOW'), const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _dateBtn('From', _startDate, (d) => setState(() => _startDate = d))),
              const SizedBox(width: 10),
              Expanded(child: _dateBtn('To', _endDate, (d) => setState(() => _endDate = d))),
            ]),
            const SizedBox(height: 18),

            Row(children: [
              Expanded(child: _lbl('LOCATION')),
              if (loc.hasLocation) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.greenDim, borderRadius: BorderRadius.circular(4)), child: Text('✓ GPS', style: GoogleFonts.jetBrainsMono(fontSize: 9, color: AppColors.green, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            TextField(controller: _locationCtrl, style: GoogleFonts.dmSans(color: AppColors.text),
              decoration: InputDecoration(hintText: 'Your area...', prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 20),
                suffixIcon: loc.hasLocation ? const Icon(Icons.gps_fixed, color: AppColors.green, size: 16) : null)),
            const SizedBox(height: 18),

            _lbl('PROVIDERS TO CALL'), const SizedBox(height: 8), _countSelector(),
            const SizedBox(height: 18),

            _lbl('CALL MODE'), const SizedBox(height: 8), _modeSelector(),
            const SizedBox(height: 18),

            _lbl('PRIORITY WEIGHTS'), const SizedBox(height: 8),
            _slider('⏰ Earliest', _earliestWeight, (v) => setState(() => _earliestWeight = v)),
            _slider('⭐ Rating', _ratingWeight, (v) => setState(() => _ratingWeight = v)),
            _slider('📍 Distance', _distanceWeight, (v) => setState(() => _distanceWeight = v)),
          ]),
        ),
        const SizedBox(height: 18),

        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : _startCampaign,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('🚀  Start Campaign', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        )),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _lbl(String t) => Text(t, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8));

  Widget _serviceSelector() {
    final svcs = [('dentist', '🦷', 'Dentist'), ('mechanic', '🔧', 'Mechanic'), ('salon', '💇', 'Salon')];
    return Row(children: svcs.map((s) {
      final sel = _serviceType == s.$1;
      return Expanded(child: GestureDetector(
        onTap: () => setState(() => _serviceType = s.$1),
        child: Container(
          margin: EdgeInsets.only(right: s.$1 != 'salon' ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: sel ? AppColors.accentDim : AppColors.bg, border: Border.all(color: sel ? AppColors.accent : AppColors.border), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(s.$2, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(s.$3, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? AppColors.accent : AppColors.textDim)),
          ]),
        ),
      ));
    }).toList());
  }

  Widget _dateBtn(String label, DateTime date, ValueChanged<DateTime> onChanged) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 90)));
        if (d != null) onChanged(d);
      },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: AppColors.bg, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          const Icon(Icons.calendar_today, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
            Text('${date.month}/${date.day}/${date.year}', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    );
  }

  Widget _countSelector() => Row(children: [3, 5, 8, 10].map((n) {
    final sel = _maxProviders == n;
    return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
      onTap: () => setState(() => _maxProviders = n),
      child: Container(width: 44, height: 38, decoration: BoxDecoration(color: sel ? AppColors.accent : AppColors.bg, border: Border.all(color: sel ? AppColors.accent : AppColors.border), borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text('$n', style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textDim)))),
    ));
  }).toList());

  Widget _modeSelector() => Row(children: [
    _modeBtn(CampaignMode.single, '📞', 'Sequential'),
    const SizedBox(width: 8),
    _modeBtn(CampaignMode.swarm, '🐝', 'Parallel'),
  ]);

  Widget _modeBtn(CampaignMode mode, String ico, String label) {
    final sel = _mode == mode;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? AppColors.accentDim : AppColors.bg, border: Border.all(color: sel ? AppColors.accent : AppColors.border), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(ico, style: const TextStyle(fontSize: 16)), const SizedBox(width: 6),
          Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? AppColors.accent : AppColors.textDim)),
        ]),
      ),
    ));
  }

  Widget _slider(String label, double val, ValueChanged<double> onChanged) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim)),
      Text('${(val * 100).round()}%', style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.accent)),
    ]),
    SliderTheme(data: SliderThemeData(activeTrackColor: AppColors.accent, inactiveTrackColor: AppColors.border, thumbColor: AppColors.accent, overlayColor: AppColors.accent.withOpacity(0.1), trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
      child: Slider(value: val, min: 0, max: 1, divisions: 20, onChanged: onChanged)),
  ]));
}