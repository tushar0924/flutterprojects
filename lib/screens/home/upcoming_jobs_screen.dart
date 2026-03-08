import 'package:flutter/material.dart';

import 'upcoming_job_detail_screen.dart';

class UpcomingJobsScreen extends StatefulWidget {
  const UpcomingJobsScreen({super.key});

  @override
  State<UpcomingJobsScreen> createState() => _UpcomingJobsScreenState();
}

class _UpcomingJobsScreenState extends State<UpcomingJobsScreen> {
  String _selectedServiceType = 'Service Type';
  String _selectedDay = 'Day';

  static const List<String> _serviceTypes = [
    'Service Type',
    'Maid',
    'Cook',
    'Driver',
    'Nanny',
  ];

  static const List<String> _days = ['Day', 'Today', 'Tomorrow', 'This Week'];

  static const List<_UpcomingJobItem> _jobs = [
    _UpcomingJobItem(
      name: 'Priya Sharma',
      rating: '4.9',
      serviceType: 'Maid',
      schedule: 'Today • 08:00 AM - 11 AM',
      duration: '3 hours duration',
      address: 'Address, lorem ipsum dolor',
      amount: '₹750',
    ),
    _UpcomingJobItem(
      name: 'Anita Desai',
      rating: '4.9',
      serviceType: 'Cook',
      schedule: 'Today • 08:00 AM - 11 AM',
      duration: '6 hours duration',
      address: 'Address, lorem ipsum dolor',
      amount: '₹150',
    ),
    _UpcomingJobItem(
      name: 'Priya Sharma',
      rating: '4.9',
      serviceType: 'Driver',
      schedule: 'Tomorrow • 08:00 AM - 11 AM',
      duration: '3 hours duration',
      address: 'Address, lorem ipsum dolor',
      amount: '₹750',
    ),
    _UpcomingJobItem(
      name: 'Anita Desai',
      rating: '4.9',
      serviceType: 'Nanny',
      schedule: 'Today • 08:00 AM - 11 AM',
      duration: '6 hours duration',
      address: 'Address, lorem ipsum dolor',
      amount: '₹150',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2545),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: const Text(
          'Upcoming Jobs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _FilterDropdown(
                      value: _selectedServiceType,
                      items: _serviceTypes,
                      onChanged: (value) {
                        setState(() => _selectedServiceType = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterDropdown(
                      value: _selectedDay,
                      items: _days,
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
              Expanded(
                child: ListView.separated(
                  itemCount: _jobs.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _JobCard(
                    job: _jobs[index],
                    onViewDetails: () {
                      final _UpcomingJobItem selected = _jobs[index];
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UpcomingJobDetailScreen(
                            customerName: selected.name,
                            rating: selected.rating,
                            serviceType: selected.serviceType,
                            earnings: selected.amount,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
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
              fontSize: 24,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 11,
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

  final _UpcomingJobItem job;
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
          _detailRow(Icons.calendar_today_outlined, job.schedule),
          _detailRow(Icons.access_time_outlined, job.duration),
          _detailRow(Icons.location_on_outlined, job.address),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job.amount,
                style: const TextStyle(
                  color: Color(0xFF0EA5E9),
                  fontSize: 23,
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

  Widget _detailRow(IconData icon, String value) {
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

class _UpcomingJobItem {
  const _UpcomingJobItem({
    required this.name,
    required this.rating,
    required this.serviceType,
    required this.schedule,
    required this.duration,
    required this.address,
    required this.amount,
  });

  final String name;
  final String rating;
  final String serviceType;
  final String schedule;
  final String duration;
  final String address;
  final String amount;
}
