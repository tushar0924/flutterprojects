import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/partner_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/user_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) => PartnerRepository());
final servicesRepositoryProvider = Provider<ServicesRepository>((ref) => ServicesRepository());
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());
