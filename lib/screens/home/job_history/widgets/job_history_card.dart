import 'package:flutter/material.dart';

import '../../../../models/job_history_model.dart';

class JobHistoryCard extends StatelessWidget {
  const JobHistoryCard({
    super.key,
    required this.job,
    required this.onViewDetails,
  });

  final JobHistoryModel job;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final status = job.displayStatus;
    final statusColor = _statusColor(
      job.displayState.trim().isNotEmpty ? job.displayState : job.status,
    );
    final statusIcon = _statusIcon(
      job.displayState.trim().isNotEmpty ? job.displayState : job.status,
    );

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
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2A4A),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF052445), width: 1),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1D2939),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (job.hasRating) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 13,
                            color: Color(0xFFF6B51E),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            job.displayRating,
                            style: const TextStyle(
                              color: Color(0xFF475467),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    statusIcon,
                    size: 14,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF667085),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.displaySchedule,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (job.hasAddress) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2545),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  job.serviceType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 34,
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF98A2B3)),
                    foregroundColor: const Color(0xFF1D2939),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String rawStatus) {
    final normalized = rawStatus.trim().toUpperCase();
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return const Color(0xFFE11D48);
    }
    if (normalized == 'MISSED') return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  IconData _statusIcon(String rawStatus) {
    final normalized = rawStatus.trim().toUpperCase();
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return Icons.cancel;
    }
    if (normalized == 'MISSED') return Icons.cancel;
    return Icons.check_circle;
  }
}
