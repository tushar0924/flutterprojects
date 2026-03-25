import 'package:flutter/material.dart';

import '../../../../models/helper_bank_model.dart';

class WithdrawMoneyCard extends StatelessWidget {
  const WithdrawMoneyCard({
    super.key,
    required this.onWithdrawTap,
    required this.onBankDetailsTap,
    required this.isEditEnabled,
  });

  final VoidCallback onWithdrawTap;
  final VoidCallback onBankDetailsTap;
  final bool isEditEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'View or edit your bank details',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onWithdrawTap,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF98A2B3),
                      side: const BorderSide(color: Color(0xFF98A2B3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'View Bank Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: isEditEnabled ? onBankDetailsTap : null,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isEditEnabled
                          ? Colors.white
                          : const Color(0xFFF2F4F7),
                      side: BorderSide(
                        color: isEditEnabled
                            ? const Color(0xFFD0D5DD)
                            : const Color(0xFFE4E7EC),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: isEditEnabled
                              ? const Color(0xFF344054)
                              : const Color(0xFF98A2B3),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Edit Bank Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isEditEnabled
                                  ? const Color(0xFF344054)
                                  : const Color(0xFF98A2B3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BankDetailsLoadingCard extends StatelessWidget {
  const BankDetailsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: const Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class BankDetailsInfoCard extends StatelessWidget {
  const BankDetailsInfoCard({
    super.key,
    required this.account,
    required this.isEditing,
    required this.isSaving,
    required this.accountHolderController,
    required this.accountNumberController,
    required this.ifscController,
    required this.bankNameController,
    required this.branchController,
    required this.onCancel,
    required this.onSave,
  });

  final HelperBankAccount account;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController accountHolderController;
  final TextEditingController accountNumberController;
  final TextEditingController ifscController;
  final TextEditingController bankNameController;
  final TextEditingController branchController;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B2D52),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.credit_card_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'For withdrawals',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isEditing) ...[
            _BankField(
              label: 'Account Holder Name',
              icon: Icons.person_outline,
              value: account.accountHolderName,
            ),
            const SizedBox(height: 10),
            _BankField(
              label: 'Account Number',
              icon: Icons.credit_card,
              value: account.accountNumber,
            ),
            const SizedBox(height: 10),
            _BankField(
              label: 'IFSC Code',
              icon: Icons.account_balance_outlined,
              value: account.ifscCode,
            ),
            const SizedBox(height: 10),
            _BankField(
              label: 'Bank Name',
              icon: null,
              value: account.bankName,
              isHighlighted: true,
            ),
            const SizedBox(height: 10),
            _BankField(
              label: 'Branch Name',
              icon: null,
              value: account.branchName,
            ),
          ] else ...[
            _EditableBankField(
              label: 'Account Holder Name',
              controller: accountHolderController,
            ),
            const SizedBox(height: 10),
            _EditableBankField(
              label: 'Account Number',
              controller: accountNumberController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            _EditableBankField(
              label: 'IFSC Code',
              controller: ifscController,
            ),
            const SizedBox(height: 10),
            _EditableBankField(
              label: 'Bank Name',
              controller: bankNameController,
            ),
            const SizedBox(height: 10),
            _EditableBankField(
              label: 'Branch Name',
              controller: branchController,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: isSaving ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2F4F7),
                        side: const BorderSide(color: Color(0xFFF2F4F7)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF344054),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10C650),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EditableBankField extends StatelessWidget {
  const _EditableBankField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF667085),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF101828),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF98A2B3)),
            ),
          ),
        ),
      ],
    );
  }
}

class _BankField extends StatelessWidget {
  const _BankField({
    required this.label,
    required this.value,
    this.icon,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '-' : value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF667085),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        if (isHighlighted)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF101828),
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        else
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: const Color(0xFF98A2B3)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF101828),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
