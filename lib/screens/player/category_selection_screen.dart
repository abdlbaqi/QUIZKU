// lib/screens/player/category_selection_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'quiz_screen.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  final List<Map<String, dynamic>> categories = const [
    {
      'name': 'Matematika',
      'image': 'assets/matematika.png',
      'icon': Icons.calculate_rounded,
      'color': Color(0xFF5C6BC0),
      'gradient': [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
      'categoryId': 'matematika',
    },
    {
      'name': 'Hewan',
      'image': 'assets/hewann.png',
      'icon': Icons.pets_rounded,
      'color': Color(0xFF26A69A),
      'gradient': [Color(0xFF26A69A), Color(0xFF00897B)],
      'categoryId': 'hewan',
    },
    {
      'name': 'Olahraga',
      'image': 'assets/olahraga.png',
      'icon': Icons.sports_soccer_rounded,
      'color': Color(0xFF42A5F5),
      'gradient': [Color(0xFF42A5F5), Color(0xFF1E88E5)],
      'categoryId': 'olahraga',
    },
    {
      'name': 'Pengetahuan Umum',
      'image': 'assets/umum.png',
      'icon': Icons.school_rounded,
      'color': Color(0xFF66BB6A),
      'gradient': [Color(0xFF66BB6A), Color(0xFF43A047)],
      'categoryId': 'umum',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isLandscape = size.width > size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(
            left: isTablet ? 16 : 12,
            top: 8,
            bottom: 8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32.0 : 20.0,
                      vertical: isLandscape ? 12.0 : 16.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isLandscape ? 8 : 16),
                        
                        // Header dengan glassmorphism
                        _buildHeader(context, isTablet, isLandscape),
                        
                        SizedBox(height: isLandscape ? 16 : 24),
                        
                        // Grid Kategori dengan glassmorphism
                        _buildCategoryGrid(
                          context,
                          isTablet,
                          isLandscape,
                        ),

                        SizedBox(height: isLandscape ? 12 : 16),

                        // Footer
                        _buildFooter(isTablet, isLandscape),
                        
                        SizedBox(height: isLandscape ? 8 : 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet, bool isLandscape) {
    final verticalPadding = isLandscape ? 16.0 : (isTablet ? 28.0 : 24.0);
    final horizontalPadding = isTablet ? 32.0 : 24.0;
    final titleSize = isTablet ? 36.0 : (isLandscape ? 24.0 : 28.0);
    final subtitleSize = isTablet ? 17.0 : (isLandscape ? 14.0 : 15.0);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Kategori',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: titleSize,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLandscape ? 6 : 8),
              Container(
                height: 4,
                width: isTablet ? 70 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00D4FF),
                      Color(0xFF0091EA),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isLandscape ? 8 : 10),
              Text(
                'Ayo Mulaii!',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    bool isTablet,
    bool isLandscape,
  ) {
    final crossAxisCount = isLandscape
        ? (isTablet ? 4 : 3)
        : (isTablet ? 3 : 2);
    
    final spacing = isTablet ? 20.0 : 16.0;
    final childAspectRatio = isLandscape 
        ? 1.15
        : (isTablet ? 1.05 : 1.0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _buildCategoryCard(context, cat, index, isTablet, isLandscape);
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> cat,
    int index,
    bool isTablet,
    bool isLandscape,
  ) {
    final borderRadius = isTablet ? 28.0 : 24.0;
    final imageSize = isTablet ? 75.0 : (isLandscape ? 50.0 : 60.0);
    final fontSize = isTablet ? 15.0 : (isLandscape ? 11.0 : 13.0);

    return Hero(
      tag: 'cat_${cat['categoryId']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (_, __, ___) => QuizScreen(categoryId: cat['categoryId']),
                transitionsBuilder: (_, animation, __, child) {
                  var curve = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
                  return FadeTransition(
                    opacity: curve,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(curve),
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: cat['color'].withOpacity(0.35),
                  blurRadius: isTablet ? 25 : 20,
                  offset: Offset(0, isTablet ? 12 : 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Stack(
                  children: [
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cat['gradient'][0].withOpacity(0.25),
                              cat['gradient'][1].withOpacity(0.08),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Decorative circles
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: isTablet ? 120 : 100,
                        height: isTablet ? 120 : 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              cat['color'].withOpacity(0.25),
                              cat['color'].withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Content - CENTERED
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16.0 : 12.0,
                          vertical: isTablet ? 18.0 : 14.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Image container dengan glassmorphism
                            Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cat['gradient'][0],
                                    cat['gradient'][1],
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: cat['color'].withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    cat['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      cat['icon'],
                                      size: imageSize * 0.45,
                                      color: cat['color'],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isLandscape ? 6 : 8),
                            
                            // Category name - CENTERED dengan batasan lebar
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 120,
                              ),
                              child: Text(
                                cat['name'],
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.4),
                                      offset: const Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            SizedBox(height: isLandscape ? 5 : 7),
                            
                            // Play button - CENTERED
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 14 : (isLandscape ? 10 : 12),
                                vertical: isTablet ? 7 : (isLandscape ? 5 : 6),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: isTablet ? 16 : (isLandscape ? 12 : 14),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Mulai',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 12 : (isLandscape ? 9 : 10),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isTablet, bool isLandscape) {
    final fontSize = isTablet ? 14.0 : (isLandscape ? 11.0 : 13.0);

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 16 : (isLandscape ? 10 : 14),
        horizontal: isTablet ? 24 : 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.06),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: Colors.white.withOpacity(0.6),
                size: isTablet ? 18 : (isLandscape ? 14 : 16),
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Flexible(
                child: Text(
                  'Ketuk kategori untuk memulai',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}