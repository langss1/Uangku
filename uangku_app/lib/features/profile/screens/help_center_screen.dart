import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isIndo ? 'Pusat Bantuan' : 'Help Center',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIndo ? 'FAQ & Solusi Cepat' : 'FAQ & Quick Solutions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              isIndo ? 'Temukan jawaban untuk pertanyaan umum seputar aplikasi Uangku.' : 'Find answers to frequently asked questions about the Uangku app.',
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
            const SizedBox(height: 24),
            
            _buildFaqItem(
              context: context,
              question: isIndo ? 'Bagaimana cara menambah pengeluaran baru?' : 'How to add a new expense?',
              answer: isIndo ? 'Anda dapat menekan tombol tambah (+) berwarna biru di menu navigasi bawah pada layar utama, kemudian pilih tipe transaksi dan masukkan nominal serta kategori.' : 'You can press the blue add (+) button in the bottom navigation menu on the main screen, then select the transaction type and enter the amount and category.',
            ),
            _buildFaqItem(
              context: context,
              question: isIndo ? 'Apakah Uangku menyimpan data di cloud?' : 'Does Uangku store data in the cloud?',
              answer: isIndo ? 'Saat ini, Uangku menyimpan data secara aman. Jika Anda mengaktifkan sinkronisasi akun, data akan dicadangkan ke server untuk memudahkan akses dari perangkat lain.' : 'Currently, Uangku stores data securely. If you enable account synchronization, data will be backed up to the server for easy access from other devices.',
            ),
            _buildFaqItem(
              context: context,
              question: isIndo ? 'Bagaimana cara kerja Wawasan AI (AI Insights)?' : 'How does AI Insights work?',
              answer: isIndo ? 'Fitur Wawasan AI menggunakan model analisis cerdas untuk mempelajari pola pengeluaran Anda dan memberikan saran keuangan personal untuk membantu Anda berhemat.' : 'The AI Insights feature uses smart analysis models to learn your spending patterns and provide personalized financial advice to help you save.',
            ),
            _buildFaqItem(
              context: context,
              question: isIndo ? 'Saya lupa password, apa yang harus dilakukan?' : 'I forgot my password, what should I do?',
              answer: isIndo ? 'Jika Anda belum login, tekan "Lupa Password" di halaman login. Jika sudah login dan ingin mengganti, masuk ke menu Profil > Ganti Password.' : 'If you haven\'t logged in, press "Forgot Password" on the login page. If logged in and want to change it, go to Profile > Change Password.',
            ),
            
            Container(
              width: double.infinity,
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
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.mark_email_unread_rounded, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isIndo ? 'Punya Pertanyaan Lain?' : 'Have Other Questions?',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email_outlined, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('support@uangku.com', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        CustomPopup.show(context, 'Membuka aplikasi email...', isSuccess: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(isIndo ? 'Hubungi Kami Sekarang' : 'Contact Us Now', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildFaqItem({required BuildContext context, required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: context.isDarkMode ? [] : [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary),
          ),
          iconColor: AppColors.primaryBlue,
          collapsedIconColor: context.textSecondary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(
              answer,
              style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
