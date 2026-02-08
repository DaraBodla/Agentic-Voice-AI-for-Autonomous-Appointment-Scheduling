import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/job_provider.dart';
import '../utils/theme.dart';
import 'request_screen.dart';
import 'progress_screen.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentPage = 0; // 0=request, 1=progress, 2=results

  void _goToProgress() => setState(() => _currentPage = 1);
  void _goToResults() => setState(() => _currentPage = 2);
  void _goToRequest() {
    context.read<JobProvider>().reset();
    setState(() => _currentPage = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('📞', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                children: [
                  TextSpan(text: 'Call', style: TextStyle(color: AppColors.text)),
                  TextSpan(text: 'Pilot', style: TextStyle(color: AppColors.accentLight)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenDim,
              border: Border.all(color: AppColors.green),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '● DEMO',
              style: TextStyle(
                color: AppColors.green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (_currentPage > 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textDim),
              onPressed: _goToRequest,
              tooltip: 'New Request',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, _) {
          // Auto-navigate based on state
          if (jobProvider.status == JobStatus.inProgress && _currentPage == 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _goToProgress());
          }
          if ((jobProvider.status == JobStatus.completed ||
                  jobProvider.status == JobStatus.stopped) &&
              _currentPage == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _goToResults());
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildPage(),
          );
        },
      ),
    );
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case 0:
        return RequestScreen(
          key: const ValueKey('request'),
          onStarted: _goToProgress,
        );
      case 1:
        return ProgressScreen(
          key: const ValueKey('progress'),
          onComplete: _goToResults,
        );
      case 2:
        return ResultsScreen(
          key: const ValueKey('results'),
          onNewRequest: _goToRequest,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
