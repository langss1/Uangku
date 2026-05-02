import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class SyncService {
  // Ganti dengan IP VPS kamu
  static const String apiUrl = 'http://145.79.10.157:8000/api/sync';

  static Future<void> syncData() async {
    // 1. Cek koneksi internet
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print('Tidak ada koneksi internet. Sync dibatalkan.');
      return;
    }

    // 2. Ambil data yang belum di-sync
    final unsyncedData = await DatabaseHelper.instance.getUnsyncedTransactions();
    
    if (unsyncedData.isEmpty) {
      print('Semua data sudah tersinkronisasi.');
      return;
    }

    print('Menemukan ${unsyncedData.length} data untuk disinkronisasi...');

    try {
      // 3. Kirim ke API Node.js
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'transactions': unsyncedData}),
      );

      if (response.statusCode == 200) {
        // 4. Jika berhasil, update status is_synced di SQLite
        final idsToUpdate = unsyncedData.map((e) => e['id'] as String).toList();
        await DatabaseHelper.instance.markAsSynced(idsToUpdate);
        print('Sinkronisasi berhasil!');
      } else {
        print('Gagal sinkronisasi. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Terjadi kesalahan saat sinkronisasi: $e');
    }
  }
}
