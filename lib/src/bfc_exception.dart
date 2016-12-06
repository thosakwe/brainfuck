class BfcException implements Exception {
  final int index;
  final String message;
  final List<int> source;
  String meta;

  BfcException(this.index, this.message, this.source, {this.meta});
}
