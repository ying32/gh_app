part of '../../repo.dart';

/// 内容视图
class RepoFileContentView extends StatelessWidget {
  const RepoFileContentView(
    this.file, {
    super.key,
    required this.filename,
  });

  final QLBlob file;
  final String filename;

  bool get _canPreview => file.byteSize <= 1024 * 1024 * 1;

  static const _jpegHeader = [0xFF, 0xD8, 0xFF];
  static const tiffHeader1 = [0x49, 0x49, 0x2A];
  static const tiffHeader2 = [0x4D, 0x4D, 0x2A];
  static const tiffHeader3 = [0x4D, 0x4D, 0x00];
  static const pngHeader = [0x89, 0x50, 0x4E, 0x47];
  static const bmpHeader = [0x42, 0x4D];
  static const gifHeader = [0x47, 0x49, 0x46];

  bool _compareBytes(List<int> data1, List<int> data2) {
    final count = math.min(data1.length, data2.length);
    for (int i = 0; i < count; i++) {
      if (data1[i] != data2[i]) return false;
    }
    return true;
  }

  /// 判断file类型
  bool _isImage(List<int> data) {
    return _compareBytes(data, _jpegHeader) ||
        _compareBytes(data, tiffHeader1) ||
        _compareBytes(data, tiffHeader2) ||
        _compareBytes(data, tiffHeader3) ||
        _compareBytes(data, pngHeader) ||
        _compareBytes(data, bmpHeader) ||
        _compareBytes(data, gifHeader);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canPreview) {
      return const Center(child: Text('<...文件太大...>'));
    }
    try {
      if (file.isBinary) {
        return const Center(child: Text('<...还没做预览二进制文件的功能...>'));
        // 解码数据
        // final data = base64Decode(file.content!.replaceAll("\n", ""));
        // if (file.isBinary && _isImage(data)) {
        //   return Image.memory(data);
        // }
      }

      // 这里还要处理编码
      final body = file.text ?? '';

      /// utf8数据  //utf8.decode(data);
      final ext = p.extension(filename).toLowerCase();
      if (ext == ".md" || ext == ".markdown") {
        return MarkdownBlockPlus(body);
      }
      return HighlightViewPlus(body,
          fileName: filename, byteSize: file.byteSize);
    } catch (e) {
      return Text("Error: $e");
    }
  }
}
