class AppNotification {
  final String id; final String type; final String? title; final String? body; final String? partyId; final String? mediaId; final String? conversationId; final bool isRead; final DateTime createdAt;
  const AppNotification({required this.id,required this.type,this.title,this.body,this.partyId,this.mediaId,this.conversationId,required this.isRead,required this.createdAt});
  factory AppNotification.fromMap(Map<String,dynamic> m)=>AppNotification(id:m['id'],type:m['type'],title:m['title'],body:m['body'],partyId:m['party_id'],mediaId:m['media_id'],conversationId:m['conversation_id'],isRead:m['is_read']??false,createdAt:DateTime.parse(m['created_at']).toUtc());
}
