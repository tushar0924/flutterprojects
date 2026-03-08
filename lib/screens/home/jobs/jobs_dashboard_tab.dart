import 'package:flutter/material.dart';

import '../upcoming_job_detail_screen.dart';
import 'jobs_data.dart';
import 'jobs_models.dart';

class JobsDashboardTab extends StatefulWidget {
  const JobsDashboardTab({super.key});

  @override
  State<JobsDashboardTab> createState() => _JobsDashboardTabState();
}

class _JobsDashboardTabState extends State<JobsDashboardTab> {
  String _selectedServiceType = kServiceTypeFilters.first;
  String _selectedDay = kDayFilters.first;

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
              color: const Color(0xFF0B2545),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.business_center_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Upcoming Jobs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _FilterDropdown(
                            value: _selectedServiceType,
                            items: kServiceTypeFilters,
                            onChanged: (value) {
                              setState(() => _selectedServiceType = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterDropdown(
                            value: _selectedDay,
                            items: kDayFilters,
                            onChanged: (value) {
                              setState(() => _selectedDay = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Expanded(
                          child: _StatBox(
                            title: '03',
                            subtitle: 'Available Today',
                            backgroundColor: Color(0xFFEAF3FF),
                            borderColor: Color(0xFFBBD8FF),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _StatBox(
                            title: '12',
                            subtitle: 'Total Jobs Available',
                            backgroundColor: Color(0xFFEAF9E9),
                            borderColor: Color(0xFFB7E6B4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      itemCount: kUpcomingJobs.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final UpcomingJobItem job = kUpcomingJobs[index];
                        return _JobCard(
                          job: job,
                          onViewDetails: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UpcomingJobDetailScreen(
                                  customerName: job.name,
                                  rating: job.rating,
                                  serviceType: job.serviceType,
                                  earnings: job.amount,
                                ),
                              ),
                            );
                          },
                        );
                      },
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Color(0xFF98A2B3),
          ),
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475467),
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 32,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onViewDetails});

  final UpcomingJobItem job;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF0B2545),
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.name,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 11,
                          color: Color(0xFFFDB022),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          job.rating,
                          style: const TextStyle(
                            color: Color(0xFF475467),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.serviceType,
                  style: const TextStyle(
                    color: Color(0xFF0B2545),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailRow(icon: Icons.calendar_today_outlined, value: job.schedule),
          _DetailRow(icon: Icons.access_time_outlined, value: job.duration),
          _DetailRow(icon: Icons.location_on_outlined, value: job.address),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.amount,
                style: const TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontSize: 35,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
              SizedBox(
                height: 30,
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF1D2939),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF344054)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF475467),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
