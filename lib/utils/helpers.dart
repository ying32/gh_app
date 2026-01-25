/// 1KB Kilobyte
const k1KB = 1024;

/// 1MB Megabyte
const k1MB = k1KB * 1024;

/// kGB Gigabyte
const k1GB = k1MB * 1024;

/// 1TB Terabyte
const k1TB = k1GB * 1024;

/// 1PB Petabyte
const k1PB = k1TB * 1024;

/// int扩展，直接
extension IntHelper on int {
  String _toSizeString(double value, int fDigits) {
    final v = value.truncate();
    if (value - v == 0.0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(fDigits);
  }

  /// 将一个整数转为更为可读的，比如 1KB 1MB 1GB
  String toSizeString([int fDigits = 2]) => switch (this) {
        < k1KB => '${this}B',
        >= k1KB && < k1MB => "${_toSizeString(this / k1KB, fDigits)}KB",
        >= k1MB && < k1GB => "${_toSizeString(this / k1MB, fDigits)}MB",
        >= k1GB && < k1TB => "${_toSizeString(this / k1GB, fDigits)}GB",
        >= k1TB && < k1PB => "${_toSizeString(this / k1GB, fDigits)}TB",
        >= k1PB => "${_toSizeString(this / k1GB, fDigits)}PB",
        _ => '',
      };
}
