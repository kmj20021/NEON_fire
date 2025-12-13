// lib/screens/group_buying/my_participation.dart
import 'package:flutter/material.dart';
import 'package:neon_fire/models/group_buy_model.dart';
import 'package:neon_fire/services/group_buy_service.dart';
import 'package:intl/intl.dart';

class MyParticipationScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBack;
  final Function(String) navigateToPage;

  const MyParticipationScreen({
    Key? key,
    required this.userId,
    required this.onBack,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  State<MyParticipationScreen> createState() => _MyParticipationScreenState();
}

class _MyParticipationScreenState extends State<MyParticipationScreen> {
  final Color primaryColor = const Color(0xFFFF5757);
  final GroupBuyService _service = GroupBuyService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');

  List<GroupBuyParticipation> participations = [];
  Map<String, GroupBuyProduct> products = {}; // productId -> product
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParticipations();
  }

  Future<void> _loadParticipations() async {
    setState(() => isLoading = true);

    try {
      print('🔄 참여 내역 로드 시작: userId=${widget.userId}');
      
      // 사용자의 참여 내역 가져오기
      final allParticipations = await _service.getUserParticipations(widget.userId);
      print('📊 전체 참여 내역: ${allParticipations.length}개');
      
      // 참여중인 것만 필터링
      final activeParticipations = allParticipations
          .where((p) {
            print('  - 참여 상태: productId=${p.productId}, status=${p.status}');
            return p.status == ParticipationStatus.active;
          })
          .toList();
      print('✅ 활성 참여 내역: ${activeParticipations.length}개');

      // 각 참여 내역의 상품 정보 가져오기
      final productMap = <String, GroupBuyProduct>{};
      for (final participation in activeParticipations) {
        print('🔍 상품 정보 조회: ${participation.productId}');
        final product = await _service.getProductById(participation.productId);
        if (product != null) {
          print('  ✅ 상품 찾음: ${product.name}');
          productMap[participation.productId] = product;
        } else {
          print('  ⚠️ 상품을 찾을 수 없음: ${participation.productId}');
        }
      }

      print('🎯 최종 표시할 상품 수: ${productMap.length}개');
      
      if (!mounted) return;
      setState(() {
        participations = activeParticipations;
        products = productMap;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 참여 내역 로드 실패: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: widget.onBack,
        ),
        title: const Text(
          '참여중인 공동구매',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => widget.navigateToPage('마이페이지'),
            icon: const Icon(
              Icons.person,
              color: Colors.black54,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : participations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadParticipations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: participations.length,
                    itemBuilder: (context, index) {
                      final participation = participations[index];
                      final product = products[participation.productId];
                      
                      if (product == null) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildParticipationCard(participation, product);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '참여중인 공동구매가 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '공동구매에 참여해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.navigateToPage('공동 구매'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '공동구매 둘러보기',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipationCard(
    GroupBuyParticipation participation,
    GroupBuyProduct product,
  ) {
    final progress = product.progressRate;
    final daysAgo = DateTime.now().difference(participation.joinedAt).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 정보
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    product.imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 상품 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 상품명
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 가격
                      Text(
                        '${_currencyFormat.format(product.discountedPrice)}원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 참여 현황 바
            Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${daysAgo}일 전 참여',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      '${product.currentParticipants}/${product.maxParticipants}명',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // 상태 표시
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '참여중',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
