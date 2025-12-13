// lib/screens/group_buying/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:neon_fire/models/group_buy_model.dart';
import 'package:neon_fire/services/group_buy_service.dart';
import 'package:intl/intl.dart';

class ProductListScreen extends StatefulWidget {
  final String userId;
  final VoidCallback onBack;
  final Function(String) navigateToPage;

  const ProductListScreen({
    Key? key,
    required this.userId,
    required this.onBack,
    required this.navigateToPage,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final Color primaryColor = const Color(0xFFFF5757);
  final GroupBuyService _service = GroupBuyService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');

  String selectedCategory = '전체';
  final List<String> categories = ['전체', '운동기구', '단백질', '기타'];

  List<GroupBuyProduct> allProducts = [];
  bool isLoading = true;
  Map<String, bool> userParticipations = {}; // productId -> 참여 여부

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 상품 데이터 로드
  Future<void> _loadProducts() async {
    setState(() => isLoading = true);

    try {
      final products = await _service.getAllProducts();

      // 각 상품에 대한 사용자 참여 여부 확인
      final participations = <String, bool>{};
      for (final product in products) {
        final hasJoined = await _service.hasUserJoined(
          userId: widget.userId,
          productId: product.id,
        );
        participations[product.id] = hasJoined;
      }

      if (!mounted) return;
      setState(() {
        allProducts = products;
        userParticipations = participations;
        isLoading = false;
      });
    } catch (e) {
      print('상품 로드 실패: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  /// 필터링된 상품 리스트
  List<GroupBuyProduct> get filteredProducts {
    if (selectedCategory == '전체') {
      return allProducts;
    }
    return allProducts.where((p) => p.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => widget.navigateToPage('내 참여'),
              icon: const Icon(
                Icons.shopping_cart,
                color: Colors.black54,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 32, height: 32),
                const SizedBox(width: 8),
                const Text(
                  '프로해빗',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () => widget.navigateToPage('마이페이지'),
              icon: const Icon(
                Icons.person,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 카테고리 탭
          _buildCategoryTabs(),

          // 검색바
          _buildSearchBar(),

          const SizedBox(height: 16),

          // 상품 리스트
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '등록된 공동구매가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(filteredProducts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text(
              '상품명이나 제목으로 검색하기',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(GroupBuyProduct product) {
    final progress = product.progressRate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showProductDetailDialog(product),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
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
                          child: Icon(Icons.image, color: Colors.grey.shade400),
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
                        // 상품명
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // 상품 설명
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 판매자 정보
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey.shade300,
                              child: Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              product.sellerName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 가격 정보
                        Row(
                          children: [
                            Text(
                              '${_currencyFormat.format(product.originalPrice)}원',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-${product.discount}%',
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_currencyFormat.format(product.discountedPrice)}원',
                              style: TextStyle(
                                fontSize: 15,
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 참여 현황 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${product.currentParticipants}/${product.maxParticipants}명',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 참여하기/참여중 버튼
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: _buildJoinButton(product),
            ),
          ),
        ],
      ),
    );
  }

  // 참여하기/참여중 버튼 빌더
  Widget _buildJoinButton(
    GroupBuyProduct product, {
    bool closeDialogFirst = false,
  }) {
    final hasJoined = userParticipations[product.id] ?? false;

    if (hasJoined) {
      // 참여중 버튼 (초록색)
      return ElevatedButton(
        onPressed: () async {
          // 참여 취소 확인 다이얼로그
          final shouldCancel = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('참여 취소'),
              content: const Text('참여를 취소 하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('아니오'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('예'),
                ),
              ],
            ),
          );

          if (shouldCancel != true) return;

          // 상세 다이얼로그를 먼저 닫기
          if (closeDialogFirst) {
            Navigator.of(context).pop();
          }

          // context를 미리 저장
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          // 참여 취소 처리
          final success = await _service.cancelParticipation(
            userId: widget.userId,
            productId: product.id,
          );

          if (!mounted) return;

          if (success) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('${product.name} 참여 취소 완료'),
                backgroundColor: Colors.grey.shade700,
              ),
            );
            // 데이터 재로드
            _loadProducts();
          } else {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('참여 취소에 실패했습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          '참여중',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      // 참여하기 버튼
      return ElevatedButton(
        onPressed: () async {
          // 상세 다이얼로그를 먼저 닫기
          if (closeDialogFirst) {
            Navigator.of(context).pop();
          }

          // context를 미리 저장
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          // Firebase로 참여하기 로직 처리
          final success = await _service.joinGroupBuy(
            userId: widget.userId,
            productId: product.id,
          );

          if (!mounted) return;

          if (success) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('${product.name} 참여 완료!'),
                backgroundColor: primaryColor,
              ),
            );
            // 데이터 재로드
            _loadProducts();
          } else {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('참여에 실패했습니다.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          '참여하기',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  // 상품 상세 다이얼로그 표시
  void _showProductDetailDialog(GroupBuyProduct product) {
    final remainingParticipants = product.remainingParticipants;
    final progress = product.progressRate;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '덤벨 세트 공동구매 모집',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // 안내 문구
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: Colors.grey.shade50,
                child: Text(
                  '공동구매에 성공 정원을 확인하여 참여할 수 있습니다.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),

              // 상품 이미지
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    product.imagePath,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 상품 정보
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상품명
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 카테고리
                    Text(
                      '운동기구',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 판매자 정보
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade300,
                          child: Icon(
                            Icons.person,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sellerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '공동구매 주최자',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 가격 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '정가',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${_currencyFormat.format(product.originalPrice)}원',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '할인율',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '${product.discount}%',
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '공동구매 가격',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${_currencyFormat.format(product.discountedPrice)}원',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 참여 현황
                    const Text(
                      '참여 현황',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${product.currentParticipants}/${product.maxParticipants}명',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$remainingParticipants명 더 필요합니다',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 상품 설명
                    const Text(
                      '상품 설명',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.detailedDescription.isNotEmpty
                          ? product.detailedDescription
                          : '이번 조절식 덤벨 세트입니다. 20kg까지 조절 가능하며, 홈트레이닝에 최적화되어 있습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 참여하기/참여중 버튼
                    SizedBox(
                      width: double.infinity,
                      child: _buildJoinButton(product, closeDialogFirst: true),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final items = [
      {'id': '운동', 'icon': Icons.fitness_center, 'label': '운동'},
      {'id': '상태확인', 'icon': Icons.assessment, 'label': '상태확인'},
      {'id': '성과확인', 'icon': Icons.bar_chart, 'label': '성과확인'},
      {'id': '공동구매', 'icon': Icons.shopping_bag, 'label': '공동 구매'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isActive = item['id'] == '공동구매';
            return InkWell(
              onTap: () {
                if (item['id'] != '공동구매') {
                  widget.navigateToPage(item['label'] as String);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
