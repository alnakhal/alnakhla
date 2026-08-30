import 'package:flutter/material.dart';

class CuppingCupsPage extends StatefulWidget {
  final bool showAnimation;

  const CuppingCupsPage({
    Key? key,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  State<CuppingCupsPage> createState() => _CuppingCupsPageState();
}

class _CuppingCupsPageState extends State<CuppingCupsPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  final List<CuppingCupItem> _cups = [
    CuppingCupItem(
      id: 1,
      name: 'كاسات بلاستيكية',
      description: 'كاسات حجامة بلاستيكية عالية الجودة',
      price: '45.00',
      icon: '🩺',
      color: const Color(0xFF4B39EF),
    ),
    CuppingCupItem(
      id: 2,
      name: 'كاسات زجاجية',
      description: 'كاسات حجامة زجاجية تقليدية',
      price: '85.00',
      icon: '🏺',
      color: const Color(0xFF00BFA6),
    ),
    CuppingCupItem(
      id: 3,
      name: 'كاسات مغناطيسية',
      description: 'كاسات حجامة بتقنية مغناطيسية حديثة',
      price: '120.00',
      icon: '⚡',
      color: const Color(0xFFFFA500),
    ),
    CuppingCupItem(
      id: 4,
      name: 'كاسات ألمنيوم',
      description: 'كاسات حجامة من الألمنيوم خفيفة',
      price: '65.00',
      icon: '🎯',
      color: const Color(0xFFE91E63),
    ),
    CuppingCupItem(
      id: 5,
      name: 'مجموعة متكاملة',
      description: 'مجموعة كاملة من جميع أنواع الكاسات',
      price: '250.00',
      icon: '📦',
      color: const Color(0xFF7C4DFF),
    ),
    CuppingCupItem(
      id: 6,
      name: 'كاسات شفط كهربائية',
      description: 'كاسات حجامة بنظام شفط كهربائي',
      price: '180.00',
      icon: '🔌',
      color: const Color(0xFF00BCD4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.showAnimation) {
      _scaleController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      _scaleController.forward();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    if (widget.showAnimation) {
      _scaleController.dispose();
      _fadeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🩺 كاسات الحجامة'),
        centerTitle: true,
        elevation: 0,
      ),
      body: widget.showAnimation
          ? ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
                ),
                child: _buildCupsList(),
              ),
            )
          : _buildCupsList(),
    );
  }

  Widget _buildCupsList() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _cups.length,
      itemBuilder: (context, index) {
        return _buildCupCard(_cups[index]);
      },
    );
  }

  Widget _buildCupCard(CuppingCupItem cup) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة ${cup.name} إلى السلة'),
            backgroundColor: cup.color,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cup.color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // خلفية بتدرج لون
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cup.color.withOpacity(0.1),
                      cup.color.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),

            // المحتوى
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الأيقونة والسعر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cup.color.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            cup.icon,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cup.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${cup.price} ر.س',
                          style: TextStyle(
                            color: cup.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // الاسم
                  Text(
                    cup.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // الوصف
                  Expanded(
                    child: Text(
                      cup.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // زر الإضافة
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✅ تم إضافة ${cup.name}'),
                            backgroundColor: cup.color,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cup.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'أضف',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // نجمة المفضلة
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❤️ تم إضافة ${cup.name} إلى المفضلة'),
                      backgroundColor: Colors.red.shade400,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Color(0xFF4B39EF),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CuppingCupItem {
  final int id;
  final String name;
  final String description;
  final String price;
  final String icon;
  final Color color;

  CuppingCupItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
  });
}
