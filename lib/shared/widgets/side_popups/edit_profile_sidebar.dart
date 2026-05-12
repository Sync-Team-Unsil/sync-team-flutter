import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import '../../../core/theme.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../core/side_popup_provider.dart';

class EditProfileSidebar extends ConsumerStatefulWidget {
  const EditProfileSidebar({super.key});

  @override
  ConsumerState<EditProfileSidebar> createState() => _EditProfileSidebarState();
}

class _EditProfileSidebarState extends ConsumerState<EditProfileSidebar> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  bool _isLoading = false;
  XFile? _imageFile;
  String? _avatarUrl;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      _firstNameCtrl.text = profile.firstName ?? '';
      _lastNameCtrl.text = profile.lastName ?? '';
      _usernameCtrl.text = profile.username ?? '';
      _roleCtrl.text = profile.role ?? '';
      _bioCtrl.text = profile.bio ?? ''; 
      _avatarUrl = profile.avatarUrl;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _roleCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = pickedFile);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _avatarUrl;

    final userId = ref.read(userIdProvider);
    if (userId == null) return null;

    final supabase = Supabase.instance.client;
    final extension = p.extension(_imageFile!.path).toLowerCase();
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}${extension.isEmpty ? ".jpg" : extension}';
    final bytes = await _imageFile!.readAsBytes();

    try {
      await supabase.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      return url;
    } catch (e) {
      debugPrint('Upload error: $e');
      return _avatarUrl;
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final uploadedUrl = await _uploadImage();

      await ref.read(profileProvider.notifier).updateProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        role: _roleCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        avatarUrl: uploadedUrl,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ref.read(sidePopupProvider.notifier).hide();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    
    if (!isWide) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () {
              Navigator.pop(context);
              ref.read(sidePopupProvider.notifier).hide();
            },
          ),
          actions: [
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))))
            else
              IconButton(icon: const Icon(Icons.check_rounded), onPressed: _save),
          ],
        ),
        body: _buildForm(),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
            child: Row(
              children: [
                Text('Edit Profile', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(child: _buildForm()),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Change'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar Section ──
          Center(
            child: DropTarget(
              onDragDone: (detail) async {
                if (detail.files.isNotEmpty) {
                  setState(() => _imageFile = detail.files.first);
                }
              },
              onDragEntered: (_) => setState(() => _isDragging = true),
              onDragExited: (_) => setState(() => _isDragging = false),
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.inputFill,
                      border: Border.all(
                        color: _isDragging ? AppColors.primary : const Color(0xFFE2E8F0),
                        width: _isDragging ? 3 : 1,
                      ),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: kIsWeb 
                                  ? NetworkImage(_imageFile!.path) as ImageProvider
                                  : FileImage(File(_imageFile!.path)) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : (_avatarUrl != null
                              ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                              : null),
                    ),
                    child: (_imageFile == null && _avatarUrl == null)
                        ? const Icon(Icons.person, size: 50, color: AppColors.textMuted)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        if (kIsWeb) {
                          _pickImage(ImageSource.gallery);
                        } else {
                          _showImageSourceActionSheet(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              kIsWeb ? 'Click icon to select or drag photo here' : 'Tap icon to change photo',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 32),

          _buildLabel('First Name'),
          const SizedBox(height: 8),
          _buildInput(_firstNameCtrl, 'Enter first name'),
          const SizedBox(height: 24),
          _buildLabel('Last Name'),
          const SizedBox(height: 8),
          _buildInput(_lastNameCtrl, 'Enter last name'),
          const SizedBox(height: 24),
          _buildLabel('Username'),
          const SizedBox(height: 8),
          _buildInput(_usernameCtrl, 'Enter username'),
          const SizedBox(height: 24),
          _buildLabel('Role'),
          const SizedBox(height: 8),
          _buildInput(_roleCtrl, 'e.g. Back-end Developer'),
          const SizedBox(height: 24),
          _buildLabel('Bio'),
          const SizedBox(height: 8),
          _buildInput(_bioCtrl, 'Tell us about yourself', maxLines: 4),
        ],
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate700));
  }

  Widget _buildInput(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
