import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../data/database_helper.dart';
import '../services/file_service.dart';
import '../widgets/video_player_widget.dart';

class MediaListScreen extends StatefulWidget {
  final String type; // 'image' or 'video'
  const MediaListScreen({super.key, required this.type});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  List<Map<String, dynamic>> _mediaList = [];
  final Set<int> _selectedIds = {};
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() => _isLoading = true);
    try {
      final data = await DatabaseHelper.instance.queryAllMedia(widget.type);
      setState(() {
        _mediaList = data;
        _isLoading = false;
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('Error loading media: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _mediaList.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        for (var item in _mediaList) {
          _selectedIds.add(item['id']);
        }
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف $count من العناصر المختارة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        for (var id in _selectedIds) {
          final item = _mediaList.firstWhere((element) => element['id'] == id);
          await FileService.deleteMedia(id, item['internal_path']);
        }
        _loadMedia();
      } catch (e) {
        debugPrint('Error deleting media: $e');
        _loadMedia();
      }
    }
  }

  Future<void> _downloadSelected() async {
    setState(() => _isLoading = true);
    try {
      List<XFile> filesToShare = [];
      for (var id in _selectedIds) {
        final item = _mediaList.firstWhere((element) => element['id'] == id);
        final file = await FileService.getMediaFile(item['internal_path']);
        if (file != null) {
          filesToShare.add(XFile(file.path, name: item['file_name']));
        }
      }

      if (filesToShare.isNotEmpty) {
        await Share.shareXFiles(filesToShare, text: 'تصدير الوسائط من Haa Backup');
      }
      
      setState(() {
        _isLoading = false;
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    } catch (e) {
      debugPrint('Error downloading media: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultiMedia() async {
    List<XFile>? pickedFiles;
    if (widget.type == 'image') {
      pickedFiles = await _picker.pickMultiImage();
    } else {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) pickedFiles = [video];
    }
    
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      _showProgressDialog();
      int successCount = 0;
      for (var xFile in pickedFiles) {
        final success = await FileService.processAndSaveMedia(File(xFile.path), widget.type);
        if (success) successCount++;
      }
      if (mounted) Navigator.pop(context);
      _loadMedia();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ $successCount ملف بنجاح في الخزنة الآمنة')));
    }
  }

  void _showProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'image' ? 'الخزنة الآمنة للصور' : 'الخزنة الآمنة للفيديوهات';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedIds.length} مختار' : title),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _downloadSelected,
              tooltip: 'تنزيل للهاتف',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _deleteSelected,
              tooltip: 'حذف المختار',
            ),
          ],
          if (_mediaList.isNotEmpty)
            IconButton(
              icon: Icon(_selectedIds.length == _mediaList.length ? Icons.deselect : Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'تحديد الكل',
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _mediaList.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.type == 'image' ? Icons.lock_outline : Icons.video_library_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('الخزنة فارغة حالياً', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _mediaList.length,
              itemBuilder: (context, index) {
                final item = _mediaList[index];
                final id = item['id'];
                final Uint8List? thumbnail = item['thumbnail_data'];
                final isSelected = _selectedIds.contains(id);
                
                return GestureDetector(
                  onLongPress: () => _toggleSelection(id),
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(id);
                    } else {
                      _viewMedia(item);
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget.type == 'image' && thumbnail != null
                            ? Image.memory(thumbnail, fit: BoxFit.cover)
                            : Container(
                                color: Colors.black87,
                                child: Center(
                                  child: Icon(
                                    widget.type == 'image' ? Icons.image : Icons.play_circle_outline, 
                                    color: Colors.white, 
                                    size: 40
                                  ),
                                ),
                              ),
                        ),
                      ),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickMultiMedia,
        backgroundColor: widget.type == 'image' ? Colors.blueAccent : Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _viewMedia(Map<String, dynamic> item) async {
    _showProgressDialog();
    final file = await FileService.getMediaFile(item['internal_path']);
    if (mounted) Navigator.pop(context);

    if (file == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر العثور على الملف الأصلي')));
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(item['file_name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            body: Center(
              child: widget.type == 'image'
                ? InteractiveViewer(child: Image.file(file))
                : VideoPlayerWidget(file: file),
            ),
          ),
        ),
      );
    }
  }
}
