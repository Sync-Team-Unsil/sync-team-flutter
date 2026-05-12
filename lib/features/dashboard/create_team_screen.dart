import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    if (tag.isNotEmpty && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await TeamsService.createTeam(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        requirements: _reqCtrl.text.trim(),
        maxMembers: _maxMembers,
        tags: _tags,
      );
      ref.invalidate(myTeamsProvider);
      ref.invalidate(availableTeamsProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team created successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Create Team'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Team Name', _nameCtrl, 'e.g. Mobile Development Hackathon'),
            const SizedBox(height: 24),
            _field('Description', _descCtrl, 'Tell others what this team is about', lines: 3),
            const SizedBox(height: 24),
            _field('Requirements', _reqCtrl, 'What skills are you looking for?', lines: 3),
            const SizedBox(height: 24),
            Text('Max Members: $_maxMembers', style: Theme.of(context).textTheme.titleLarge),
            Slider(
              value: _maxMembers.toDouble(),
              min: 2,
              max: 20,
              divisions: 18,
              label: _maxMembers.toString(),
              onChanged: (val) => setState(() => _maxMembers = val.round()),
            ),
            const SizedBox(height: 24),
            Text('Tags (Max 5)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(hintText: 'Add a tag'),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(onPressed: _addTag, icon: const Icon(Icons.add_circle, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _tags.map((t) => Chip(
                label: Text('#$t'),
                onDeleted: () => setState(() => _tags.remove(t)),
              )).toList(),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Create Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String l, TextEditingController c, String h, {int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          maxLines: lines,
          decoration: InputDecoration(hintText: h),
        ),
      ],
    );
  }
}
