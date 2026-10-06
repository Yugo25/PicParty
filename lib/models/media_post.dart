class MediaPost {
  final String id, partyId, userId, type;
  final String? localPath, storagePath, caption, username, displayName;
  final DateTime createdAt;
  int likeCount, commentCount;
  bool liked;
  MediaPost({required this.id,required this.partyId,required this.userId,required this.type,this.localPath,this.storagePath,this.caption,this.username,this.displayName,required this.createdAt,this.likeCount=0,this.commentCount=0,this.liked=false});
}
