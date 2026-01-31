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

  String toKiloString() =>
      this < 1000 ? "$this" : "${(this / 1000.0).toStringAsFixed(1)}k";
}

/// 时间扩展
extension DateTimeHelper on DateTime {
  /// 时间转易读的标签
  String get toLabel {
    const minute = 60;
    const hour = 60 * minute;
    const day = 24 * hour;
    // const week = 7 * day;
    const month = 30 * day;
    const year = 12 * month;

    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000 -
        millisecondsSinceEpoch ~/ 1000;

    return switch (seconds) {
      0 => '刚刚',
      < minute => '$seconds秒前',
      < hour => '${seconds ~/ minute}分钟前',
      < day => '${seconds ~/ hour}小时前',
      // < week => '${seconds ~/ week}周前',
      < month => '${seconds ~/ day}天前',
      < year => '${seconds ~/ month}个月前',
      >= year => '${seconds ~/ year}年前',
      _ => "",
    };
  }
}
