import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final _api = ApiClient.instance;

  Future<List<NotificationModel>> getNotifications() async {
    final data = await _api.get('/notifications/');
    final results = (data is Map<String, dynamic>) ? data['results'] as List<dynamic> : data as List<dynamic>;
    return results.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String id) async {
    await _api.post('/notifications/$id/mark_read/');
  }

  Future<void> markAllRead() async {
    await _api.post('/notifications/mark_all_read/');
  }
}
