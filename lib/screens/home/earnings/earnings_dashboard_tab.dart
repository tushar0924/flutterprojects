import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/helper_bank_model.dart';
import '../../../models/helper_earnings_history_model.dart';
import '../../../providers/partner_provider.dart';
import '../../../utils/toast_helper.dart';
import 'earnings_models.dart';
import 'transaction_detail_screen.dart';
import 'widgets/earnings_dashboard_sections.dart';
import 'widgets/earnings_period_tabs.dart';

class EarningsDashboardTab extends ConsumerStatefulWidget {
  const EarningsDashboardTab({super.key});

  @override
  ConsumerState<EarningsDashboardTab> createState() => _EarningsDashboardTabState();
}

class _EarningsDashboardTabState extends ConsumerState<EarningsDashboardTab> {
  EarningsPeriod _selectedPeriod = EarningsPeriod.today;
  Map<String, dynamic>? _dashboardData;
  HelperEarningsHistoryResponse? _historyResponse;
  HelperBankAccount? _bankAccount;
  bool _isBalanceHidden = true;
  bool _isBankLoading = false;
  bool _showBankDetails = false;
  bool _isEditingBankDetails = false;
  bool _isSavingBankDetails = false;

  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();

  @override
  void dispose() {
    _holderController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEarnings());
  }

  Future<void> _loadEarnings() async {
    final isInitialLoad = _dashboardData == null;
    if (isInitialLoad) {
      // Mark as loading while first fetch runs — build gate is _dashboardData == null
    }
    try {
      final repo = ref.read(partnerRepositoryProvider);
      final responses = await Future.wait<dynamic>([
        repo.getHelperEarningsDashboard(),
        repo.getHelperEarningsHistory(page: 1, limit: 20),
      ]);

      final dashboardRes = responses[0] as Map<String, dynamic>;
      final historyRes = responses[1] as HelperEarningsHistoryResponse;

      if (mounted) {
        setState(() {
          _dashboardData = dashboardRes['data'] as Map<String, dynamic>?;
          _historyResponse = historyRes;
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  EarningsSnapshot get _snapshot {
    if (_dashboardData == null) {
      return const EarningsSnapshot(
        availableBalance: '₹0',
        pendingEarnings: '₹0',
        pendingMessage: '',
        minimumWithdrawal: 'Minimum Withdrawal: ₹500 • Processed within 24 hours',
        withdrawalHistory: <WithdrawalRecord>[],
      );
    }

    final periodKey = switch (_selectedPeriod) {
      EarningsPeriod.today => 'today',
      EarningsPeriod.thisWeek => 'week',
      EarningsPeriod.thisMonth => 'month',
    };

    final periodData = _dashboardData![periodKey];
    final section = periodData is Map<String, dynamic> ? periodData : null;
    final total = (section?['totalEarnings'] as num?) ?? 0;
    final pending = (section?['pendingEarnings'] as num?) ?? 0;
    final records = _mapHistoryRecords();

    return EarningsSnapshot(
      availableBalance: '₹$total',
      pendingEarnings: '₹$pending',
      pendingMessage: '',
      minimumWithdrawal: 'Minimum Withdrawal: ₹500 • Processed within 24 hours',
      withdrawalHistory: records,
    );
  }

  List<WithdrawalRecord> _mapHistoryRecords() {
    final items = _historyResponse?.items ?? const <HelperEarningsHistoryItem>[];
    if (items.isEmpty) return const <WithdrawalRecord>[];

    return items.map((item) {
      return WithdrawalRecord(
        transactionId: item.id,
        amount: '₹${_formatAmount(item.amount)}',
        title: item.title,
        method: _historySubtitle(item),
        status: _toTitleCase(item.status.toLowerCase()),
        date: item.date.isNotEmpty ? item.date : '-',
      );
    }).toList();
  }

  String _historySubtitle(HelperEarningsHistoryItem item) {
    if (item.type.trim().toUpperCase() == 'CREDIT') {
      return 'Wallet Credit';
    }
    return _toTitleCase(item.type.toLowerCase());
  }

  String _formatAmount(num amount) {
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount.toStringAsFixed(2);
  }

  String _toTitleCase(String text) {
    if (text.trim().isEmpty) return text;
    return text
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  void _showActionMessage(String title) {
    AppToast.showInfo('$title will be available soon');
  }

  Future<void> _onViewBankDetailsTap() async {
    if (_showBankDetails) {
      setState(() {
        _showBankDetails = false;
        _isEditingBankDetails = false;
      });
      return;
    }

    if (_bankAccount != null) {
      setState(() {
        _showBankDetails = true;
        _isEditingBankDetails = false;
      });
      return;
    }

    setState(() => _isBankLoading = true);
    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.getHelperBank();

    if (!mounted) return;

    if (res.success && res.account != null) {
      setState(() {
        _bankAccount = res.account;
        _showBankDetails = true;
        _isEditingBankDetails = false;
        _isBankLoading = false;
      });
      _fillBankControllers(res.account!);
      return;
    }

    setState(() {
      _isBankLoading = false;
      _showBankDetails = false;
    });
    AppToast.showInfo(res.message ?? 'Bank details not available');
  }

  void _fillBankControllers(HelperBankAccount account) {
    _holderController.text = account.accountHolderName;
    _accountNumberController.text = account.accountNumber;
    _ifscController.text = account.ifscCode;
    _bankNameController.text = account.bankName;
    _branchController.text = account.branchName;
  }

  void _onEditBankDetailsTap() {
    if (!_showBankDetails || _bankAccount == null) return;
    _fillBankControllers(_bankAccount!);
    setState(() => _isEditingBankDetails = true);
  }

  void _onCancelBankEdit() {
    if (_bankAccount != null) {
      _fillBankControllers(_bankAccount!);
    }
    setState(() => _isEditingBankDetails = false);
  }

  Future<void> _onSaveBankDetails() async {
    if (_bankAccount == null) return;

    final updated = _bankAccount!.copyWith(
      accountHolderName: _holderController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      ifscCode: _ifscController.text.trim(),
      bankName: _bankNameController.text.trim(),
      branchName: _branchController.text.trim(),
    );

    setState(() => _isSavingBankDetails = true);
    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.updateHelperBank(updated);

    if (!mounted) return;

    final success = res['success'] == true;
    if (success) {
      setState(() {
        _bankAccount = updated;
        _isEditingBankDetails = false;
        _isSavingBankDetails = false;
      });
      return;
    }

    setState(() => _isSavingBankDetails = false);
    AppToast.showError(res['message']?.toString() ?? 'Failed to update bank details');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B2545),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Color(0xFF0B2545)),
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 18),
              child: Column(
                children: [
                  const Text(
                    'Earnings Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
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
              child: Container(
                color: const Color(0xFFF3F5F8),
                child: RefreshIndicator(
                  onRefresh: _loadEarnings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                    child: Column(
                      children: [
                    AvailableBalanceCard(
                      balance: _snapshot.availableBalance,
                      periodLabel: _selectedPeriod.tabLabel,
                      isHidden: _isBalanceHidden,
                      onToggleVisibility: () {
                        setState(() => _isBalanceHidden = !_isBalanceHidden);
                      },
                    ),
                    const SizedBox(height: 10),
                    PendingEarningsCard(
                      pendingAmount: _snapshot.pendingEarnings,
                      pendingMessage: _snapshot.pendingMessage,
                    ),
                    const SizedBox(height: 10),
                    WithdrawMoneyCard(
                      onWithdrawTap: _onViewBankDetailsTap,
                      onBankDetailsTap: _onEditBankDetailsTap,
                      isEditEnabled: _showBankDetails && _bankAccount != null,
                    ),
                    if (_isBankLoading) ...[
                      const SizedBox(height: 10),
                      const BankDetailsLoadingCard(),
                    ],
                    if (_showBankDetails && _bankAccount != null) ...[
                      const SizedBox(height: 10),
                      BankDetailsInfoCard(
                        account: _bankAccount!,
                        isEditing: _isEditingBankDetails,
                        isSaving: _isSavingBankDetails,
                        accountHolderController: _holderController,
                        accountNumberController: _accountNumberController,
                        ifscController: _ifscController,
                        bankNameController: _bankNameController,
                        branchController: _branchController,
                        onCancel: _onCancelBankEdit,
                        onSave: _onSaveBankDetails,
                      ),
                    ],
                    const SizedBox(height: 10),
                    WithdrawalHistoryCard(
                      records: _snapshot.withdrawalHistory,
                      onExportTap: () => _showActionMessage('Export'),
                      onRecordTap: (record) {
                        if (record.transactionId.trim().isEmpty) {
                          AppToast.showInfo('Transaction details not available');
                          return;
                        }

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailScreen(
                              transactionId: record.transactionId,
                            ),
                          ),
                        );
                      },
                    ),
                    ],
                    ),
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
