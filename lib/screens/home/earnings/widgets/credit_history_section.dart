import 'package:flutter/material.dart';

import '../earnings_models.dart';

class WithdrawalHistoryCard extends StatelessWidget {
  const WithdrawalHistoryCard({
    super.key,
    required this.records,
    required this.onExportTap,
    required this.onRecordTap,
  });

  final List<WithdrawalRecord> records;
  final VoidCallback onExportTap;
  final ValueChanged<WithdrawalRecord> onRecordTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Text(
                      'Credit History',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onExportTap,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 16,
                          color: Color(0xFF344054),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Export',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF344054),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HistoryTile(
                record: record,
                onTap: () => onRecordTap(record),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.onTap});

  final WithdrawalRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA6F4C5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FADF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: Color(0xFF027A48),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.method,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.date,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${record.amount}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF027A48),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FADF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF027A48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
