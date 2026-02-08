import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/web_call_service.dart';
import '../utils/theme.dart';

class LiveCallScreen extends StatefulWidget {
  final String providerName, serviceType, phone;
  const LiveCallScreen({super.key, required this.providerName, required this.serviceType, this.phone = ''});
  @override
  State<LiveCallScreen> createState() => _LiveCallScreenState();
}

class _LiveCallScreenState extends State<LiveCallScreen> with SingleTickerProviderStateMixin {
  final WebCallService _call = WebCallService();
  final List<TranscriptLine> _transcript = [];
  final ScrollController _scroll = ScrollController();
  WebCallStatus _status = WebCallStatus.connecting;
  String? _error;
  DateTime? _start;
  Timer? _timer;
  String _elapsed = '00:00';
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _startCall();
  }

  Future<void> _startCall() async {
    _call.onStatus.listen((s) { if (!mounted) return; setState(() => _status = s); if (s == WebCallStatus.connected) { _start = DateTime.now(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick()); } });
    _call.onTranscript.listen((l) { if (!mounted) return; setState(() => _transcript.add(l)); Future.delayed(const Duration(milliseconds: 50), () { if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut); }); });
    _call.onError.listen((e) { if (mounted) setState(() => _error = e); });
    final ok = await _call.startCall(providerName: widget.providerName, serviceType: widget.serviceType, phone: widget.phone);
    if (!ok && mounted) setState(() => _status = WebCallStatus.error);
  }

  void _tick() { if (_start == null || !mounted) return; final d = DateTime.now().difference(_start!); setState(() => _elapsed = '${d.inMinutes.toString().padLeft(2, "0")}:${(d.inSeconds % 60).toString().padLeft(2, "0")}'); }
  void _end() { _call.endCall(); _timer?.cancel(); if (mounted) setState(() => _status = WebCallStatus.ended); }
  bool get _live => _status == WebCallStatus.connecting || _status == WebCallStatus.connected;

  String get _emoji => widget.serviceType == 'dentist' ? '🦷' : widget.serviceType == 'mechanic' ? '🔧' : '💇';

  @override
  void dispose() { _call.dispose(); _timer?.cancel(); _pulse.dispose(); _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: _live ? null : IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        automaticallyImplyLeading: false,
        title: Row(children: [
          Text(_emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.providerName, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text), overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _sColor().withOpacity(0.1), border: Border.all(color: _sColor().withOpacity(0.4)), borderRadius: BorderRadius.circular(20)),
            child: Text(_sLabel(), style: TextStyle(color: _sColor(), fontSize: 11, fontWeight: FontWeight.w600))),
        ],
      ),
      body: Column(children: [
        // Visual
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Column(children: [
            AnimatedBuilder(animation: _pulse, builder: (_, __) {
              final s = _live ? 1.0 + _pulse.value * 0.06 : 1.0;
              return Transform.scale(scale: s, child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _sColor().withOpacity(0.1), border: Border.all(color: _sColor().withOpacity(0.3), width: 2)),
                child: const Center(child: Text('🤖', style: TextStyle(fontSize: 36))),
              ));
            }),
            const SizedBox(height: 12),
            Text(_sLabel(), style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
            Text(_elapsed, style: GoogleFonts.jetBrainsMono(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: _live ? AppColors.greenDim : AppColors.bg, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: _live ? AppColors.green : AppColors.textMuted)),
                const SizedBox(width: 6),
                Text(_live ? 'Mic active' : 'Call ended', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: _live ? AppColors.green : AppColors.textMuted)),
              ])),
          ]),
        ),

        // Transcript
        Expanded(child: _transcript.isEmpty
            ? Center(child: Text(_live ? 'Waiting for conversation...' : 'No transcript.', style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textMuted)))
            : ListView.separated(
                controller: _scroll, padding: const EdgeInsets.all(16), itemCount: _transcript.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final l = _transcript[i]; final isAi = l.role == TranscriptRole.ai;
                  return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: isAi ? AppColors.tealDim : AppColors.accentDim, borderRadius: BorderRadius.circular(4)),
                      child: Text(isAi ? 'AI' : 'YOU', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: isAi ? AppColors.teal : AppColors.accent, letterSpacing: 0.4))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.text, style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim, height: 1.4))),
                  ]));
                })),

        if (_error != null)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.redDim, border: Border.all(color: AppColors.red), borderRadius: BorderRadius.circular(10)),
            child: Text(_error!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.red)))),

        // Bottom button
        Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, height: 50, child: _live
            ? ElevatedButton.icon(onPressed: _end, icon: const Icon(Icons.call_end, color: Colors.white), label: Text('End Call', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))
            : ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white), label: Text('Back', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))))),
      ]),
    );
  }

  String _sLabel() => switch (_status) { WebCallStatus.connecting => 'Connecting...', WebCallStatus.connected => 'On the Line', WebCallStatus.completed => 'Complete', WebCallStatus.ended => 'Ended', WebCallStatus.error => 'Error' };
  Color _sColor() => switch (_status) { WebCallStatus.connecting => AppColors.orange, WebCallStatus.connected => AppColors.green, WebCallStatus.completed => AppColors.green, WebCallStatus.ended => AppColors.textMuted, WebCallStatus.error => AppColors.red };
}