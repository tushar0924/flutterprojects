import 'earnings_models.dart';

const Map<EarningsPeriod, EarningsSnapshot> kEarningsSnapshots = {
  EarningsPeriod.today: EarningsSnapshot(
    availableBalance: '₹638',
    pendingEarnings: '₹2638',
    pendingMessage: 'From 8 jobs • Available on 1 Dec',
    minimumWithdrawal: 'Minimum Withdrawal: ₹500 • Processed within 24 hours',
    withdrawalHistory: [
      WithdrawalRecord(
        amount: '₹500',
        method: 'Bank Transfer',
        status: 'Completed',
        date: '20 Nov',
      ),
      WithdrawalRecord(
        amount: '₹390',
        method: 'UPI',
        status: 'Completed',
        date: '16 Nov',
      ),
      WithdrawalRecord(
        amount: '₹420',
        method: 'Bank Transfer',
        status: 'Completed',
        date: '10 Nov',
      ),
    ],
  ),
  EarningsPeriod.thisWeek: EarningsSnapshot(
    availableBalance: '₹2410',
    pendingEarnings: '₹1890',
    pendingMessage: 'From 16 jobs • Available on 3 Dec',
    minimumWithdrawal: 'Minimum Withdrawal: ₹500 • Processed within 24 hours',
    withdrawalHistory: [
      WithdrawalRecord(
        amount: '₹1200',
        method: 'Bank Transfer',
        status: 'Completed',
        date: '28 Nov',
      ),
      WithdrawalRecord(
        amount: '₹700',
        method: 'UPI',
        status: 'Completed',
        date: '26 Nov',
      ),
      WithdrawalRecord(
        amount: '₹510',
        method: 'Bank Transfer',
        status: 'Completed',
        date: '24 Nov',
      ),
    ],
  ),
  EarningsPeriod.thisMonth: EarningsSnapshot(
    availableBalance: '₹7860',
    pendingEarnings: '₹3240',
    pendingMessage: 'From 42 jobs • Available on 5 Dec',
    minimumWithdrawal: 'Minimum Withdrawal: ₹500 • Processed within 24 hours',
    withdrawalHistory: [
      WithdrawalRecord(
        amount: '₹3000',
        method: 'Bank Transfer',
        status: 'Completed',
        date: '30 Nov',
      ),
      WithdrawalRecord(
        amount: '₹1850',
        method: 'UPI',
        status: 'Completed',
        date: '22 Nov',
      ),
      WithdrawalRecord(
        amount: '₹2200',
        method: 'Bank Transfer',
        status: 'Completed',
        date: '14 Nov',
      ),
    ],
  ),
};
