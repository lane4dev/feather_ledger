/// Settings for the first pending occurrence and its following occurrences.
class CustomRecurrence {
  const CustomRecurrence(
      {required this.frequency,
      required this.interval,
      required this.startDate,
      required this.weekdays,
      this.endDate,
      this.countLimit});
  final String frequency;
  final int interval;
  final DateTime startDate;
  final List<int> weekdays;
  final DateTime? endDate;
  final int? countLimit;
}
