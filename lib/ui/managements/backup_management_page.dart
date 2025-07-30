import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../../services/backup_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BackupManagementPage extends StatefulWidget {
  const BackupManagementPage({super.key});

  @override
  State<BackupManagementPage> createState() => _BackupManagementPageState();
}

class _BackupManagementPageState extends State<BackupManagementPage> {
  final BackupService _backupService = BackupService();
  List<Map<String, dynamic>> _backupHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupHistory();
  }

  Future<void> _loadBackupHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _backupService.getBackupHistory();
      setState(() {
        _backupHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedekleme geçmişi yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final backup = await _backupService.createBackup();
      final filePath = await _backupService.saveBackupToDownloads(backup);
      
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yedekleme başarıyla oluşturuldu!\nDosya: ${filePath.split('/').last}'),
            duration: const Duration(seconds: 3),
          ),
        );
        _loadBackupHistory();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedekleme oluşturulamadı: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final typeGroup = XTypeGroup(
        label: 'JSON files',
        extensions: ['json'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file != null) {
        setState(() => _isLoading = true);
        
        final backup = await _backupService.loadBackupFromFile(file.path);
        
        // Onay dialogu
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Yedekleme Geri Yükle'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bu işlem mevcut tüm verileri silecek ve yedeklemedeki verileri geri yükleyecek.'),
                const SizedBox(height: 16),
                Text('Harcama Sayısı: ${(backup['expenses'] as List).length}'),
                Text('Bütçe Sayısı: ${(backup['budgets'] as List).length}'),
                Text('Oluşturulma: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(backup['created_at']))}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Geri Yükle'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await _backupService.restoreBackup(backup);
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yedekleme başarıyla geri yüklendi!')),
            );
            Navigator.of(context).pop(); // Sayfayı kapat
          }
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedekleme geri yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _deleteBackup(String filePath) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yedekleme Sil'),
        content: const Text('Bu yedeklemeyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _backupService.deleteBackup(filePath);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yedekleme silindi!')),
          );
          _loadBackupHistory();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Yedekleme silinemedi: $e')),
          );
        }
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.backupManagement),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Butonlar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createBackup,
                          icon: const Icon(Icons.backup),
                          label: const Text('Yedekleme Oluştur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _restoreBackup,
                          icon: const Icon(Icons.restore),
                          label: const Text('Yedekleme Geri Yükle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Yedekleme geçmişi
                Expanded(
                  child: _backupHistory.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.backup, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Henüz yedekleme yok',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _backupHistory.length,
                          itemBuilder: (context, index) {
                            final backup = _backupHistory[index];
                            final createdAt = DateTime.parse(backup['created_at']);
                            
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.backup, color: Colors.blue),
                                title: Text(backup['name']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Oluşturulma: ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}'),
                                    Text('Harcama: ${backup['expense_count']}, Bütçe: ${backup['budget_count']}'),
                                    Text('Boyut: ${_formatFileSize(backup['size'])}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteBackup(backup['path']),
                                ),
                                onTap: () async {
                                  try {
                                    final backupData = await _backupService.loadBackupFromFile(backup['path']);
                                    if (mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Yedekleme Detayları'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Dosya: ${backup['name']}'),
                                              Text('Oluşturulma: ${DateFormat('dd.MM.yyyy HH:mm').format(createdAt)}'),
                                              Text('Harcama Sayısı: ${backup['expense_count']}'),
                                              Text('Bütçe Sayısı: ${backup['budget_count']}'),
                                              Text('Boyut: ${_formatFileSize(backup['size'])}'),
                                              const SizedBox(height: 16),
                                              const Text('Bu yedeklemeyi geri yüklemek ister misiniz?'),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('İptal'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                Navigator.pop(ctx);
                                                setState(() => _isLoading = true);
                                                await _backupService.restoreBackup(backupData);
                                                setState(() => _isLoading = false);
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Yedekleme geri yüklendi!')),
                                                  );
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: const Text('Geri Yükle'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Yedekleme okunamadı: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 