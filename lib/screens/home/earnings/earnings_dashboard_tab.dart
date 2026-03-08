import 'package:flutter/material.dart';

import 'earnings_data.dart';
import 'earnings_models.dart';
import 'widgets/earnings_dashboard_sections.dart';
import 'widgets/earnings_period_tabs.dart';

class EarningsDashboardTab extends StatefulWidget {
  const EarningsDashboardTab({super.key});

  @override
  State<EarningsDashboardTab> createState() => _EarningsDashboardTabState();
}

class _EarningsDashboardTabState extends State<EarningsDashboardTab> {
  EarningsPeriod _selectedPeriod = EarningsPeriod.today;

  EarningsSnapshot get _snapshot => kEarningsSnapshots[_selectedPeriod]!;

  void _showActionMessage(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be available soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F5F8),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF0B2545),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  const Text(
                    'Earnings Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EarningsPeriodTabs(
                    selectedPeriod: _selectedPeriod,
                    onChanged: (period) {
                      setState(() => _selectedPeriod = period);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    AvailableBalanceCard(
                      balance: _snapshot.availableBalance,
                      periodLabel: _selectedPeriod.tabLabel,
                    ),
                    const SizedBox(height: 10),
                    PendingEarningsCard(
                      pendingAmount: _snapshot.pendingEarnings,
                      pendingMessage: _snapshot.pendingMessage,
                    ),
                    const SizedBox(height: 10),
                    WithdrawMoneyCard(
                      minimumWithdrawalText: _snapshot.minimumWithdrawal,
                      onWithdrawTap: () => _showActionMessage('Withdraw'),
                      onBankDetailsTap: () =>
                          _showActionMessage('Bank details'),
                    ),
                    const SizedBox(height: 10),
                    WithdrawalHistoryCard(
                      records: _snapshot.withdrawalHistory,
                      onExportTap: () => _showActionMessage('Export'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
