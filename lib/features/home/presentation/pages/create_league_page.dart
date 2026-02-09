import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/presentation/widgets/image_picker_widget.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/competitions/data/models/competition_model.dart';
import 'package:football_predictions/features/competitions/data/repositories/competitions_repository.dart';
import 'package:football_predictions/features/home/data/repositories/leagues_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreateLeaguePage extends StatefulWidget {
  const CreateLeaguePage({super.key});

  @override
  State<CreateLeaguePage> createState() => _CreateLeaguePageState();
}

class _CreateLeaguePageState extends State<CreateLeaguePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedCompetitionId;
  XFile? _selectedImage;
  bool _isLoading = false;

  Future<void> _createLeague() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<LeaguesRepository>().createLeague(
        name: _nameController.text,
        competitionId: _selectedCompetitionId!,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        avatar: _selectedImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Liga criada com sucesso!')),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar sucesso
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Nova Liga')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerWidget(
                image: _selectedImage,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome da liga';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<CompetitionModel>>(
                future: context
                    .read<CompetitionsRepository>()
                    .getCompetitions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }
                  return DropdownButtonFormField<int>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Competição *',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedCompetitionId,
                    items: snapshot.data?.map((competition) {
                      return DropdownMenuItem(
                        value: competition.id,
                        child: Row(
                          children: [
                            if (competition.emblem != null) ...[
                              AppNetworkImage(
                                url: competition.emblem!,
                                width: 24,
                                height: 24,
                                errorWidget: const Icon(Icons.sports_soccer, size: 24),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                competition.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCompetitionId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Selecione uma competição' : null,
                  );
                },
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
                        onPressed: _createLeague,
                        child: const Text('CRIAR LIGA'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
