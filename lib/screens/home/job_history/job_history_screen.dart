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
  static const int _pageSize = 15;

  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _message;
  List<JobHistoryModel> _jobs = [];
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory(reset: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 160) {
      _loadMore();
    }
  }

  Future<void> _loadHistory({required bool reset}) async {
    setState(() {
      if (reset) {
        _isLoading = true;
        _isLoadingMore = false;
        _message = null;
        _page = 1;
        _hasMore = true;
        _jobs = [];
      }
    });

    final repo = ref.read(partnerRepositoryProvider);
    final response = await repo.getBookingHistory(page: _page, limit: _pageSize);

    if (!mounted) return;

    if (response.success) {
      final nextPage = response.pagination.page > 0
          ? response.pagination.page + 1
          : _page + 1;
      final hasMore = response.pagination.totalPages > 0
          ? response.pagination.hasNextPage
          : response.jobs.length == _pageSize;

      setState(() {
        _jobs = reset ? response.jobs : [..._jobs, ...response.jobs];
        _message = response.message;
        _isLoading = false;
        _isLoadingMore = false;
        _page = nextPage;
        _hasMore = hasMore;
      });
      return;
    }

    setState(() {
      if (reset) {
        _jobs = response.jobs;
        _isLoading = false;
      }
      _message = response.message ?? 'Failed to load job history';
      _isLoadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _loadHistory(reset: false);
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
        onRefresh: () => _loadHistory(reset: true),
        child: _isLoading
            ? _buildSkeletonList()
            : _buildContent(),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _JobHistorySkeletonCard(),
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

    final itemCount = _isLoadingMore ? _jobs.length + 1 : _jobs.length;

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= _jobs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final job = _jobs[index];
        return JobHistoryCard(
          job: job,
          onViewDetails: () => _onViewDetails(job),
        );
      },
    );
  }
}

class _JobHistorySkeletonCard extends StatelessWidget {
  const _JobHistorySkeletonCard();

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE4E7EC);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8DEE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 42,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 12,
                width: 70,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: baseColor),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: baseColor),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 22,
                width: 110,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Spacer(),
              Container(
                height: 34,
                width: 92,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF98A2B3)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
