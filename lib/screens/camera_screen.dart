import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/photo.dart';
import '../services/photos.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, required this.coupleId, required this.myUid});

  final String coupleId;
  final String myUid;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    Navigator.of(context).pop(); // close the source-picker sheet
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 70,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 700 * 1024) {
        setState(() => _error = 'الصورة كبيرة، جرّب صورة ثانية أو بجودة أقل.');
        return;
      }

      setState(() {
        _uploading = true;
        _error = null;
      });
      await addPhoto(widget.coupleId, widget.myUid, bytes);
    } catch (_) {
      setState(() => _error = 'تعذّر إضافة الصورة، حاول مرة ثانية.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _openSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1522),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إضافة صورة',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ListTile(
                onTap: () => _pick(ImageSource.camera),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_camera_rounded, color: Color(0xFFFF3D77)),
                title: const Text('التقط صورة', style: TextStyle(color: Colors.white)),
              ),
              ListTile(
                onTap: () => _pick(ImageSource.gallery),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF7B61FF)),
                title: const Text('اختر من المعرض', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openViewer(Photo photo) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: _PhotoViewer(
            photo: photo,
            isMine: photo.senderId == widget.myUid,
            onDelete: () async {
              Navigator.of(context).pop();
              await deletePhoto(widget.coupleId, photo.id);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15111A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('الكاميرا 📷'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _openSourceSheet,
        backgroundColor: const Color(0xFFFF3D77),
        child: _uploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B)), textAlign: TextAlign.center),
              ),
            Expanded(
              child: StreamBuilder<List<Photo>>(
                stream: watchPhotos(widget.coupleId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFFF3D77)));
                  }
                  final photos = snap.data!;
                  if (photos.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'لسا ما فيه صور — اضغط على زر الكاميرا وابدأوا تجمعوا لحظاتكم 📷',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF9C8FAE)),
                        ),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return GestureDetector(
                        onTap: () => _openViewer(photo),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(photo.imageBase64),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.photo, required this.isMine, required this.onDelete});

  final Photo photo;
  final bool isMine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Uint8List bytes = base64Decode(photo.imageBase64);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.memory(bytes),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                ),
              ),
              if (isMine)
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 26),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  _formatDate(photo.createdAt),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '...';
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
