import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' hide Provider;
import '../providers/location_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/env_config.dart';
import '../utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final settings = context.watch<SettingsProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Settings', style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 4),
        Text('Configure location, mode, and connections.', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim)),
        const SizedBox(height: 22),

        _sec('📍', 'Your Location'),
        const SizedBox(height: 10),
        _locCard(loc),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _btn(Icons.my_location, 'Detect GPS', AppColors.teal, () => loc.detectViaGPS(), loading: loc.state == LocationState.detecting)),
          const SizedBox(width: 10),
          Expanded(child: _btn(Icons.edit_location_alt, 'Set Manually', AppColors.accent, () => _showLocEditor(context, loc))),
        ]),
        if (loc.hasLocation) Padding(padding: const EdgeInsets.only(top: 8), child: _btn(Icons.delete_outline, 'Clear', AppColors.red, () => loc.clear())),
        const SizedBox(height: 22),

        _sec('📏', 'Search Radius'),
        const SizedBox(height: 10),
        _radiusCard(loc),
        const SizedBox(height: 22),

        _sec('⚙️', 'App Mode'),
        const SizedBox(height: 10),
        _modeCard(settings),
        const SizedBox(height: 22),

        _sec('🔌', 'Services'),
        const SizedBox(height: 10),
        _statusCard(),
        const SizedBox(height: 22),

        _sec('🖥️', 'Backend'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(EnvConfig.backendUrl, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: AppColors.accent)),
            const SizedBox(height: 4),
            Text('WS: ${EnvConfig.backendWsUrl}', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textMuted)),
          ]),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _sec(String emoji, String title) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
  ]);

  Widget _locCard(LocationProvider loc) {
    final ok = loc.hasLocation;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: ok ? AppColors.teal.withOpacity(0.3) : AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(ok ? Icons.location_on : Icons.location_off, size: 18, color: ok ? AppColors.teal : AppColors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(loc.displayAddress, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text), maxLines: 2)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: ok ? AppColors.greenDim : AppColors.orangeDim, borderRadius: BorderRadius.circular(6)),
            child: Text(ok ? '✓ Set' : 'Not set', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: ok ? AppColors.green : AppColors.orange)),
          ),
        ]),
        if (ok) Padding(padding: const EdgeInsets.only(top: 6), child: Text(loc.coordsText, style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textMuted))),
        if (loc.error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(loc.error!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.red))),
      ]),
    );
  }

  Widget _btn(IconData icon, String label, Color color, VoidCallback onTap, {bool loading = false}) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (loading) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color)) else Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );

  Widget _radiusCard(LocationProvider loc) {
    final opts = [(1000, '1 km'), (2000, '2 km'), (5000, '5 km'), (10000, '10 km'), (20000, '20 km')];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: opts.map((o) {
          final sel = loc.radiusMeters == o.$1;
          return GestureDetector(
            onTap: () => loc.setRadius(o.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: sel ? AppColors.accent : AppColors.bg, border: Border.all(color: sel ? AppColors.accent : AppColors.border), borderRadius: BorderRadius.circular(8)),
              child: Text(o.$2, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AppColors.textDim)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _modeCard(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(settings.isDemoMode ? Icons.science_outlined : Icons.cloud_done_outlined, color: settings.isDemoMode ? AppColors.orange : AppColors.green, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(settings.isDemoMode ? 'Demo Mode' : 'Live Mode', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          Text(settings.isDemoMode ? 'Scripted responses' : 'Real ElevenLabs AI calls', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textDim)),
        ])),
        Switch(value: !settings.isDemoMode, onChanged: (_) => settings.toggleMode(), activeColor: AppColors.green),
      ]),
    );
  }

  Widget _statusCard() {
    final status = EnvConfig.serviceStatus;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: status.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: e.value ? AppColors.green : AppColors.red)),
          const SizedBox(width: 10),
          Expanded(child: Text(_svcLabel(e.key), style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text))),
          Text(e.value ? 'Ready' : 'Not set', style: GoogleFonts.jetBrainsMono(fontSize: 11, color: e.value ? AppColors.green : AppColors.textMuted)),
        ]),
      )).toList()),
    );
  }

  String _svcLabel(String k) => switch (k) {
    'openai' => 'OpenAI',
    'elevenlabs' => 'ElevenLabs',
    'backend' => 'Backend',
    'google_places' => 'Google Places',
    'google_calendar' => 'Google Calendar',
    _ => k,
  };

  void _showLocEditor(BuildContext context, LocationProvider loc) {
    final addrCtrl = TextEditingController(text: loc.address);
    final latCtrl = TextEditingController(text: loc.lat?.toString() ?? '');
    final lngCtrl = TextEditingController(text: loc.lng?.toString() ?? '');

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Text('📍 Set Location', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 4),
          Text('Enter address and coordinates.', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim)),
          const SizedBox(height: 16),

          Text('ADDRESS', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 5),
          TextField(controller: addrCtrl, style: GoogleFonts.dmSans(color: AppColors.text), decoration: const InputDecoration(hintText: 'e.g. Clifton, Karachi')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LATITUDE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
              const SizedBox(height: 5),
              TextField(controller: latCtrl, style: GoogleFonts.jetBrainsMono(color: AppColors.text, fontSize: 14), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(hintText: '24.8607')),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LONGITUDE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
              const SizedBox(height: 5),
              TextField(controller: lngCtrl, style: GoogleFonts.jetBrainsMono(color: AppColors.text, fontSize: 14), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(hintText: '67.0011')),
            ])),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              final addr = addrCtrl.text.trim();
              if (lat != null && lng != null) { loc.setManual(lat: lat, lng: lng, address: addr); }
              else if (addr.isNotEmpty) { loc.setFromAddress(addr); }
              else { return; }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Save Location', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          )),
        ]),
      ),
    );
  }
}