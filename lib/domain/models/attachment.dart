class Attachment {
  const Attachment({
    required this.url,
    required this.name,
    required this.mime,
    this.sizeBytes = 0,
    this.durationMs,
  });

  final String url;
  final String name;
  final String mime;
  final int sizeBytes;
  final int? durationMs;

  bool get isImage => mime.startsWith('image/');
  bool get isAudio => mime.startsWith('audio/');

  String get readableSize {
    if (sizeBytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = sizeBytes.toDouble();
    var i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${units[i]}';
  }

  Map<String, dynamic> toMap() => {
        'url': url,
        'name': name,
        'mime': mime,
        'sizeBytes': sizeBytes,
        'durationMs': durationMs,
      };

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        url: map['url'] as String? ?? '',
        name: map['name'] as String? ?? '',
        mime: map['mime'] as String? ?? 'application/octet-stream',
        sizeBytes: map['sizeBytes'] as int? ?? 0,
        durationMs: map['durationMs'] as int?,
      );
}
