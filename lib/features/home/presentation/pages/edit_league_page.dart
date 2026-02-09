import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/image_picker_widget.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/home/data/models/league_details_model.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditLeaguePage extends StatefulWidget {
  final String leagueId;

  const EditLeaguePage({super.key, required this.leagueId});

  @override
  State<EditLeaguePage> createState() => _EditLeaguePageState();
}

class _EditLeaguePageState extends State<EditLeaguePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  XFile? _selectedImage;
  bool _isLoading = false;
  LeagueDetailsModel? _league;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _fetchLeagueDetails();
  }

  Future<void> _fetchLeagueDetails() async {
    try {
      final league = await context.read<LeaguesRepository>().getLeagueDetails(widget.leagueId);
      if (mounted) {
        setState(() {
          _league = league;
          _nameController.text = league.name;
          _descriptionController.text = league.description;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados da liga: $e'), backgroundColor: Colors.red),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _hasChanges {
    if (_league == null) return false;
    if (_selectedImage != null) return true;
    if (_nameController.text != _league!.name) return true;
    if (_descriptionController.text != _league!.description) return true;
    return false;
  }

  void _resetChanges() {
    setState(() {
      _nameController.text = _league!.name;
      _descriptionController.text = _league!.description;
      _selectedImage = null;
    });
  }

  Future<void> _updateLeague() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar alterações'),
        content: const Text('Deseja realmente salvar as alterações?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    try {
      await context.read<LeaguesRepository>().updateLeague(
            id: widget.leagueId,
            name: _nameController.text,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
            avatar: _selectedImage,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liga atualizada com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_league == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Liga')),
        body: const Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Liga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Desfazer alterações',
            onPressed: _hasChanges ? _resetChanges : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerWidget(
                image: _selectedImage,
                initialUrl: _league!.avatar,
                onImageSelected: (file) => setState(() {
                  _selectedImage = file;
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Liga *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Por favor, insira o nome da liga'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: _isLoading
                    ? const Center(child: LoadingWidget())
                    : FilledButton(
                        onPressed: _hasChanges ? _updateLeague : null,
                        child: const Text('SALVAR ALTERAÇÕES'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}