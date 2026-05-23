import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FAQ & Solusi Cepat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Temukan jawaban untuk pertanyaan umum seputar aplikasi Uangku.',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 24),
            
            _buildFaqItem(
              question: 'Bagaimana cara menambah pengeluaran baru?',
              answer: 'Anda dapat menekan tombol tambah (+) berwarna biru di menu navigasi bawah pada layar utama, kemudian pilih tipe transaksi dan masukkan nominal serta kategori.',
            ),
            _buildFaqItem(
              question: 'Apakah Uangku menyimpan data di cloud?',
              answer: 'Saat ini, Uangku menyimpan data secara aman. Jika Anda mengaktifkan sinkronisasi akun, data akan dicadangkan ke server untuk memudahkan akses dari perangkat lain.',
            ),
            _buildFaqItem(
              question: 'Bagaimana cara kerja Wawasan AI (AI Insights)?',
              answer: 'Fitur Wawasan AI menggunakan model analisis cerdas untuk mempelajari pola pengeluaran Anda dan memberikan saran keuangan personal untuk membantu Anda berhemat.',
            ),
            _buildFaqItem(
              question: 'Saya lupa password, apa yang harus dilakukan?',
              answer: 'Jika Anda belum login, tekan "Lupa Password" di halaman login. Jika sudah login dan ingin mengganti, masuk ke menu Profil > Ganti Password.',
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
                  const Text(
                    'Punya Pertanyaan Lain?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                      child: const Text('Hubungi Kami Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildFaqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2E8F0).withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          iconColor: AppColors.primaryBlue,
          collapsedIconColor: const Color(0xFF94A3B8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(
              answer,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
