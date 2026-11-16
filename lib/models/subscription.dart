class Subscription {
  final String id;
  String name;
  String url;
  DateTime? updatedAt;
  int serverCount;

  Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.updatedAt,
    this.serverCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'updatedAt': updatedAt?.toIso8601String(),
        'serverCount': serverCount,
      };

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Subscription',
        url: j['url'] as String? ?? '',
        updatedAt: j['updatedAt'] != null ? DateTime.tryParse(j['updatedAt']) : null,
        serverCount: (j['serverCount'] as num?)?.toInt() ?? 0,
      );
}
