import 'jobs_models.dart';

const List<String> kServiceTypeFilters = [
  'Service Type',
  'Maid',
  'Cook',
  'Driver',
  'Nanny',
];

const List<String> kDayFilters = ['Day', 'Today', 'Tomorrow', 'This Week'];

const List<UpcomingJobItem> kUpcomingJobs = [
  UpcomingJobItem(
    name: 'Priya Sharma',
    rating: '4.9',
    serviceType: 'Maid',
    schedule: 'Tomorrow • 08:00 AM - 11 AM',
    duration: '3 hours duration',
    address: 'Address, lorem ipsum dolor',
    amount: '₹750',
  ),
  UpcomingJobItem(
    name: 'Anita Desai',
    rating: '4.9',
    serviceType: 'Cook',
    schedule: 'Today • 08:00 AM - 11 AM',
    duration: '6 hours duration',
    address: 'Address, lorem ipsum dolor',
    amount: '₹150',
  ),
  UpcomingJobItem(
    name: 'Priya Sharma',
    rating: '4.9',
    serviceType: 'Driver',
    schedule: 'Tomorrow • 08:00 AM - 11 AM',
    duration: '3 hours duration',
    address: 'Address, lorem ipsum dolor',
    amount: '₹750',
  ),
];
