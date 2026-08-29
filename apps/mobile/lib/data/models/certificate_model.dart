class CertificateModel {
  final String id;
  final String certificateNumber;
  final String organizationId;
  final String? organizationName;
  final String? organizationLogo;
  final String recipientName;
  final String recipientEmail;
  final String title;
  final String description;
  final String issueDate;
  final String? expiryDate;
  final String s3ObjectKey;
  final String documentHash;
  final String status;
  final String? txHash;
  final int? blockNumber;
  final String? contractAddress;
  final int chainId;
  final String? fileUrl;
  final String? claimUrl;

  CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.organizationId,
    this.organizationName,
    this.organizationLogo,
    required this.recipientName,
    required this.recipientEmail,
    required this.title,
    required this.description,
    required this.issueDate,
    this.expiryDate,
    required this.s3ObjectKey,
    required this.documentHash,
    required this.status,
    this.txHash,
    this.blockNumber,
    this.contractAddress,
    this.chainId = 80002,
    this.fileUrl,
    this.claimUrl,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    final org = json['organizations'];
    return CertificateModel(
      id: json['id'] ?? '',
      certificateNumber: json['certificate_number'] ?? '',
      organizationId: json['organization_id'] ?? '',
      organizationName: org != null ? org['name'] : json['organization_name'],
      organizationLogo: org != null ? org['logo_url'] : json['organization_logo'],
      recipientName: json['recipient_name'] ?? '',
      recipientEmail: json['recipient_email'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      issueDate: json['issue_date'] ?? '',
      expiryDate: json['expiry_date'],
      s3ObjectKey: json['s3_object_key'] ?? '',
      documentHash: json['document_hash'] ?? '',
      status: json['status'] ?? 'ISSUED',
      txHash: json['tx_hash'],
      blockNumber: json['block_number'] != null ? int.tryParse(json['block_number'].toString()) : null,
      contractAddress: json['contract_address'],
      chainId: json['chain_id'] ?? 80002,
      fileUrl: json['fileUrl'] ?? json['file_url'],
      claimUrl: json['claimUrl'] ?? json['claim_url'],
    );
  }

  bool get isClaimed => status.toUpperCase() == 'CLAIMED' || status.toUpperCase() == 'ISSUED';
  bool get isRevoked => status.toUpperCase() == 'REVOKED';
}
