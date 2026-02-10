class ProfitTable {
  /// X-axis: dates as ISO strings (e.g. "2024-03-15")
  final List<String> xAxis;

  /// Y-axis: stock prices
  final List<double> yAxis;

  /// Data keyed by "date:price" → profit/loss value
  final Map<String, double> data;

  ProfitTable({
    required this.xAxis,
    required this.yAxis,
    Map<String, double>? data,
  }) : data = data ?? {};

  static String generateKey(String date, double price) => '$date:$price';

  static ({String date, double price}) parseKey(String key) {
    final parts = key.split(':');
    return (date: parts[0], price: double.parse(parts[1]));
  }

  double? getValue(String date, double price) => data[generateKey(date, price)];

  double get maxValue =>
      data.values.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b);

  double get minValue =>
      data.values.isEmpty ? 0 : data.values.reduce((a, b) => a < b ? a : b);
}
