import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/partner_provider.dart';
import 'earnings_data.dart';
import 'earnings_models.dart';
import 'widgets/earnings_dashboard_sections.dart';
import 'widgets/earnings_period_tabs.dart';

class EarningsDashboardTab extends ConsumerStatefulWidget {
  const EarningsDashboardTab({super.key});

  @override
  ConsumerState<EarningsDashboardTab> createState() => _EarningsDashboardTabState();
}

class _EarningsDashboardTabState extends ConsumerState<EarningsDashboardTab> {
  EarningsPeriod _selectedPeriod = EarningsPeriod.today;
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _history;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEarnings());
  }

  Future<void> _loadEarnings() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(partnerRepositoryProvider);
      final summaryRes = await repo.getEarningsSummary();
      final historyRes = await repo.getEarningsHistory(page: 1, limit: 10);
      if (mounted) {
        setState(() {
          _summary = summaryRes['summary'] as Map<String, dynamic>?;
          _history = historyRes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  EarningsSnapshot get _snapshot {
    if (_isLoading || _summary == null) {
      return kEarningsSnapshots[_selectedPeriod]!;
    }
    final s = _summary!;
    final total = (s['totalEarnings'] as num?) ?? 0;
    final pending = (s['pendingPayout'] as num?) ?? 0;
    final completed = (s['completedJobs'] as num?) ?? 0;
    final history = _history?['history'] as List<dynamic>? ?? [];
    final records = history.take(5).map((e) {
      final m = e as Map<String, dynamic>;
      return WithdrawalRecord(
        amount: '₹${m['amount'] ?? 0}',
        method: 'Payout',
        status: m['status'] as String? ?? '—',
        date: _formatDate(m['paidAt'] ?? m['createdAt']),
      );
    }).toList();
    return EarningsSnapshot(
      availableBalance: '₹$total',
      pendingEarnings: '₹$pending',
      pendingMessage: 'From $completed jobs',
      minimumWithdrawal: 'Minimum Withdrawal: ₹500 • Processed within 24 hours',
      withdrawalHistory: records.isNotEmpty ? records : kEarningsSnapshots[_selectedPeriod]!.withdrawalHistory,
    );
  }

  String _formatDate(dynamic d) {
    if (d == null) return '—';
    final s = d.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

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
              child: RefreshIndicator(
                onRefresh: _loadEarnings,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          ],
        ),
      ),
    );
  }
}
