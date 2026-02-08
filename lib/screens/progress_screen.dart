import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class ProgressScreen extends StatelessWidget {
  final VoidCallback onComplete;
  const ProgressScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final jp = context.watch<JobProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Live Campaign', style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.text)),
            Text('Calling providers now...', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim)),
          ]),
          TextButton.icon(
            onPressed: () { jp.stopCampaign(); onComplete(); },
            icon: Icon(Icons.stop_circle, size: 18, color: AppColors.red),
            label: Text('Stop All', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.red)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.red.withOpacity(0.3)))),
          ),
        ]),
        const SizedBox(height: 18),

        // Stats
        Row(children: [
          _stat('${jp.totalCalls}', 'Total', AppColors.text, AppColors.bg),
          const SizedBox(width: 8),
          _stat('${jp.activeCalls}', 'Active', AppColors.blue, AppColors.blueDim),
          const SizedBox(width: 8),
          _stat('${jp.doneCalls}', 'Done', AppColors.green, AppColors.greenDim),
          const SizedBox(width: 8),
          _stat('${jp.failedCalls}', 'Failed', AppColors.red, AppColors.redDim),
        ]),
        const SizedBox(height: 18),

        // Call list
        ...jp.calls.map((call) => _callCard(call)),

        // Event logs
        if (jp.logs.isNotEmpty) ...[
          const SizedBox(height: 14),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Event Logs (${jp.logs.length})', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted)),
            children: jp.logs.reversed.take(10).map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Expanded(child: Text('${l.event}  ${l.data}', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            )).toList(),
          ),
        ],
      ]),
    );
  }

  Widget _stat(String val, String label, Color fg, Color bg) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Text(val, style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: fg)),
        Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
      ]),
    ),
  );

  Widget _callCard(CallResult call) {
    Color statusColor; String statusLabel;
    switch (call.status) {
      case CallStatus.queued: statusColor = AppColors.textMuted; statusLabel = 'QUEUED'; break;
      case CallStatus.calling: statusColor = AppColors.blue; statusLabel = 'CALLING'; break;
      case CallStatus.done: statusColor = AppColors.green; statusLabel = 'DONE'; break;
      case CallStatus.failed: statusColor = AppColors.red; statusLabel = 'FAILED'; break;
      case CallStatus.stopped: statusColor = AppColors.orange; statusLabel = 'STOPPED'; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: call.status == CallStatus.calling ? AppColors.blue.withOpacity(0.4) : call.status == CallStatus.failed ? AppColors.red.withOpacity(0.3) : AppColors.border),
      ),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(call.providerName, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          const SizedBox(height: 2),
          Text(
            call.status == CallStatus.calling ? '🤖 On the line...'
                : call.status == CallStatus.done ? '✓ ${call.offeredSlots.length} slot${call.offeredSlots.length != 1 ? "s" : ""} found'
                : call.status == CallStatus.failed ? '✕ ${call.notes.isNotEmpty ? call.notes : "No availability"}'
                : call.status == CallStatus.queued ? 'Waiting...' : 'Stopped',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textDim),
          ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(statusLabel, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ]),
    );
  }
}