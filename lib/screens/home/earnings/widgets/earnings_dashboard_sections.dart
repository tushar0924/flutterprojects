import 'package:flutter/material.dart';

import '../earnings_models.dart';

class AvailableBalanceCard extends StatelessWidget {
  const AvailableBalanceCard({
    super.key,
    required this.balance,
    required this.periodLabel,
  });

  final String balance;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF06C14A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF04A03D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            balance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              periodLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEFDFA0)),
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
                    color: Color(0xFF101828),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDB022),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Processing',
                  style: TextStyle(
                    color: Color(0xFF663300),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pendingAmount,
            style: const TextStyle(
              color: Color(0xFF7A3E00),
              fontSize: 27,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pendingMessage,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 9.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WithdrawMoneyCard extends StatelessWidget {
  const WithdrawMoneyCard({
    super.key,
    required this.minimumWithdrawalText,
    required this.onWithdrawTap,
    required this.onBankDetailsTap,
  });

  final String minimumWithdrawalText;
  final VoidCallback onWithdrawTap;
  final VoidCallback onBankDetailsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Withdraw Money',
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Withdraw your available balance to your registered bank account',
            style: TextStyle(
              color: Color(0xFF667085),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 27,
                  child: ElevatedButton.icon(
                    onPressed: onWithdrawTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 12,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Withdraw',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 27,
                  child: OutlinedButton.icon(
                    onPressed: onBankDetailsTap,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    icon: const Icon(
                      Icons.credit_card,
                      size: 12,
                      color: Color(0xFF344054),
                    ),
                    label: const Text(
                      'Bank Details',
                      style: TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            minimumWithdrawalText,
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontSize: 9.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WithdrawalHistoryCard extends StatelessWidget {
  const WithdrawalHistoryCard({
    super.key,
    required this.records,
    required this.onExportTap,
  });

  final List<WithdrawalRecord> records;
  final VoidCallback onExportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Withdrawal History',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onExportTap,
                child: const Row(
                  children: [
                    Icon(
                      Icons.download_outlined,
                      size: 12,
                      color: Color(0xFF344054),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Export',
                      style: TextStyle(
                        color: Color(0xFF344054),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEF2F6)),
            ),
            child: Column(
              children: records.map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _WithdrawalRecordRow(record: record),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalRecordRow extends StatelessWidget {
  const _WithdrawalRecordRow({required this.record});

  final WithdrawalRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFFB7F0C8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 11,
              color: Color(0xFF15803D),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.amount,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 10.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  record.method,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 9.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                record.date,
                style: const TextStyle(
                  color: Color(0xFF98A2B3),
                  fontSize: 8.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
