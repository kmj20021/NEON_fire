// lib/models/group_buy_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// 공동구매 상품 모델
class GroupBuyProduct {
  final String id;
  final String name;
  final String description;
  final String sellerId;
  final String sellerName;
  final String category;
  final int originalPrice;
  final int discount;
  final int discountedPrice;
  final int currentParticipants;
  final int maxParticipants;
  final String imagePath;
  final String detailedDescription;
  final DateTime createdAt;
  final DateTime? endDate;
  final bool isActive;

  GroupBuyProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.sellerId,
    required this.sellerName,
    required this.category,
    required this.originalPrice,
    required this.discount,
    required this.discountedPrice,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.imagePath,
    required this.detailedDescription,
    required this.createdAt,
    this.endDate,
    required this.isActive,
  });

  /// Firestore 문서에서 모델 생성
  factory GroupBuyProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupBuyProduct(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      category: data['category'] ?? '기타',
      originalPrice: data['originalPrice'] ?? 0,
      discount: data['discount'] ?? 0,
      discountedPrice: data['discountedPrice'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      maxParticipants: data['maxParticipants'] ?? 10,
      imagePath: data['imagePath'] ?? 'assets/images/product/dumbell.jpg',
      detailedDescription: data['detailedDescription'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  /// 모델을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'category': category,
      'originalPrice': originalPrice,
      'discount': discount,
      'discountedPrice': discountedPrice,
      'currentParticipants': currentParticipants,
      'maxParticipants': maxParticipants,
      'imagePath': imagePath,
      'detailedDescription': detailedDescription,
      'createdAt': Timestamp.fromDate(createdAt),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
    };
  }

  /// 참여율 계산
  double get progressRate => currentParticipants / maxParticipants;

  /// 남은 인원 수
  int get remainingParticipants => maxParticipants - currentParticipants;

  /// 참여 가능 여부
  bool get canJoin => isActive && currentParticipants < maxParticipants;

  /// 모집 완료 여부
  bool get isCompleted => currentParticipants >= maxParticipants;

  /// 복사본 생성 (업데이트용)
  GroupBuyProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? sellerId,
    String? sellerName,
    String? category,
    int? originalPrice,
    int? discount,
    int? discountedPrice,
    int? currentParticipants,
    int? maxParticipants,
    String? imagePath,
    String? detailedDescription,
    DateTime? createdAt,
    DateTime? endDate,
    bool? isActive,
  }) {
    return GroupBuyProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discount: discount ?? this.discount,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      imagePath: imagePath ?? this.imagePath,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      createdAt: createdAt ?? this.createdAt,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// 공동구매 참여 기록 모델
class GroupBuyParticipation {
  final String id;
  final String userId;
  final String productId;
  final String productName;
  final int price;
  final DateTime joinedAt;
  final ParticipationStatus status;

  GroupBuyParticipation({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.joinedAt,
    required this.status,
  });

  /// Firestore 문서에서 모델 생성
  factory GroupBuyParticipation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupBuyParticipation(
      id: doc.id,
      userId: data['userId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      price: data['price'] ?? 0,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ParticipationStatus.values.firstWhere(
        (e) => e.toString() == 'ParticipationStatus.${data['status']}',
        orElse: () => ParticipationStatus.active,
      ),
    );
  }

  /// 모델을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'status': status.toString().split('.').last,
    };
  }
}

/// 참여 상태 enum
enum ParticipationStatus {
  active, // 활성
  completed, // 완료
  cancelled, // 취소
}
