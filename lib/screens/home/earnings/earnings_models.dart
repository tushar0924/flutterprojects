enum EarningsPeriod { today, thisWeek, thisMonth }

extension EarningsPeriodLabel on EarningsPeriod {
  String get tabLabel {
    switch (this) {
      case EarningsPeriod.today:
        return 'Today';
      case EarningsPeriod.thisWeek:
        return 'This Week';
      case EarningsPeriod.thisMonth:
        return 'This Month';
    }
  }
}

class WithdrawalRecord {
  const WithdrawalRecord({
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
  });

  final String amount;
  final String method;
  final String status;
  final String date;
}

class EarningsSnapshot {
  const EarningsSnapshot({
    required this.availableBalance,
    required this.pendingEarnings,
    required this.pendingMessage,
    required this.minimumWithdrawal,
    required this.withdrawalHistory,
  });

  final String availableBalance;
  final String pendingEarnings;
  final String pendingMessage;
  final String minimumWithdrawal;
  final List<WithdrawalRecord> withdrawalHistory;
}
