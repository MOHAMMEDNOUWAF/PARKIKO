/// Deck Model for Site Layout & Bay Distribution
class DeckModel {
  final String id;
  final String name;
  final int total;
  final String range;
  final int standardBays;
  final int vipBays;
  final int evBays;

  const DeckModel({
    required this.id,
    required this.name,
    required this.total,
    required this.range,
    required this.standardBays,
    required this.vipBays,
    required this.evBays,
  });

  DeckModel copyWith({
    String? id,
    String? name,
    int? total,
    String? range,
    int? standardBays,
    int? vipBays,
    int? evBays,
  }) {
    return DeckModel(
      id: id ?? this.id,
      name: name ?? this.name,
      total: total ?? this.total,
      range: range ?? this.range,
      standardBays: standardBays ?? this.standardBays,
      vipBays: vipBays ?? this.vipBays,
      evBays: evBays ?? this.evBays,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'total': total,
    'range': range,
    'standardBays': standardBays,
    'vipBays': vipBays,
    'evBays': evBays,
  };

  factory DeckModel.fromMap(Map<String, dynamic> map) {
    return DeckModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      total: (map['total'] as num?)?.toInt() ?? 0,
      range: map['range']?.toString() ?? '',
      standardBays: (map['standardBays'] as num?)?.toInt() ?? 0,
      vipBays: (map['vipBays'] as num?)?.toInt() ?? 0,
      evBays: (map['evBays'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Comprehensive Site Model for Multi-Site Valet Network
class SiteModel {
  final String id;
  final String name;
  final String address;
  final int totalBays;
  final double baseFee;
  final double vipFee;
  final double overnightFee;
  final List<DeckModel> decks;
  final String status; // 'active', 'inactive'
  final DateTime createdAt;

  const SiteModel({
    required this.id,
    required this.name,
    required this.address,
    required this.totalBays,
    this.baseFee = 150.0,
    this.vipFee = 300.0,
    this.overnightFee = 500.0,
    this.decks = const [],
    this.status = 'active',
    required this.createdAt,
  });

  int get totalAllocatedBays => decks.fold<int>(0, (sum, d) => sum + d.total);
  int get deckCount => decks.length;

  SiteModel copyWith({
    String? id,
    String? name,
    String? address,
    int? totalBays,
    double? baseFee,
    double? vipFee,
    double? overnightFee,
    List<DeckModel>? decks,
    String? status,
    DateTime? createdAt,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      totalBays: totalBays ?? this.totalBays,
      baseFee: baseFee ?? this.baseFee,
      vipFee: vipFee ?? this.vipFee,
      overnightFee: overnightFee ?? this.overnightFee,
      decks: decks ?? this.decks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'totalBays': totalBays,
    'baseFee': baseFee,
    'vipFee': vipFee,
    'overnightFee': overnightFee,
    'decks': decks.map((d) => d.toMap()).toList(),
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SiteModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final rawDecks = map['decks'];
    List<DeckModel> parsedDecks = [];
    if (rawDecks is List) {
      parsedDecks = rawDecks
          .whereType<Map>()
          .map((d) => DeckModel.fromMap(Map<String, dynamic>.from(d)))
          .toList();
    }

    DateTime created;
    final rawDate = map['createdAt'];
    if (rawDate is String) {
      created = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    return SiteModel(
      id: (map['id'] ?? docId)?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      totalBays: (map['totalBays'] as num?)?.toInt() ?? 0,
      baseFee: (map['baseFee'] as num?)?.toDouble() ?? 150.0,
      vipFee: (map['vipFee'] as num?)?.toDouble() ?? 300.0,
      overnightFee: (map['overnightFee'] as num?)?.toDouble() ?? 500.0,
      decks: parsedDecks,
      status: map['status']?.toString() ?? 'active',
      createdAt: created,
    );
  }
}
