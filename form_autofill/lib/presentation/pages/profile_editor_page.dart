import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/form_profile.dart';

class ProfileEditorPage extends StatefulWidget {
  final List<FormProfile> profiles;
  final FormProfile? activeProfile;
  final Future<void> Function(FormProfile) onSave;
  final Future<void> Function(String) onDelete;
  final Future<void> Function(String) onSetActive;

  const ProfileEditorPage({
    super.key,
    required this.profiles,
    required this.activeProfile,
    required this.onSave,
    required this.onDelete,
    required this.onSetActive,
  });

  @override
  State<ProfileEditorPage> createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends State<ProfileEditorPage> {
  static const _fieldLabels = {
    'father_name': 'Father Name',
    'mother_name': 'Mother Name',
    'gender': 'Gender',
    'address': 'Address',
    'dob': 'Date of Birth',
    'district': 'District',
    'full_name': 'Full Name',
    'email': 'Email',
    'phone': 'Phone',
    'pincode': 'Pincode',
    'state': 'State',
    'city': 'City',
    'aadhaar': 'Aadhaar',
    'pan': 'PAN',
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Data Profiles',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('New'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.profiles.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No profiles yet. Create one to store form data.'),
              ),
            ),
          )
        else
          ...widget.profiles.map((p) => _ProfileTile(
                profile: p,
                isActive: widget.activeProfile?.id == p.id,
                onTap: () => _openEditor(context, profile: p),
                onSetActive: () => widget.onSetActive(p.id),
                onDelete: () => _confirmDelete(context, p),
              )),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, FormProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('Delete "${p.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await widget.onDelete(p.id);
  }

  Future<void> _openEditor(BuildContext context, {FormProfile? profile}) async {
    final result = await Navigator.push<FormProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProfileFormScreen(
          profile: profile,
          fieldLabels: _fieldLabels,
        ),
      ),
    );
    if (result != null) await widget.onSave(result);
  }
}

class _ProfileTile extends StatelessWidget {
  final FormProfile profile;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onSetActive;
  final VoidCallback onDelete;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.onTap,
    required this.onSetActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(profile.name.isNotEmpty ? profile.name[0] : '?'),
        ),
        title: Text(profile.name),
        subtitle: Text('${profile.fields.length} fields'),
        trailing: isActive
            ? const Chip(label: Text('Active'))
            : IconButton(
                icon: const Icon(Icons.check),
                onPressed: onSetActive,
                tooltip: 'Set active',
              ),
        onTap: onTap,
        onLongPress: onDelete,
      ),
    );
  }
}

class _ProfileFormScreen extends StatefulWidget {
  final FormProfile? profile;
  final Map<String, String> fieldLabels;

  const _ProfileFormScreen({this.profile, required this.fieldLabels});

  @override
  State<_ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<_ProfileFormScreen> {
  late final TextEditingController _nameController;
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    for (final key in AppConstants.defaultLabelKeys) {
      _controllers[key] = TextEditingController(
        text: widget.profile?.fields[key] ?? '',
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'New Profile' : 'Edit Profile'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Profile Name',
              hintText: 'e.g. Government Form 2025',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Form Fields',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...widget.fieldLabels.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _controllers[e.key],
                decoration: InputDecoration(
                  labelText: e.value,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile name is required')),
      );
      return;
    }
    final fields = <String, String>{};
    for (final entry in _controllers.entries) {
      final v = entry.value.text.trim();
      if (v.isNotEmpty) fields[entry.key] = v;
    }
    Navigator.pop(
      context,
      FormProfile(
        id: widget.profile?.id ?? const Uuid().v4(),
        name: name,
        fields: fields,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
