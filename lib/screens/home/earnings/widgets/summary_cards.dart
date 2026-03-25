import 'package:flutter/material.dart';

class AvailableBalanceCard extends StatelessWidget {
  const AvailableBalanceCard({
    super.key,
    required this.balance,
    required this.periodLabel,
    required this.isHidden,
    required this.onToggleVisibility,
  });

  final String balance;
  final String periodLabel;
  final bool isHidden;
  final VoidCallback onToggleVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 152,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00C950),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00B649)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Earnings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleVisibility,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: const Color(0xFFE6FFE5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            isHidden ? '• • • • •' : balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              periodLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PendingEarningsCard extends StatelessWidget {
  const PendingEarningsCard({
    super.key,
    required this.pendingAmount,
    required this.pendingMessage,
  });

  final String pendingAmount;
  final String pendingMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2C94C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pending Earnings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDB022),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Processing',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pendingAmount,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFF733E0A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pendingMessage,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }
}
