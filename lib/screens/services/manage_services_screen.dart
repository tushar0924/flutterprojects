import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/manage_service_model.dart';
import '../../providers/partner_provider.dart';
import '../../utils/toast_helper.dart';

class ManageServicesScreen extends ConsumerStatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  ConsumerState<ManageServicesScreen> createState() =>
      _ManageServicesScreenState();
}

class _ManageServicesScreenState extends ConsumerState<ManageServicesScreen> {
  static const List<String> _fallbackServices = [
    'Maid',
    'Cook',
    'Shop-helper',
    'Driver',
    'Nanny',
    'Elder Care',
    'Baby Sitter',
    'Patient Care',
  ];

  bool _loading = true;
  bool _saving = false;
  String _query = '';
  late final TextEditingController _searchController;
  List<_ServiceOption> _services = <_ServiceOption>[];
  Set<int> _selectedServiceIds = <int>{};
  late Set<int> _initialSelectedServiceIds; // Track initial state
  bool _hasChanges = false; // Track if selections have changed

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);

    final partnerRepo = ref.read(partnerRepositoryProvider);

    // Fetch available services from API
    final servicesResponse = await partnerRepo.getManageServices();
    
    // Fetch user's currently selected services from API
    final selectedServicesRes = await partnerRepo.getPartnerServices();

    if (!mounted) return;

    // Convert ManageService models to _ServiceOption
    final services = servicesResponse.services
        .map((s) => _ServiceOption(id: s.serviceId, name: s.name))
        .toList();

    // Extract selected IDs from the selected services response
    final selectedIdsFromApi = _extractSelectedIds(selectedServicesRes);
    final selectedNamesFromApi = _extractSelectedNames(selectedServicesRes);

    final resolvedServices = services.isEmpty
        ? _fallbackServices
              .asMap()
              .entries
              .map((e) => _ServiceOption(id: e.key + 1, name: e.value))
              .toList()
        : services;

    final resolvedSelectedIds = <int>{};
    if (selectedIdsFromApi.isNotEmpty) {
      resolvedSelectedIds.addAll(selectedIdsFromApi);
    } else if (selectedNamesFromApi.isNotEmpty) {
      for (final service in resolvedServices) {
        if (selectedNamesFromApi.contains(service.name.toLowerCase())) {
          resolvedSelectedIds.add(service.id);
        }
      }
    } else {
      for (final service in resolvedServices) {
        final normalized = service.name.toLowerCase();
        if (normalized == 'maid' || normalized == 'cook') {
          resolvedSelectedIds.add(service.id);
        }
      }
    }

    setState(() {
      _services = resolvedServices;
      _selectedServiceIds = resolvedSelectedIds;
      _initialSelectedServiceIds = Set<int>.from(resolvedSelectedIds); // Store initial state
      _hasChanges = false;
      _loading = false;
    });
  }

  Set<int> _extractSelectedIds(Map<String, dynamic> payload) {
    final source = _extractSourceMap(payload);
    final candidates = <dynamic>[
      source['serviceIds'],
      source['services'],
      source['selectedServiceIds'],
      source['selectedServices'],
      source['serviceId'],
    ];

    final ids = <int>{};
    for (final candidate in candidates) {
      if (candidate is List) {
        for (final value in candidate) {
          final id = _extractId(value);
          if (id != null) ids.add(id);
        }
      } else {
        final id = _extractId(candidate);
        if (id != null) ids.add(id);
      }
    }
    return ids;
  }

  Set<String> _extractSelectedNames(Map<String, dynamic> payload) {
    final source = _extractSourceMap(payload);
    final candidates = <dynamic>[
      source['services'],
      source['selectedServices'],
      source['serviceNames'],
      source['serviceName'],
    ];

    final names = <String>{};
    for (final candidate in candidates) {
      if (candidate is List) {
        for (final value in candidate) {
          final name = _extractName(value);
          if (name != null) names.add(name.toLowerCase());
        }
      } else {
        final name = _extractName(candidate);
        if (name != null) names.add(name.toLowerCase());
      }
    }
    return names;
  }

  Map<String, dynamic> _extractSourceMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      if (data['partner'] is Map<String, dynamic>) {
        return data['partner'] as Map<String, dynamic>;
      }
      if (data['helper'] is Map<String, dynamic>) {
        return data['helper'] as Map<String, dynamic>;
      }
      return data;
    }
    return payload;
  }

  int? _extractId(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    if (value is Map<String, dynamic>) {
      final nested = value['id'] ?? value['serviceId'];
      return _extractId(nested);
    }
    return null;
  }

  String? _extractName(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is Map<String, dynamic>) {
      final nested = value['name'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }
    return null;
  }

  void _toggleService(_ServiceOption service) {
    if (_saving) return;

    final wasSelected = _selectedServiceIds.contains(service.id);

    setState(() {
      if (wasSelected) {
        _selectedServiceIds.remove(service.id);
      } else {
        _selectedServiceIds.add(service.id);
      }
      // Update hasChanges based on current selection vs initial
      _hasChanges = !setEquals(_selectedServiceIds, _initialSelectedServiceIds);
    });
  }

  Future<void> _saveServices() async {
    if (_saving) return;

    setState(() => _saving = true);

    final repo = ref.read(partnerRepositoryProvider);
    final res = await repo.updatePartnerServices(
      serviceIds: _selectedServiceIds.toList(),
    );

    if (!mounted) return;

    final success = res['success'] == true;
    if (success) {
      // Update initial state to current state
      setState(() {
        _initialSelectedServiceIds = Set<int>.from(_selectedServiceIds);
        _hasChanges = false;
      });
      AppToast.showSuccess('Services saved successfully');
    } else {
      AppToast.showError(
        (res['message'] ?? 'Failed to save services').toString(),
      );
    }

    setState(() => _saving = false);
  }

  List<_ServiceOption> get _visibleServices {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _services;
    return _services.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2239),
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Manage Services',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                height: 1.05,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Add or remove services you offer',
              style: TextStyle(
                color: Color(0xFFD0D5DD),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD0D5DD)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: Color(0xFF98A2B3),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D2939),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search service...',
                              hintStyle: TextStyle(
                                color: Color(0xFF98A2B3),
                                fontSize: 16,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.mic,
                          color: Color(0xFF98A2B3),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Choose Service You Provide',
                    style: TextStyle(
                      color: Color(0xFF1D2939),
                      fontSize: 21,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _visibleServices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final service = _visibleServices[index];
                        final selected = _selectedServiceIds.contains(
                          service.id,
                        );
                        return _ServiceTile(
                          title: service.name,
                          selected: selected,
                          onTap: () => _toggleService(service),
                        );
                      },
                    ),
                  ),
                  // Show save button if there are unsaved changes
                  if (_hasChanges)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveServices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            disabledBackgroundColor: const Color(0xFFA8D5BA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _saving ? 'Saving...' : 'Save Services',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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

class _ServiceOption {
  const _ServiceOption({required this.id, required this.name});

  final int id;
  final String name;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFCBEAF8) : const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFFACACAC),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0EA5E9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF0EA5E9)
                        : const Color(0xFF6B7280),
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
