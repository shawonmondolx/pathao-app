class TransferRequest {
  final String id;
  final String consignmentId;
  final String recipientName;
  final String recipientPhone;
  final String address;
  final double amount;
  
  TransferRequest({
    required this.id,
    required this.consignmentId,
    required this.recipientName,
    required this.recipientPhone,
    required this.address,
    required this.amount,
  });

  factory TransferRequest.fromJson(Map<String, dynamic> json) {
    return TransferRequest(
      id: json['id']?.toString() ?? '',
      consignmentId: json['consignment_id']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? 'Unknown',
      recipientPhone: json['recipient_phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
    );
  }
}
