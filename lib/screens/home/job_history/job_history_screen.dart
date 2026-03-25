import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job_history_model.dart';
import '../../../providers/partner_provider.dart';
import 'job_history_detail_screen.dart';
import 'widgets/job_history_card.dart';

class JobHistoryScreen extends ConsumerStatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  ConsumerState<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends ConsumerState<JobHistoryScreen> {
  bool _isLoading = true;
  String? _message;
  List<JobHistoryModel> _jobs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final repo = ref.read(partnerRepositoryProvider);
    final response = await repo.getBookingHistory(limit: 50);

    if (!mounted) return;

    if (response.success) {
      setState(() {
        _jobs = response.jobs;
        _message = response.message;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _jobs = response.jobs;
      _message = response.message ?? 'Failed to load job history';
      _isLoading = false;
    });
  }

  void _onViewDetails(JobHistoryModel job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobHistoryDetailScreen(summary: job),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2545),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Jobs History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_jobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          const Center(
            child: Text(
              'No job history found',
              style: TextStyle(
                color: Color(0xFF667085),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_message != null && _message!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                _message!,
                style: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: _jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return JobHistoryCard(
          job: job,
          onViewDetails: () => _onViewDetails(job),
        );
      },
    );
  }
}
