class HelperBankAccount {
  const HelperBankAccount({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.branchName,
  });

  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String branchName;

  HelperBankAccount copyWith({
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? bankName,
    String? branchName,
  }) {
    return HelperBankAccount(
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
    );
  }

  factory HelperBankAccount.fromJson(Map<String, dynamic> json) {
    return HelperBankAccount(
      accountHolderName: _pickString(
        json,
        const ['accountHolderName', 'accountName', 'holderName', 'name'],
      ),
      accountNumber: _pickString(
        json,
        const ['accountNumber', 'bankAccountNumber', 'accNumber'],
      ),
      ifscCode: _pickString(json, const ['ifscCode', 'ifsc']),
      bankName: _pickString(json, const ['bankName', 'bank']),
      branchName: _pickString(
        json,
        const ['branchName', 'branch', 'branchAddress'],
      ),
    );
  }

  bool get hasUsefulData {
    return accountHolderName.isNotEmpty ||
        accountNumber.isNotEmpty ||
        ifscCode.isNotEmpty ||
        bankName.isNotEmpty ||
        branchName.isNotEmpty;
  }

  Map<String, dynamic> toPutPayload() {
    return <String, dynamic>{
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'bankName': bankName,
      'branchName': branchName,
    };
  }
}

class HelperBankResponse {
  const HelperBankResponse({
    required this.success,
    required this.account,
    required this.message,
  });

  final bool success;
  final HelperBankAccount? account;
  final String? message;

  factory HelperBankResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    Map<String, dynamic>? accountJson;
    if (data is Map<String, dynamic>) {
      if (data['bank'] is Map<String, dynamic>) {
        accountJson = data['bank'] as Map<String, dynamic>;
      } else if (data['account'] is Map<String, dynamic>) {
        accountJson = data['account'] as Map<String, dynamic>;
      } else {
        accountJson = data;
      }
    }

    final parsedAccount = accountJson == null
        ? null
        : HelperBankAccount.fromJson(accountJson);

    return HelperBankResponse(
      success: json['success'] == true,
      account: (parsedAccount != null && parsedAccount.hasUsefulData)
          ? parsedAccount
          : null,
      message: json['message']?.toString(),
    );
  }
}

String _pickString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}
