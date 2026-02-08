import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' hide Provider;
import '../models/models.dart';
import '../providers/job_provider.dart';
import '../utils/theme.dart';

class ProgressScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const ProgressScreen({super.key, required this.onComplete});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _expandedTranscript;
  bool _showLogs = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, job, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + kill switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Campaign',
                          style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.isRunning ? 'Calling providers now...' : 'Campaign ${job.status.name}',
                          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim),
                        ),
                      ],
                    ),
                  ),
                  if (job.isRunning)
                    ElevatedButton.icon(
                      onPressed: () => job.stopCampaign(),
                      icon: const Icon(Icons.stop_circle, size: 18),
                      label: const Text('Stop All'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.redDim,
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Stats row
              Row(
                children: [
                  _statBox('${job.totalCalls}', 'Total', AppColors.text),
                  const SizedBox(width: 8),
                  _statBox('${job.activeCalls}', 'Active', AppColors.accentLight),
                  const SizedBox(width: 8),
                  _statBox('${job.doneCalls}', 'Done', AppColors.green),
                  const SizedBox(width: 8),
                  _statBox('${job.failedCalls}', 'Failed', AppColors.red),
                ],
              ),
              const SizedBox(height: 20),

              // Call list
              ...job.calls.asMap().entries.map((entry) {
                final i = entry.key;
                final call = entry.value;
                return _buildCallItem(call, i);
              }),

              if (job.calls.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                      ),
                      const SizedBox(height: 16),
                      Text('Initializing calls...', style: GoogleFonts.dmSans(color: AppColors.textMuted)),
                    ],
                  ),
                ),

              // Logs toggle
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _showLogs = !_showLogs),
                child: Row(
                  children: [
                    Icon(
                      _showLogs ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Event Logs (${job.logs.length})',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (_showLogs) _buildLogsPanel(job.logs),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildCallItem(CallResult call, int index) {
    final isCalling = call.status == CallStatus.calling;
    final isDone = call.status == CallStatus.done;
    final isFailed = call.status == CallStatus.failed;
    final isStopped = call.status == CallStatus.stopped;

    Color borderColor = AppColors.border;
    if (isCalling) borderColor = AppColors.accent;
    if (isDone) borderColor = AppColors.green;
    if (isFailed) borderColor = AppColors.red;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCalling ? AppColors.accent.withOpacity(0.05) : AppColors.surface,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusDot(call.status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.providerName,
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusText(call),
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textDim),
                    ),
                    if (isDone && call.validSlotCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          '${call.validSlotCount} valid slot(s) found',
                          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.green),
                        ),
                      ),
                  ],
                ),
              ),
              _statusBadge(call.status),
            ],
          ),

          // Transcript toggle
          if (isDone && call.transcriptSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() {
                _expandedTranscript = _expandedTranscript == call.providerId ? null : call.providerId;
              }),
              child: Text(
                _expandedTranscript == call.providerId ? '▾ Hide transcript' : '▸ Show transcript',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.accentLight),
              ),
            ),
            if (_expandedTranscript == call.providerId)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  call.transcriptSummary,
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppColors.textDim, height: 1.6),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _statusDot(CallStatus status) {
    Color color;
    bool animate = false;
    switch (status) {
      case CallStatus.queued:
        color = AppColors.textMuted;
      case CallStatus.calling:
        color = AppColors.accentLight;
        animate = true;
      case CallStatus.done:
        color = AppColors.green;
      case CallStatus.failed:
        color = AppColors.red;
      case CallStatus.stopped:
        color = AppColors.textMuted;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: animate
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8, spreadRadius: 2)]
            : null,
      ),
    );
  }

  Widget _statusBadge(CallStatus status) {
    String text;
    Color bg, fg;
    switch (status) {
      case CallStatus.queued:
        text = 'QUEUED'; bg = AppColors.surface2; fg = AppColors.textMuted;
      case CallStatus.calling:
        text = 'CALLING'; bg = AppColors.accent; fg = Colors.white;
      case CallStatus.done:
        text = 'DONE'; bg = AppColors.greenDim; fg = AppColors.green;
      case CallStatus.failed:
        text = 'FAILED'; bg = AppColors.redDim; fg = AppColors.red;
      case CallStatus.stopped:
        text = 'STOPPED'; bg = AppColors.surface2; fg = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.5)),
    );
  }

  String _statusText(CallResult call) {
    switch (call.status) {
      case CallStatus.calling:
        return '🔊 On the line...';
      case CallStatus.done:
        return '✓ ${call.durationSeconds}s • Confidence: ${(call.confidence * 100).round()}%';
      case CallStatus.failed:
        return '✕ No availability';
      case CallStatus.queued:
        return 'Waiting...';
      case CallStatus.stopped:
        return 'Cancelled';
    }
  }

  Widget _buildLogsPanel(List<EventLog> logs) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: logs.length,
        itemBuilder: (_, i) {
          final log = logs[i];
          final time = DateFormat('HH:mm:ss').format(log.timestamp);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$time ', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textMuted)),
                TextSpan(text: '[${log.event}] ', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.accentLight)),
                TextSpan(
                  text: log.data.entries.map((e) => '${e.key}=${e.value}').join(' '),
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, color: AppColors.textDim),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}