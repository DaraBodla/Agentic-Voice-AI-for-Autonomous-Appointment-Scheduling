import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' hide Provider;
import '../models/models.dart';
import '../providers/job_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/location_provider.dart';
import '../services/web_call_service.dart';
import '../utils/env_config.dart';
import '../utils/theme.dart';
import 'request_screen.dart';
import 'progress_screen.dart';
import 'results_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';
import 'live_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  int _bookPage = 0;
  bool _isDemo = true;

  @override
  void initState() {
    super.initState();
    _checkMode();
  }

  Future<void> _checkMode() async {
    try {
      final c = await WebCallService.getServerConfig();
      if (mounted) setState(() => _isDemo = c['demo_mode'] == true);
    } catch (_) {}
  }

  void _goToProgress() => setState(() { _tab = 1; _bookPage = 1; });
  void _goToResults() => setState(() { _tab = 1; _bookPage = 2; });
  void _goToRequest() { context.read<JobProvider>().reset(); setState(() { _bookPage = 0; _tab = 1; }); }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ContactProvider>();
    final loc = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.coral, AppColors.accent]), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Text('📞', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Call', style: GoogleFonts.dmSans(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.text)),
            TextSpan(text: 'Pilot', style: GoogleFonts.dmSans(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.coral)),
          ])),
        ]),
        actions: [
          _pill(_isDemo ? '● DEMO' : '● LIVE', _isDemo ? AppColors.orange : AppColors.green, _isDemo ? AppColors.orangeDim : AppColors.greenDim),
          if (loc.hasLocation) _pill('📍 ${loc.city.isNotEmpty ? loc.city : "Located"}', AppColors.teal, AppColors.tealDim),
          if (_tab == 1 && _bookPage > 0) IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _goToRequest),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: Consumer<JobProvider>(builder: (context, jp, _) {
        if (_tab == 1) {
          if (jp.status == JobStatus.inProgress && _bookPage == 0) WidgetsBinding.instance.addPostFrameCallback((_) => _goToProgress());
          if ((jp.status == JobStatus.completed || jp.status == JobStatus.stopped) && _bookPage == 1) WidgetsBinding.instance.addPostFrameCallback((_) => _goToResults());
        }
        switch (_tab) {
          case 0: return _buildHome(loc);
          case 1: return AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: _buildBookPage());
          case 2: return const ContactsScreen();
          case 3: return const SettingsScreen();
          default: return const SizedBox.shrink();
        }
      }),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: BottomNavigationBar(
          currentIndex: _tab, onTap: (i) => setState(() => _tab = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent, unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign), label: 'Campaign'),
            BottomNavigationBarItem(
              icon: Badge(isLabelVisible: cp.contacts.isNotEmpty, label: Text('${cp.contacts.length}', style: const TextStyle(fontSize: 9)), backgroundColor: AppColors.accent, child: const Icon(Icons.contacts_outlined)),
              label: 'Contacts',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) => Container(
    margin: const EdgeInsets.only(right: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: fg.withOpacity(0.3))),
    child: Text(text, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HOME PAGE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHome(LocationProvider loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero
        Center(child: Column(children: [
          Text('Book anything with', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.2)),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [AppColors.coral, AppColors.accent]).createShader(b),
            child: Text('one voice call', style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
          ),
          const SizedBox(height: 8),
          Text('AI calls providers near you, finds\navailable slots, and books for you.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim, height: 1.5)),
        ])),
        const SizedBox(height: 22),

        // Location
        _locBar(loc),
        const SizedBox(height: 22),

        // Quick Call
        _section('📞', 'Quick Voice Call'),
        const SizedBox(height: 10),
        Row(children: [
          _svcTile('🦷', 'Dentist', AppColors.teal, 'dentist'),
          const SizedBox(width: 10),
          _svcTile('🔧', 'Mechanic', AppColors.coral, 'mechanic'),
          const SizedBox(width: 10),
          _svcTile('💇', 'Salon', AppColors.accent, 'salon'),
        ]),
        const SizedBox(height: 22),

        // Campaign
        _section('🚀', 'AI Campaign'),
        const SizedBox(height: 10),
        _campaignBtn('🦷', 'Dentist Campaign', 'Call 5 dentists, rank slots', AppColors.teal, 'dentist'),
        const SizedBox(height: 8),
        _campaignBtn('🔧', 'Mechanic Campaign', 'Find best garage for your car', AppColors.coral, 'mechanic'),
        const SizedBox(height: 8),
        _campaignBtn('💇', 'Salon Campaign', 'Book a haircut near you', AppColors.accent, 'salon'),
        const SizedBox(height: 22),

        // Steps
        _section('💡', 'How It Works'),
        const SizedBox(height: 10),
        _step(1, 'Set location', 'We find providers near you', AppColors.teal),
        const SizedBox(height: 6),
        _step(2, 'AI calls them', 'Negotiates slots in real-time', AppColors.coral),
        const SizedBox(height: 6),
        _step(3, 'Review & book', 'Pick the best, confirm instantly', AppColors.accent),
      ]),
    );
  }

  // ── Location bar
  Widget _locBar(LocationProvider loc) {
    final ok = loc.hasLocation;
    return GestureDetector(
      onTap: () => setState(() => _tab = 3),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: ok ? AppColors.teal.withOpacity(0.3) : AppColors.orange.withOpacity(0.3))),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: ok ? AppColors.tealDim : AppColors.orangeDim, borderRadius: BorderRadius.circular(10)),
            child: Icon(ok ? Icons.location_on : Icons.location_off, size: 18, color: ok ? AppColors.teal : AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR LOCATION', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8)),
            Text(ok ? loc.displayAddress : 'Tap to set your location →', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: ok ? AppColors.text : AppColors.textDim), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
        ]),
      ),
    );
  }

  // ── Service tile (quick call)
  Widget _svcTile(String emoji, String label, Color color, String svc) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showCallSheet(svc),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 3),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Call', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w600, color: color))),
          ]),
        ),
      ),
    );
  }

  // ── Campaign button
  Widget _campaignBtn(String emoji, String title, String sub, Color color, String svc) {
    return GestureDetector(
      onTap: () => setState(() { _tab = 1; _bookPage = 0; }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            Text(sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textDim)),
          ])),
          Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        ]),
      ),
    );
  }

  Widget _section(String emoji, String title) => Row(children: [
    Text(emoji, style: const TextStyle(fontSize: 16)),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text)),
  ]);

  Widget _step(int n, String title, String sub, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Container(width: 26, height: 26, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(7)),
        child: Center(child: Text('$n', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
        Text(sub, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textDim)),
      ])),
    ]),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // CALL SHEET — discovers nearby providers from backend, then manual entry
  // ═══════════════════════════════════════════════════════════════════════════

  void _showCallSheet(String svc) {
    final loc = context.read<LocationProvider>();
    final cp = context.read<ContactProvider>();
    final saved = cp.getByType(svc);
    final emoji = svc == 'dentist' ? '🦷' : svc == 'mechanic' ? '🔧' : '💇';
    final label = svc == 'dentist' ? 'Dentist' : svc == 'mechanic' ? 'Mechanic' : 'Salon';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CallSheet(svc: svc, label: label, emoji: emoji, loc: loc, saved: saved,
        onCall: (name, phone) { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => LiveCallScreen(providerName: name, serviceType: svc, phone: phone))); }),
    );
  }

  Widget _buildBookPage() {
    switch (_bookPage) {
      case 0: return RequestScreen(key: const ValueKey('req'), onStarted: _goToProgress);
      case 1: return ProgressScreen(key: const ValueKey('prog'), onComplete: _goToResults);
      case 2: return ResultsScreen(key: const ValueKey('res'), onNewRequest: _goToRequest);
      default: return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Call Bottom Sheet — fetches providers from backend
// ═══════════════════════════════════════════════════════════════════════════════

class _CallSheet extends StatefulWidget {
  final String svc, label, emoji;
  final LocationProvider loc;
  final List<UserContact> saved;
  final void Function(String name, String phone) onCall;
  const _CallSheet({required this.svc, required this.label, required this.emoji, required this.loc, required this.saved, required this.onCall});
  @override
  State<_CallSheet> createState() => _CallSheetState();
}

class _CallSheetState extends State<_CallSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<Map<String, dynamic>> _nearby = [];
  bool _loading = false;

  @override
  void initState() { super.initState(); _loadNearby(); }

  Future<void> _loadNearby() async {
    if (!widget.loc.hasLocation) return;
    setState(() => _loading = true);
    final res = await widget.loc.findNearbyProviders(widget.svc);
    if (mounted) setState(() { _nearby = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Text('${widget.emoji} Call a ${widget.label}', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
        const SizedBox(height: 3),
        Text(widget.loc.hasLocation ? 'Providers near ${widget.loc.city.isNotEmpty ? widget.loc.city : "you"}' : 'Set location in Settings for nearby results',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textDim)),
        const SizedBox(height: 14),

        // Nearby
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
        else if (_nearby.isNotEmpty) ...[
          _label('NEARBY · ${_nearby.length} found'),
          const SizedBox(height: 6),
          ..._nearby.take(5).map(_provTile),
          const SizedBox(height: 10),
        ],

        // Saved
        if (widget.saved.isNotEmpty) ...[
          _label('YOUR CONTACTS'),
          const SizedBox(height: 6),
          Wrap(spacing: 6, children: widget.saved.map((c) => ActionChip(
            label: Text(c.name, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.accent)),
            backgroundColor: AppColors.accentDim, side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () { _nameCtrl.text = c.name; _phoneCtrl.text = c.phone; setState(() {}); },
          )).toList()),
          const SizedBox(height: 10),
        ],

        // Manual
        _label('OR ENTER MANUALLY'),
        const SizedBox(height: 6),
        TextField(controller: _nameCtrl, style: GoogleFonts.dmSans(color: AppColors.text), decoration: const InputDecoration(hintText: 'Provider name')),
        const SizedBox(height: 8),
        TextField(controller: _phoneCtrl, style: GoogleFonts.jetBrainsMono(color: AppColors.text, fontSize: 14), keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone (optional)')),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: () { final n = _nameCtrl.text.trim(); if (n.isEmpty) return; widget.onCall(n, _phoneCtrl.text.trim()); },
          icon: const Icon(Icons.call, size: 18, color: Colors.white),
          label: Text('Start Voice Call', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        )),
      ])),
    );
  }

  Widget _label(String t) => Text(t, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 0.8));

  Widget _provTile(Map<String, dynamic> p) {
    final name = p['name'] ?? ''; final phone = p['phone'] ?? ''; final rating = p['rating']; final dist = p['distance_km'];
    return GestureDetector(
      onTap: () { _nameCtrl.text = name; _phoneCtrl.text = phone; setState(() {}); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            if ((p['address'] ?? '').isNotEmpty) Text(p['address'], style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (rating != null && rating > 0) Padding(padding: const EdgeInsets.only(right: 6), child: Text('⭐ $rating', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.orange))),
          if (dist != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text('$dist km', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.blue))),
          GestureDetector(
            onTap: () => widget.onCall(name, phone),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(8)),
              child: Text('Call', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))),
          ),
        ]),
      ),
    );
  }
}