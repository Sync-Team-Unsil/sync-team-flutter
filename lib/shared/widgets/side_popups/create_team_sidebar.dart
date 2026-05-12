import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../../../features/dashboard/teams_provider.dart';

class CreateTeamSidebar extends ConsumerStatefulWidget {
  const CreateTeamSidebar({super.key});

  @override
  ConsumerState<CreateTeamSidebar> createState() => _CreateTeamSidebarState();
}

class _CreateTeamSidebarState extends ConsumerState<CreateTeamSidebar> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _reqCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  int _maxMembers = 5;
  final List<String> _tags = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _reqCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && _tags.length < 5 && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _descCtrl.text.isEmpty || _reqCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi semua field yang wajib')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(teamsServiceProvider).createTeam(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        requirements: _reqCtrl.text.trim(),
        maxMembers: _maxMembers,
        tags: _tags,
      );
      if (mounted) {
        ref.invalidate(myTeamsProvider);
        ref.invalidate(availableTeamsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tim berhasil dibuat!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat tim: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Text(
                'Buat Tim Baru',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Nama Tim', required: true),
                const SizedBox(height: 8),
                _buildInput(_nameCtrl, 'Masukkan nama tim'),

                const SizedBox(height: 24),

                _buildLabel('Deskripsi Tim', required: true),
                const SizedBox(height: 8),
                _buildInput(_descCtrl, 'Ceritakan tentang tim Anda', maxLines: 4, maxLength: 500),

                const SizedBox(height: 24),

                _buildLabel('Jumlah Anggota', required: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Row(
                    children: [
                      _counterBtn(Icons.remove, () {
                        if (_maxMembers > 2) setState(() => _maxMembers--);
                      }),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$_maxMembers',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      _counterBtn(Icons.add, () {
                        if (_maxMembers < 20) setState(() => _maxMembers++);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildLabel('Persyaratan', required: true),
                const SizedBox(height: 8),
                _buildInput(_reqCtrl, 'Apa syarat untuk bergabung?', maxLines: 4, maxLength: 500),

                const SizedBox(height: 24),

                _buildLabel('Tags', required: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagCtrl,
                              decoration: const InputDecoration(hintText: 'Tambah tag...', border: InputBorder.none),
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: _addTag),
                        ],
                      ),
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            onDeleted: () => setState(() => _tags.remove(t)),
                          )).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Buat Tim Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        children: [
          TextSpan(text: text),
          if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, {int maxLines = 1, int? maxLength}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: const BorderSide(color: AppColors.inputBorder)),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
