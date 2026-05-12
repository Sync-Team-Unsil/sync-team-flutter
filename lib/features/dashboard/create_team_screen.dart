import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'teams_provider.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
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
        const SnackBar(content: Text('Please fill all required fields')),
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
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Teams'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            _buildLabel('Teams name', required: true),
            const SizedBox(height: 8),
            _buildInput(_nameCtrl, 'Enter your teams name'),

            const SizedBox(height: 24),

            // Description
            _buildLabel('Teams description', required: true),
            const SizedBox(height: 8),
            _buildInput(_descCtrl, 'Tell them about your team', maxLines: 4, maxLength: 500),

            const SizedBox(height: 24),

            // Team numbers
            _buildLabel('Team numbers', required: true),
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
                  GestureDetector(
                    onTap: () {
                      if (_maxMembers > 2) setState(() => _maxMembers--);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.remove, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$_maxMembers',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_maxMembers < 20) setState(() => _maxMembers++);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add, size: 18, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Requirements
            _buildLabel('Requirements', required: true),
            const SizedBox(height: 8),
            _buildInput(_reqCtrl, 'Whats the requirement to join your team', maxLines: 4, maxLength: 500),

            const SizedBox(height: 24),

            // Tags
            _buildLabel('Tags', required: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Add related tags for your teams',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _addTag,
                        child: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 24),
                      ),
                    ],
                  ),
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.tagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('# $t', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.tagText, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _tags.remove(t)),
                              child: const Icon(Icons.close, size: 14, color: AppColors.tagText),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Max ${_tags.length}/5 tags',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Register teams'),
              ),
            ),
          ],
        ),
      ),
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
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
      ),
    );
  }
}
