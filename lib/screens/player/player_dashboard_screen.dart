// lib/screens/player/player_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import 'category_selection_screen.dart';

class PlayerDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PlayerDashboardScreen({super.key, required this.userData});

  @override
  State<PlayerDashboardScreen> createState() => _PlayerDashboardScreenState();
}

class _PlayerDashboardScreenState extends State<PlayerDashboardScreen> {
  late Map<String, dynamic> _currentUserData;

  @override
  void initState() {
    super.initState();
    _currentUserData = Map.from(widget.userData);
    _refreshUserData();
  }

  // Refresh data dari Firestore
  Future<void> _refreshUserData() async {
    final userId = FirebaseService.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _currentUserData = userDoc.data() ?? _currentUserData;
        });
      }
    } catch (e) {
      // Silently fail, keep using current data
      debugPrint('Error refreshing user data: $e');
    }
  }

  // Navigasi ke category selection dan refresh saat kembali
  Future<void> _navigateToQuiz() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CategorySelectionScreen(),
      ),
    );
    
    // Refresh data setelah kembali dari quiz
    await _refreshUserData();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isLandscape = size.width > size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshUserData,
            color: const Color(0xFFAB47BC),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32.0 : 24.0,
                  vertical: isLandscape ? 16.0 : 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header dengan profil
                    _buildHeader(isTablet, isLandscape),
                    
                    SizedBox(height: isLandscape ? 24 : 32),
                    
                    // Tombol Mulai Kuis (Main Card)
                    _buildMainQuizCard(context, isTablet, isLandscape),
                    
                    SizedBox(height: isLandscape ? 20 : 28),
                    
                    // Stats Cards
                    _buildStatsCards(isTablet, isLandscape),
                    
                    SizedBox(height: isLandscape ? 40 : 60),
                    
                    // Footer
                    _buildFooter(isTablet, isLandscape),
                    
                    // ignore: prefer_const_constructors
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isLandscape) {
    final titleSize = isTablet ? 24.0 : (isLandscape ? 18.0 : 20.0);
    final nameSize = isTablet ? 34.0 : (isLandscape ? 26.0 : 30.0);
    final avatarRadius = isTablet ? 32.0 : (isLandscape ? 26.0 : 28.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: titleSize,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: isLandscape ? 4 : 6),
              Text(
                _currentUserData['username'] ?? 'Pemain',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: nameSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Avatar dengan glassmorphism
        PopupMenuButton<String>(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: const Color(0xFF1A1A2E),
          elevation: 20,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.white,
                    backgroundImage: const AssetImage('assets/frame.png'),
                    onBackgroundImageError: (_, __) {},
                    child: _currentUserData['photoURL'] == null
                        ? Icon(
                            Icons.person,
                            size: avatarRadius,
                            color: Colors.grey.shade400,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await FirebaseService.logout();
              if (mounted && context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'logout',
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainQuizCard(BuildContext context, bool isTablet, bool isLandscape) {
    final imageSize = isTablet ? 120.0 : (isLandscape ? 80.0 : 100.0);
    final titleSize = isTablet ? 28.0 : (isLandscape ? 20.0 : 24.0);
    final subtitleSize = isTablet ? 17.0 : (isLandscape ? 14.0 : 16.0);
    final verticalPadding = isLandscape ? 30.0 : (isTablet ? 50.0 : 40.0);

    return GestureDetector(
      onTap: _navigateToQuiz,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: isTablet ? 32.0 : 24.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFAB47BC).withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon/Image dengan gradient border
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFAB47BC),
                        Color(0xFFEC407A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFAB47BC).withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/frame.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.quiz_rounded,
                            size: imageSize * 0.5,
                            color: const Color(0xFFAB47BC),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: isLandscape ? 16 : 20),
                
                Text(
                  'Mulai Kuis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: isLandscape ? 8 : 12),
                
                Text(
                  'Pilih kategori untuk memulai kuis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: isLandscape ? 12 : 16),
                
                // Arrow indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: isTablet ? 28 : 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(bool isTablet, bool isLandscape) {
    final fontSize = isTablet ? 22.0 : (isLandscape ? 16.0 : 20.0);
    final iconSize = isTablet ? 40.0 : (isLandscape ? 32.0 : 36.0);
    final padding = isLandscape ? 16.0 : (isTablet ? 24.0 : 20.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Star icon dengan gradient
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFC107),
                      Color(0xFFFF8F00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC107).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
              
              SizedBox(width: isTablet ? 16 : 12),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skor Tertinggi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isTablet ? 15.0 : (isLandscape ? 12.0 : 14.0),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentUserData['skorTertinggi'] ?? 0}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isTablet, bool isLandscape) {
    // ignore: unused_local_variable
    final fontSize = isTablet ? 15.0 : (isLandscape ? 12.0 : 14.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 1,
          width: isTablet ? 200 : 150,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // const SizedBox(height: 16),
        // Text(
        //   'Quiz App by YourName',
        //   style: TextStyle(
        //     color: Colors.white.withOpacity(0.4),
        //     fontSize: fontSize,
        //     fontWeight: FontWeight.w400,
        //     letterSpacing: 0.5,
        //   ),
        // ),
      ],
    );
  }
}