class PartyInvite {
  final String id, partyId, inviterId, inviteeId, status; final DateTime createdAt; final String? partyTitle, inviterUsername;
  const PartyInvite({required this.id,required this.partyId,required this.inviterId,required this.inviteeId,required this.status,required this.createdAt,this.partyTitle,this.inviterUsername});
  factory PartyInvite.fromMap(Map<String,dynamic> m)=>PartyInvite(id:m['id'],partyId:m['party_id'],inviterId:m['inviter_id'],inviteeId:m['invitee_id'],status:m['status'],createdAt:DateTime.parse(m['created_at']).toUtc(),partyTitle:m['party_title'],inviterUsername:m['inviter_username']);
}
