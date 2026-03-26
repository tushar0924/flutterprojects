import 'package:flutter/material.dart';

import '../earnings_models.dart';

class EarningsPeriodTabs extends StatelessWidget {
  const EarningsPeriodTabs({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  final EarningsPeriod selectedPeriod;
  final ValueChanged<EarningsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: EarningsPeriod.values.map((period) {
        final bool isSelected = period == selectedPeriod;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: period == EarningsPeriod.thisMonth ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFF173F63),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFE4E7EC)
                        : const Color(0xFF335A7D),
                  ),
                ),
                child: Center(
                  child: Text(
                    period.tabLabel,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
