class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String status;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.status = 'active',
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'logo_url': logoUrl,
        'status': status,
      };
}
