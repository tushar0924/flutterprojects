import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/partner_review_model.dart';
import '../../providers/partner_provider.dart';

class MyReviewsScreen extends ConsumerStatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  ConsumerState<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends ConsumerState<MyReviewsScreen> {
  static const List<String> _filters = ['All', 'Newest', 'Highest', 'Lowest'];

  bool _isLoading = true;
  String _selectedFilter = 'All';
  PartnerReviewsResponse _response = PartnerReviewsResponse.empty();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);
    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.getPartnerReviews();
    if (!mounted) return;
    setState(() {
      _response = res;
      _isLoading = false;
    });
  }

  List<PartnerReviewItem> get _filteredReviews {
    final list = List<PartnerReviewItem>.from(_response.reviews);
    switch (_selectedFilter) {
      case 'Newest':
        list.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );
        return list;
      case 'Highest':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        return list;
      case 'Lowest':
        list.sort((a, b) => a.rating.compareTo(b.rating));
        return list;
      default:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _response.summary;
    final reviews = _filteredReviews;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2239),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'My Reviews',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                children: [
                  _buildSummaryCard(summary),
                  const SizedBox(height: 14),
                  _buildFilterChips(),
                  const SizedBox(height: 10),
                  Text(
                    'Reviews (${summary.totalReviews})',
                    style: const TextStyle(
                      color: Color(0xFF1D2939),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (reviews.isEmpty)
                    _buildEmptyState()
                  else
                    ...reviews.map(_buildReviewCard),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(PartnerReviewSummary summary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2239),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B4D62), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8A00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                summary.averageRating.toStringAsFixed(2),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  height: 0.9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  index < summary.averageRating.round()
                      ? Icons.star
                      : Icons.star_border,
                  size: 16,
                  color: const Color(0xFFFFC300),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetric(summary.totalReviews.toString(), 'Reviews'),
              _metricDivider(),
              _buildMetric(summary.totalJobs.toString(), 'Total Jobs'),
              _metricDivider(),
              _buildMetric('${summary.reviewRate}%', 'Review Rate'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD0D5DD),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricDivider() {
    return Container(width: 1, height: 24, color: const Color(0xFF475467));
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter == _selectedFilter;
          return ChoiceChip(
            label: Text(
              filter,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF1D2939),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: selected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            showCheckmark: false,
            backgroundColor: const Color(0xFFF2F4F7),
            selectedColor: const Color(0xFF0B2239),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF0B2239)
                  : const Color(0xFFD0D5DD),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(PartnerReviewItem review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF0B2239),
                child: Text(
                  review.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        color: Color(0xFF1D2939),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (review.formattedDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 10,
                            color: Color(0xFF98A2B3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            review.formattedDate,
                            style: const TextStyle(
                              color: Color(0xFF98A2B3),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              _buildRatingStars(review.rating),
            ],
          ),
          if (review.reviewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${review.reviewText}"',
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 14,
          color: const Color(0xFFFDB022),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(
        _response.message.isEmpty
            ? 'No reviews available yet.'
            : _response.message,
        style: const TextStyle(color: Color(0xFF475467), fontSize: 13),
      ),
    );
  }
}
