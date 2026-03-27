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
    final status = _statusText(job.status);
    final statusColor = _statusColor(job.status);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                      const SizedBox(height: 2),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2545),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      job.serviceType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF344054),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.displaySchedule,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF344054),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
                    size: 15,
                    color: Color(0xFF344054),
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
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  job.displayAmount,
                  style: const TextStyle(
                    color: Color(0xFF008FF0),
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCAD2DB)),
                    foregroundColor: const Color(0xFF1D2939),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  String _statusText(String rawStatus) {
    final normalized = rawStatus.trim().toUpperCase();
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return 'Canceled';
    }
    if (normalized == 'COMPLETED') return 'Completed';
    if (normalized.isEmpty) return 'Completed';
    return '${normalized[0]}${normalized.substring(1).toLowerCase()}';
  }

  Color _statusColor(String rawStatus) {
    final normalized = rawStatus.trim().toUpperCase();
    if (normalized == 'CANCELLED' || normalized == 'CANCELED') {
      return const Color(0xFFE70F18);
    }
    return const Color(0xFF22C55E);
  }
}
