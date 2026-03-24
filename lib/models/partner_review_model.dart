class PartnerReviewsResponse {
  const PartnerReviewsResponse({
    required this.success,
    required this.message,
    required this.summary,
    required this.reviews,
  });

  final bool success;
  final String message;
  final PartnerReviewSummary summary;
  final List<PartnerReviewItem> reviews;

  factory PartnerReviewsResponse.empty({String message = 'No reviews found'}) {
    return PartnerReviewsResponse(
      success: false,
      message: message,
      summary: const PartnerReviewSummary(),
      reviews: const [],
    );
  }

  factory PartnerReviewsResponse.fromJson(Map<String, dynamic> json) {
    final rootData = json['data'];
    final data = rootData is Map<String, dynamic> ? rootData : json;

    final summaryMap = _asMap(data['summary']) ?? _asMap(data['stats']) ?? data;

    final rawReviews =
        _asList(data['reviews']) ??
        _asList(data['items']) ??
        _asList(json['reviews']) ??
        const [];

    return PartnerReviewsResponse(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      summary: PartnerReviewSummary.fromJson(summaryMap),
      reviews: rawReviews
          .whereType<Map<String, dynamic>>()
          .map(PartnerReviewItem.fromJson)
          .toList(),
    );
  }
}

class PartnerReviewSummary {
  const PartnerReviewSummary({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.totalJobs = 0,
    this.reviewRate = 0,
  });

  final double averageRating;
  final int totalReviews;
  final int totalJobs;
  final int reviewRate;

  factory PartnerReviewSummary.fromJson(Map<String, dynamic> json) {
    return PartnerReviewSummary(
      averageRating: _toDouble(
        json['averageRating'] ?? json['avgRating'] ?? json['rating'],
      ),
      totalReviews: _toInt(
        json['totalReviews'] ?? json['reviewsCount'] ?? json['reviewCount'],
      ),
      totalJobs: _toInt(json['totalJobs'] ?? json['jobsCount']),
      reviewRate: _toInt(json['reviewRate'] ?? json['ratingPercent']),
    );
  }
}

class PartnerReviewItem {
  const PartnerReviewItem({
    required this.reviewerName,
    required this.reviewText,
    required this.rating,
    required this.createdAt,
  });

  final String reviewerName;
  final String reviewText;
  final int rating;
  final DateTime? createdAt;

  factory PartnerReviewItem.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']) ?? _asMap(json['customer']) ?? const {};
    final rawName =
        json['reviewerName'] ?? user['name'] ?? user['fullName'] ?? 'User';

    return PartnerReviewItem(
      reviewerName: rawName.toString().trim().isEmpty
          ? 'User'
          : rawName.toString().trim(),
      reviewText: (json['review'] ?? json['comment'] ?? json['message'] ?? '')
          .toString()
          .trim(),
      rating: _toInt(json['rating']).clamp(0, 5),
      createdAt: _toDateTime(
        json['createdAt'] ?? json['date'] ?? json['reviewDate'],
      ),
    );
  }

  String get initials {
    if (reviewerName.trim().isEmpty) return 'U';
    return reviewerName.trim().substring(0, 1).toUpperCase();
  }

  String get formattedDate {
    final d = createdAt;
    if (d == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[d.month - 1];
    return '$month ${d.day}, ${d.year}';
  }
}

Map<String, dynamic>? _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : null;
}

List<dynamic>? _asList(dynamic value) {
  return value is List<dynamic> ? value : null;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
