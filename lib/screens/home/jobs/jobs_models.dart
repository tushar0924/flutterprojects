class UpcomingJobItem {
  const UpcomingJobItem({
    required this.name,
    required this.rating,
    required this.serviceType,
    required this.schedule,
    required this.duration,
    required this.address,
    required this.amount,
  });

  final String name;
  final String rating;
  final String serviceType;
  final String schedule;
  final String duration;
  final String address;
  final String amount;
}
