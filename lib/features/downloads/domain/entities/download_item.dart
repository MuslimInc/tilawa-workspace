import 'package:equatable/equatable.dart';

class DownloadItem extends Equatable {
  const DownloadItem({
    required this.id,
    required this.title,
    required this.url,
    required this.filePath,
    required this.reciterName,
    required this.status,
    required this.progress,
    required this.fileSize,
    required this.downloadedSize,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String url;
  final String filePath;
  final String reciterName;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int fileSize; // in bytes
  final int downloadedSize; // in bytes
  final DateTime createdAt;
  final DateTime? completedAt;

  @override
  List<Object?> get props => [
    id,
    title,
    url,
    filePath,
    reciterName,
    status,
    progress,
    fileSize,
    downloadedSize,
    createdAt,
    completedAt,
  ];

  DownloadItem copyWith({
    String? id,
    String? title,
    String? url,
    String? filePath,
    String? reciterName,
    DownloadStatus? status,
    double? progress,
    int? fileSize,
    int? downloadedSize,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      reciterName: reciterName ?? this.reciterName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      fileSize: fileSize ?? this.fileSize,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'filePath': filePath,
      'reciterName': reciterName,
      'status': status.name,
      'progress': progress,
      'fileSize': fileSize,
      'downloadedSize': downloadedSize,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      filePath: json['filePath'] as String,
      reciterName: json['reciterName'] as String,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.pending,
      ),
      progress: (json['progress'] as num).toDouble(),
      fileSize: json['fileSize'] as int,
      downloadedSize: json['downloadedSize'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
  cancelled,
}
