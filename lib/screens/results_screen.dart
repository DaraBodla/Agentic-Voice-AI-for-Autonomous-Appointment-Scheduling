import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/job_provider.dart';
import '../utils/theme.dart';

class ResultsScreen extends StatefulWidget {
  final VoidCallback onNewRequest;
  const ResultsScreen({super.key, required this.onNewRequest});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  RankedOption? _selected;
  bool _confirming = false;
  bool _showLogs = false;

  Future<void> _confirmBooking() async {
    if (_selected == null) return;
    setState(() => _confirming = true);
    await context.read<JobProvider>().confirmBooking(_selected!);
    setState(() => _confirming = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, job, _) {
        // If booked, show confirmation
        if (job.status == JobStatus.booked && job.confirmation != null) {
          return _buildConfirmation(job);
        }

        final ranked = job.rankedResults;
        final stopped = job.status == JobStatus.stopped;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stopped
                    ? 'Campaign Stopped'
                    : ranked.isNotEmpty
                        ? 'Best Options Found'
                        : 'No Results',
                style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text),
              ),
              const SizedBox(height: 6),
              Text(
                ranked.isNotEmpty
                    ? 'Found ${ranked.length} option${ranked.length > 1 ? 's' : ''} from ${job.doneCalls}/${job.totalCalls} successful calls. Select one to confirm.'
                    : stopped
                        ? 'The campaign was stopped before results could be collected.'
                        : 'No available slots found. Try expanding your time window.',
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim, height: 1.5),
              ),
              const SizedBox(height: 20),

              // Stats
              if (ranked.isNotEmpty) ...[
                Row(
                  children: [
                    _statBox('${job.totalCalls}', 'Calls Made', AppColors.accentLight),
                    const SizedBox(width: 8),
                    _statBox('${job.doneCalls}', 'Successful', AppColors.green),
                    const SizedBox(width: 8),
                    _statBox('${ranked.length}', 'Options', AppColors.orange),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Ranked results
              ...ranked.take(5).map((opt) => _buildResultCard(opt)),

              // Confirm button
              if (_selected != null) ...[
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Confirm booking with ${_selected!.providerName} at ${DateFormat('MMM d h:mm a').format(_selected!.slot.dateTime)}?',
                        style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _confirming ? null : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _confirming
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  '✓  Confirm Booking',
                                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (ranked.isEmpty) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onNewRequest,
                    child: const Text('🔄  Try Again'),
                  ),
                ),
              ],

              // Logs
              const SizedBox(height: 24),
              if (job.logs.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _showLogs = !_showLogs),
                  child: Row(
                    children: [
                      Icon(
                        _showLogs ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                        size: 18, color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text('Full Event Logs (${job.logs.length})',
                          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted)),
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

  Widget _buildResultCard(RankedOption opt) {
    final isSelected = _selected?.providerId == opt.providerId &&
        _selected?.slot.dateTime == opt.slot.dateTime;

    Color rankColor;
    switch (opt.rank) {
      case 1:
        rankColor = AppColors.accent;
      case 2:
        rankColor = AppColors.surface2;
      default:
        rankColor = AppColors.surface2;
    }

    return GestureDetector(
      onTap: () => setState(() => _selected = opt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: isSelected ? AppColors.green : AppColors.border, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.green.withOpacity(0.1), blurRadius: 12, spreadRadius: 2)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: opt.rank == 1 ? AppColors.accent : AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${opt.rank}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: opt.rank == 1 ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opt.providerName,
                          style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('MMM d h:mm a').format(opt.slot.dateTime)} • ${opt.slot.durationMinutes} min',
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(opt.score * 100).toStringAsFixed(0)}',
                  style: GoogleFonts.jetBrainsMono(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.accentLight),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details row
            Row(
              children: [
                _detailChip('⭐ ${opt.rating}'),
                const SizedBox(width: 12),
                _detailChip('🚗 ${opt.distanceMinutes.round()} min'),
                const SizedBox(width: 12),
                _confBadge(opt.confidence),
              ],
            ),
            const SizedBox(height: 10),

            // Why explanation
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
                border: const Border(left: BorderSide(color: AppColors.accent, width: 3)),
              ),
              child: Text(
                opt.why,
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textDim, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String text) {
    return Text(text, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textDim));
  }

  Widget _confBadge(double confidence) {
    Color bg, fg;
    if (confidence >= 0.8) {
      bg = AppColors.greenDim;
      fg = AppColors.green;
    } else if (confidence >= 0.5) {
      bg = AppColors.orangeDim;
      fg = AppColors.orange;
    } else {
      bg = AppColors.redDim;
      fg = AppColors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        '${(confidence * 100).round()}% conf',
        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: fg, fontWeight: FontWeight.w600),
      ),
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

  Widget _buildConfirmation(JobProvider job) {
    final conf = job.confirmation!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.green, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.greenDim,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('✓', style: TextStyle(fontSize: 28, color: AppColors.green))),
                ),
                const SizedBox(height: 16),
                Text('Appointment Booked!',
                    style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 6),
                Text('Your appointment has been confirmed.',
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    conf.confirmationCode,
                    style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.accentLight),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Provider: ${_selected?.providerName ?? conf.providerId}',
                    style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim)),
                const SizedBox(height: 4),
                Text(
                  'Time: ${DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(conf.slot))}',
                  style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onNewRequest,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('← Book Another Appointment',
                  style: GoogleFonts.dmSans(color: AppColors.textDim, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
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
