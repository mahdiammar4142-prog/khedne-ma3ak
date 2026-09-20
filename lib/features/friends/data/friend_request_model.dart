import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequestModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String? fromDisplayName;
  final String? fromEmail;
  final String? toDisplayName;
  final String? toEmail;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendRequestModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.fromDisplayName,
    this.fromEmail,
    this.toDisplayName,
    this.toEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequestModel(
      id: id,
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      fromDisplayName: map['fromDisplayName'] as String?,
      fromEmail: map['fromEmail'] as String?,
      toDisplayName: map['toDisplayName'] as String?,
      toEmail: map['toEmail'] as String?,
      status: _statusFromString(map['status'] as String?),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromDisplayName': fromDisplayName,
        'fromEmail': fromEmail,
        'toDisplayName': toDisplayName,
        'toEmail': toEmail,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static FriendRequestStatus _statusFromString(String? value) {
    return FriendRequestStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => FriendRequestStatus.pending,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}

