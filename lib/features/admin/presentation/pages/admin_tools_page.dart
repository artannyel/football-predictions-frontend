import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/admin/data/models/admin_log_model.dart';
import 'package:football_predictions/features/admin/data/models/admin_match_model.dart';
import 'package:football_predictions/features/admin/data/repositories/admin_repository.dart';
import 'package:football_predictions/core/utils/file_saver.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:provider/provider.dart';

class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  bool _isLoading = false;
  List<AdminFilterItem> _competitions = [];
  List<AdminLogModel> _logs = [];

  // Inputs
  int? _selectedImportCompetitionId;
  final _badgeSlugController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final repo = context.read<AdminRepository>();
      final filters = await repo.getFilters();
      final logs = await repo.getLogs();

      if (mounted) {
        setState(() {
          _competitions = filters.competitions;
          _logs = logs;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar dados iniciais: $e');
    }
  }

  Future<void> _executeAction(
    String title,
    Future<void> Function() action, {
    bool confirm = false,
    String? confirmMessage,
    bool isDanger = false,
  }) async {
    if (confirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(confirmMessage ?? 'Tem certeza que deseja continuar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: isDanger
                  ? FilledButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: Operação iniciada/concluída com sucesso.'),
            backgroundColor: Colors.green,
          ),
        );
        // Recarrega logs pois a ação pode ter gerado um novo
        _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ferramentas de Sistema')),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildImportCard(),
                const SizedBox(height: 16),
                _buildReprocessingCard(),
                const SizedBox(height: 16),
                _buildMaintenanceCard(),
                const SizedBox(height: 16),
                _buildLogsCard(),
              ],
            ),
    );
  }

  Widget _buildImportCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_download, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Importação de Dados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          const Text(
            'Força a importação de jogos da API externa.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedImportCompetitionId,
            decoration: const InputDecoration(
              labelText: 'Competição (Opcional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              ..._competitions.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) => setState(() => _selectedImportCompetitionId = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _executeAction(
                'Importar Partidas',
                () => context.read<AdminRepository>().importMatches(
                      competitionId: _selectedImportCompetitionId,
                    ),
              ),
              icon: const Icon(Icons.sync),
              label: const Text('Importar Partidas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReprocessingCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Reprocessamento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          const Text(
            'Atenção: Estas ações podem demorar e afetar o desempenho.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Ação 1
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => _executeAction(
                'Recalcular Stats',
                () => context.read<AdminRepository>().recalculateStats(),
                confirm: true,
                confirmMessage:
                    'Tem certeza? Isso vai recalcular os pontos de todos os usuários em todas as ligas.',
              ),
              child: const Text('Recalcular Estatísticas de Ligas'),
            ),
          ),
          const SizedBox(height: 16),
          // Ação 2
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _badgeSlugController,
                  decoration: const InputDecoration(
                    labelText: 'Slug da Medalha (Opcional)',
                    hintText: 'ex: sniper',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _executeAction(
                  'Recalcular Medalhas',
                  () => context.read<AdminRepository>().recalculateBadges(
                        badgeSlug: _badgeSlugController.text,
                      ),
                ),
                child: const Text('Recalcular'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Ação 3
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => _executeAction(
                'Resetar Ranking Global',
                () => context.read<AdminRepository>().recalculateGlobalStats(),
                confirm: true,
                isDanger: true,
                confirmMessage:
                    'ATENÇÃO: Isso vai apagar e recriar todo o histórico do Ranking Global. Pode levar vários minutos.',
              ),
              child: const Text('Resetar Ranking Global'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Manutenção Diária',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _executeAction(
                'Distribuir Power-Ups',
                () => context.read<AdminRepository>().distributePowerups(),
              ),
              icon: const Icon(Icons.flash_on),
              label: const Text('Distribuir Power-Ups Semanais'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.description, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Logs do Sistema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadInitialData,
              ),
            ],
          ),
          const Divider(),
          if (_logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Nenhum log encontrado.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Arquivo')),
                  DataColumn(label: Text('Tamanho')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Ação')),
                ],
                rows: _logs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(Text(log.filename)),
                      DataCell(Text(log.size)),
                      DataCell(Text(log.lastModified)),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () async {
                            try {
                              final bytes = await context
                                  .read<AdminRepository>()
                                  .downloadLog(log.filename);
                              final msg = await saveFile(log.filename, bytes);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(msg)),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}