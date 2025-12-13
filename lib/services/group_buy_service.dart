// lib/services/group_buy_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neon_fire/models/group_buy_model.dart';

class GroupBuyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 캐시
  List<GroupBuyProduct>? _cachedProducts;
  DateTime? _cacheTime;

  /// 캐시 유효성 검사 (1분)
  bool get _isCacheValid {
    if (_cachedProducts == null || _cacheTime == null) {
      return false;
    }
    final now = DateTime.now();
    return now.difference(_cacheTime!) < const Duration(minutes: 1);
  }

  /// 캐시 초기화
  void clearCache() {
    _cachedProducts = null;
    _cacheTime = null;
  }

  /// 모든 활성 공동구매 상품 조회
  Future<List<GroupBuyProduct>> getAllProducts({bool forceRefresh = false}) async {
    try {
      // 캐시 사용
      if (!forceRefresh && _isCacheValid) {
        print('✅ 캐시된 공동구매 상품 사용: ${_cachedProducts!.length}개');
        return _cachedProducts!;
      }

      print('🔄 Firebase에서 공동구매 상품 로드 중...');

      final querySnapshot = await _db
          .collection('group_buy_products')
          .where('isActive', isEqualTo: true)
          .get();

      final products = querySnapshot.docs
          .map((doc) => GroupBuyProduct.fromFirestore(doc))
          .toList();

      // 메모리에서 createdAt으로 정렬
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 캐시 저장
      _cachedProducts = products;
      _cacheTime = DateTime.now();

      print('✅ 공동구매 상품 로드 완료: ${products.length}개');
      return products;
    } catch (e) {
      print('❌ 공동구매 상품 로드 실패: $e');
      // 오류 시 빈 리스트 반환
      return [];
    }
  }

  /// 카테고리별 상품 필터링
  Future<List<GroupBuyProduct>> getProductsByCategory(
    String category, {
    bool forceRefresh = false,
  }) async {
    try {
      if (category == '전체') {
        return await getAllProducts(forceRefresh: forceRefresh);
      }

      // 캐시된 데이터에서 필터링
      if (!forceRefresh && _isCacheValid) {
        return _cachedProducts!
            .where((product) => product.category == category)
            .toList();
      }

      // Firebase에서 직접 쿼리
      final querySnapshot = await _db
          .collection('group_buy_products')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .get();

      final products = querySnapshot.docs
          .map((doc) => GroupBuyProduct.fromFirestore(doc))
          .toList();

      // 메모리에서 createdAt으로 정렬
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return products;
    } catch (e) {
      print('❌ 카테고리별 상품 조회 실패: $e');
      return [];
    }
  }

  /// 특정 상품 조회
  Future<GroupBuyProduct?> getProductById(String productId) async {
    try {
      final doc = await _db
          .collection('group_buy_products')
          .doc(productId)
          .get();

      if (!doc.exists) {
        print('⚠️ 상품을 찾을 수 없습니다: $productId');
        return null;
      }

      return GroupBuyProduct.fromFirestore(doc);
    } catch (e) {
      print('❌ 상품 조회 실패: $e');
      return null;
    }
  }

  /// 새 상품 등록
  Future<String?> createProduct(GroupBuyProduct product) async {
    try {
      final docRef = await _db
          .collection('group_buy_products')
          .add(product.toFirestore());

      print('✅ 공동구매 상품 등록 완료: ${docRef.id}');
      clearCache(); // 캐시 무효화
      return docRef.id;
    } catch (e) {
      print('❌ 상품 등록 실패: $e');
      return null;
    }
  }

  /// 상품 정보 업데이트
  Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      await _db
          .collection('group_buy_products')
          .doc(productId)
          .update(updates);

      print('✅ 상품 정보 업데이트 완료: $productId');
      clearCache(); // 캐시 무효화
      return true;
    } catch (e) {
      print('❌ 상품 업데이트 실패: $e');
      return false;
    }
  }

  /// 공동구매 참여
  Future<bool> joinGroupBuy({
    required String userId,
    required String productId,
  }) async {
    try {
      // 트랜잭션으로 동시성 처리
      return await _db.runTransaction((transaction) async {
        // 1. 상품 정보 조회
        final productRef = _db.collection('group_buy_products').doc(productId);
        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          throw Exception('상품을 찾을 수 없습니다.');
        }

        final product = GroupBuyProduct.fromFirestore(productDoc);

        // 2. 참여 가능 여부 확인
        if (!product.canJoin) {
          throw Exception('참여할 수 없는 상품입니다.');
        }

        // 3. 이미 참여했는지 확인
        final participationQuery = await _db
            .collection('group_buy_participations')
            .where('userId', isEqualTo: userId)
            .where('productId', isEqualTo: productId)
            .where('status', isEqualTo: 'active')
            .get();

        if (participationQuery.docs.isNotEmpty) {
          throw Exception('이미 참여한 공동구매입니다.');
        }

        // 4. 참여 기록 생성
        final participation = GroupBuyParticipation(
          id: '',
          userId: userId,
          productId: productId,
          productName: product.name,
          price: product.discountedPrice,
          joinedAt: DateTime.now(),
          status: ParticipationStatus.active,
        );

        final participationRef = _db.collection('group_buy_participations').doc();
        transaction.set(participationRef, participation.toFirestore());

        // 5. 참여 인원 증가
        transaction.update(productRef, {
          'currentParticipants': FieldValue.increment(1),
        });

        print('✅ 공동구매 참여 완료: $productId');
        clearCache(); // 캐시 무효화
        return true;
      });
    } catch (e) {
      print('❌ 공동구매 참여 실패: $e');
      return false;
    }
  }

  /// 공동구매 참여 취소
  Future<bool> cancelParticipation({
    required String userId,
    required String productId,
  }) async {
    try {
      return await _db.runTransaction((transaction) async {
        // 1. 참여 기록 찾기
        final participationQuery = await _db
            .collection('group_buy_participations')
            .where('userId', isEqualTo: userId)
            .where('productId', isEqualTo: productId)
            .where('status', isEqualTo: 'active')
            .get();

        if (participationQuery.docs.isEmpty) {
          throw Exception('참여 기록을 찾을 수 없습니다.');
        }

        final participationDoc = participationQuery.docs.first;

        // 2. 참여 기록 상태 업데이트
        transaction.update(
          _db.collection('group_buy_participations').doc(participationDoc.id),
          {'status': 'cancelled'},
        );

        // 3. 참여 인원 감소
        final productRef = _db.collection('group_buy_products').doc(productId);
        transaction.update(productRef, {
          'currentParticipants': FieldValue.increment(-1),
        });

        print('✅ 공동구매 참여 취소 완료: $productId');
        clearCache(); // 캐시 무효화
        return true;
      });
    } catch (e) {
      print('❌ 참여 취소 실패: $e');
      return false;
    }
  }

  /// 사용자의 참여 내역 조회
  Future<List<GroupBuyParticipation>> getUserParticipations(String userId) async {
    try {
      print('🔍 사용자 참여 내역 조회 시작: userId=$userId');
      
      final querySnapshot = await _db
          .collection('group_buy_participations')
          .where('userId', isEqualTo: userId)
          .get();

      print('📊 조회된 문서 수: ${querySnapshot.docs.length}');
      
      final participations = querySnapshot.docs
          .map((doc) {
            print('📄 문서 데이터: ${doc.data()}');
            return GroupBuyParticipation.fromFirestore(doc);
          })
          .toList();
      
      // 메모리에서 joinedAt으로 정렬
      participations.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
      
      print('✅ 참여 내역 조회 완료: ${participations.length}개');
      return participations;
    } catch (e) {
      print('❌ 참여 내역 조회 실패: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      return [];
    }
  }

  /// 특정 상품에 사용자가 참여했는지 확인
  Future<bool> hasUserJoined({
    required String userId,
    required String productId,
  }) async {
    try {
      final querySnapshot = await _db
          .collection('group_buy_participations')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ 참여 여부 확인 실패: $e');
      return false;
    }
  }

  /// 상품 삭제 (비활성화)
  Future<bool> deleteProduct(String productId) async {
    try {
      await _db
          .collection('group_buy_products')
          .doc(productId)
          .update({'isActive': false});

      print('✅ 상품 비활성화 완료: $productId');
      clearCache(); // 캐시 무효화
      return true;
    } catch (e) {
      print('❌ 상품 삭제 실패: $e');
      return false;
    }
  }

  /// 목업 데이터 생성 (개발용)
  Future<void> seedMockData() async {
    try {
      print('🌱 공동구매 목업 데이터 생성 중...');

      final mockProducts = [
        GroupBuyProduct(
          id: '',
          name: '덤벨 세트 공동구매 모집',
          description: '도금식 덤벨 세트 20kg',
          sellerId: 'mock_seller_1',
          sellerName: '김철수',
          category: '운동기구',
          originalPrice: 150000,
          discount: 30,
          discountedPrice: 105000,
          currentParticipants: 8,
          maxParticipants: 20,
          imagePath: 'assets/images/product/dumbell.jpg',
          detailedDescription: '이번 조절식 덤벨 세트입니다. 20kg까지 조절 가능하며, 홈트레이닝에 최적화되어 있습니다.',
          createdAt: DateTime.now(),
          isActive: true,
        ),
        GroupBuyProduct(
          id: '',
          name: 'WPC 단백질 보충제 공구',
          description: '마이프로틴 임팩트 웨이 5kg',
          sellerId: 'mock_seller_2',
          sellerName: '이영희',
          category: '단백질',
          originalPrice: 88000,
          discount: 25,
          discountedPrice: 66750,
          currentParticipants: 15,
          maxParticipants: 20,
          imagePath: 'assets/images/product/my_protine.jpg',
          detailedDescription: '마이프로틴 브랜드의 고품질 WPC 단백질 보충제입니다. 5kg 대용량으로 가성비가 뛰어납니다.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isActive: true,
        ),
        GroupBuyProduct(
          id: '',
          name: '요가매트 공동구매',
          description: '프리미엄 NBR 요가매트 10mm',
          sellerId: 'mock_seller_3',
          sellerName: '박민수',
          category: '운동기구',
          originalPrice: 45000,
          discount: 40,
          discountedPrice: 27000,
          currentParticipants: 12,
          maxParticipants: 15,
          imagePath: 'assets/images/product/yoga_mat.jpg',
          detailedDescription: '10mm 두께의 프리미엄 NBR 요가매트입니다. 쿠션감이 좋아 관절 보호에 효과적입니다.',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          isActive: true,
        ),
      ];

      for (final product in mockProducts) {
        await createProduct(product);
      }

      print('✅ 목업 데이터 생성 완료: ${mockProducts.length}개');
    } catch (e) {
      print('❌ 목업 데이터 생성 실패: $e');
    }
  }
}
