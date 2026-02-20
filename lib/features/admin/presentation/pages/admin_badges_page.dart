import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/admin/data/models/admin_badge_model.dart';
import 'package:football_predictions/features/admin/data/repositories/admin_repository.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AdminBadgesPage extends StatefulWidget {
  const AdminBadgesPage({super.key});

  @override
  State<AdminBadgesPage> createState() => _AdminBadgesPageState();
}

class _AdminBadgesPageState extends State<AdminBadgesPage> {
  bool _isLoading = false;
  List<AdminBadgeModel> _badges = [];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    try {
      final badges = await context.read<AdminRepository>().getBadges();
      if (mounted) {
        setState(() {
          _badges = badges;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditDialog(AdminBadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) => _EditBadgeDialog(
        badge: badge,
        onSaved: _loadBadges,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Medalhas')),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : RefreshIndicator(
              onRefresh: _loadBadges,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _badges.length,
                itemBuilder: (context, index) {
                  final badge = _badges[index];
                  return _buildBadgeCard(badge);
                },
              ),
            ),
    );
  }

  Widget _buildBadgeCard(AdminBadgeModel badge) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: badge.iconUrl != null
                ? AppNetworkImage(
                    url: badge.iconUrl!,
                    fit: BoxFit.contain,
                  )
                : const Icon(Icons.military_tech, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            badge.slug,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge.type.toUpperCase(),
              style: const TextStyle(fontSize: 8, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditDialog(badge),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Editar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditBadgeDialog extends StatefulWidget {
  final AdminBadgeModel badge;
  final VoidCallback onSaved;

  const _EditBadgeDialog({required this.badge, required this.onSaved});

  @override
  State<_EditBadgeDialog> createState() => _EditBadgeDialogState();
}

class _EditBadgeDialogState extends State<_EditBadgeDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  XFile? _selectedImage;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.badge.name);
    _descController = TextEditingController(text: widget.badge.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    debugPrint('pickImage');
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AdminRepository>().updateBadge(
            slug: widget.badge.slug,
            name: _nameController.text,
            description: _descController.text,
            iconFile: _selectedImage,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medalha atualizada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar: ${widget.badge.slug}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: _selectedImage != null
                    ? kIsWeb
                        ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                        : Image.file(File(_selectedImage!.path), fit: BoxFit.cover)
                    : widget.badge.iconUrl != null
                        ? AppNetworkImage(
                            url: widget.badge.iconUrl!,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.add_a_photo, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Toque para alterar ícone', style: TextStyle(fontSize: 10)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}