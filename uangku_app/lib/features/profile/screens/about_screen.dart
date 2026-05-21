import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Tentang Uangku',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/Logo SplashScreen.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Uangku',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: context.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Versi 2.1.4',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.borderColor),
                boxShadow: context.isDarkMode ? [] : [
                  BoxShadow(
                    color: const Color(0xFFE2E8F0).withOpacity(0.6),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tentang Aplikasi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Uangku adalah asisten keuangan pribadi cerdas yang dirancang khusus untuk mempermudah Anda dalam mencatat transaksi, menyusun anggaran bulanan, dan memberikan saran (insight) otomatis berbasis AI. Kami percaya mengelola uang tidak harus rumit.',
                    style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Project Context Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), AppColors.primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Proyek Tugas Besar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dikembangkan sepenuh hati untuk memenuhi Tugas Besar mata kuliah Aplikasi Perangkat Bergerak (APB).',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), height: 1.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Developers List
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tim Pengembang',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textPrimary),
              ),
            ),
            const SizedBox(height: 16),
            _buildDeveloperTile(context, 'Gilang Wasis Wicaksono', 'Mobile Developer / UI/UX', 'G'),
            _buildDeveloperTile(context, 'Ihab Hasanin Akmal', 'Mobile Developer / Backend', 'I'),
            _buildDeveloperTile(context, 'Farhan Muamar Fawwaz', 'Mobile Developer / QA', 'F'),
            _buildDeveloperTile(context, 'Arina Rahmania Nabila', 'Mobile Developer / PM', 'A'),
            
            const SizedBox(height: 40),
            const Text(
              '© 2026 Uangku Team. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperTile(BuildContext context, String name, String role, String initial) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: context.isDarkMode ? [] : [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0E7FF), Color(0xFFDBEAFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
