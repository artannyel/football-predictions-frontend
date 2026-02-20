import 'package:flutter/material.dart';
import 'package:football_predictions/core/presentation/widgets/loading_widget.dart';
import 'package:football_predictions/features/admin/data/models/admin_match_model.dart';
import 'package:football_predictions/features/admin/data/repositories/admin_repository.dart';
import 'package:football_predictions/features/home/presentation/widgets/glass_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AdminMatchesPage extends StatefulWidget {
  const AdminMatchesPage({super.key});

  @override
  State<AdminMatchesPage> createState() => _AdminMatchesPageState();
}

class _AdminMatchesPageState extends State<AdminMatchesPage> {
  // Filtros
  AdminFiltersModel? _filtersData;
  int? _selectedCompetitionId;
  String? _selectedStatus;
  final _teamController = TextEditingController();
  DateTime? _dateFrom;
  DateTime? _dateTo;

  // Lista
  final List<AdminMatchModel> _matches = [];
  bool _isLoading = false;
  int _page = 1;
  int _lastPage = 1;
  bool _isStuckMode = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadMatches();
  }

  Future<void> _loadFilters() async {
    try {
      final data = await context.read<AdminRepository>().getFilters();
      setState(() => _filtersData = data);
    } catch (e) {
      debugPrint('Erro ao carregar filtros: $e');
    }
  }

  Future<void> _loadMatches({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _page = 1;
      _lastPage = 1;
      _matches.clear();
    } else if (_page > _lastPage) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await context.read<AdminRepository>().getMatches(
            page: _page,
            stuck: _isStuckMode,
            competitionId: _selectedCompetitionId,
            status: _selectedStatus,
            teamName: _teamController.text,
            dateFrom: _dateFrom?.toIso8601String().split('T')[0],
            dateTo: _dateTo?.toIso8601String().split('T')[0],
          );

      setState(() {
        _matches.addAll(result.matches);
        _lastPage = result.lastPage;
        _page++;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleStuckMode() {
    setState(() {
      _isStuckMode = !_isStuckMode;
      // Limpa filtros se entrar no modo stuck
      if (_isStuckMode) {
        _selectedCompetitionId = null;
        _selectedStatus = null;
        _teamController.clear();
        _dateFrom = null;
        _dateTo = null;
      }
    });
    _loadMatches(refresh: true);
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Partidas'),
        actions: [
          TextButton.icon(
            onPressed: _toggleStuckMode,
            icon: Icon(
              _isStuckMode ? Icons.list : Icons.warning_amber_rounded,
              color: _isStuckMode ? Colors.white : Colors.orangeAccent,
            ),
            label: Text(
              _isStuckMode ? 'Ver Todos' : 'Jogos Travados',
              style: TextStyle(
                color: _isStuckMode ? Colors.white : Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isStuckMode) _buildFilters(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedCompetitionId,
                    decoration: const InputDecoration(
                      labelText: 'Competição',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: _filtersData?.competitions.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCompetitionId = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: _filtersData?.statuses.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedStatus = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _teamController,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(true),
                  tooltip: 'Data Inicial',
                ),
                if (_dateFrom != null)
                  Text(DateFormat('dd/MM').format(_dateFrom!)),
                const Text(' - '),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(false),
                  tooltip: 'Data Final',
                ),
                if (_dateTo != null) Text(DateFormat('dd/MM').format(_dateTo!)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _loadMatches(refresh: true),
                child: const Text('FILTRAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_matches.isEmpty && _isLoading) {
      return const Center(child: LoadingWidget());
    }
    if (_matches.isEmpty) {
      return const Center(child: Text('Nenhuma partida encontrada.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          _loadMatches();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _matches.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _matches.length) {
            return const Center(child: LoadingWidget());
          }
          final match = _matches[index];
          return _buildMatchCard(match);
        },
      ),
    );
  }

  Widget _buildMatchCard(AdminMatchModel match) {
    final date = DateTime.parse(match.utcDate).toLocal();
    final formattedDate = DateFormat('dd/MM HH:mm').format(date);

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$formattedDate • ${match.competitionName}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (match.isManualUpdate)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'EDITADO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.homeTeamName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${match.homeScore ?? '-'} x ${match.awayScore ?? '-'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  match.awayTeamName,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            match.status,
            style: TextStyle(
              color: match.status == 'IN_PLAY' ? Colors.green : Colors.grey,
              fontSize: 12,
            ),
          ),
          const Divider(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showFixMatchDialog(match),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Corrigir / Editar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showFixMatchDialog(AdminMatchModel match) {
    showDialog(
      context: context,
      builder: (context) => _FixMatchDialog(
        match: match,
        onSaved: () {
          _loadMatches(refresh: true);
        },
      ),
    );
  }
}

class _FixMatchDialog extends StatefulWidget {
  final AdminMatchModel match;
  final VoidCallback onSaved;

  const _FixMatchDialog({required this.match, required this.onSaved});

  @override
  State<_FixMatchDialog> createState() => _FixMatchDialogState();
}

class _FixMatchDialogState extends State<_FixMatchDialog> {
  late TextEditingController _homeScoreCtrl;
  late TextEditingController _awayScoreCtrl;
  late TextEditingController _homeScoreExtraCtrl;
  late TextEditingController _awayScoreExtraCtrl;
  late TextEditingController _homeScorePenCtrl;
  late TextEditingController _awayScorePenCtrl;
  String? _selectedStatus;
  String? _selectedWinner;
  String? _selectedDuration;
  bool _unlock = false;
  bool _isSaving = false;

  final List<String> _statuses = [
    'SCHEDULED',
    'TIMED',
    'IN_PLAY',
    'PAUSED',
    'FINISHED',
    'SUSPENDED',
    'POSTPONED',
    'CANCELLED',
    'AWARDED',
  ];

  final List<String> _winners = ['HOME_TEAM', 'AWAY_TEAM', 'DRAW'];
  final List<String> _durations = ['REGULAR', 'EXTRA_TIME', 'PENALTY_SHOOTOUT'];

  @override
  void initState() {
    super.initState();
    _homeScoreCtrl =
        TextEditingController(text: widget.match.homeScore?.toString() ?? '');
    _awayScoreCtrl =
        TextEditingController(text: widget.match.awayScore?.toString() ?? '');
    _homeScoreExtraCtrl = TextEditingController(
        text: widget.match.homeScoreExtraTime?.toString() ?? '');
    _awayScoreExtraCtrl = TextEditingController(
        text: widget.match.awayScoreExtraTime?.toString() ?? '');
    _homeScorePenCtrl = TextEditingController(
        text: widget.match.homeScorePenalties?.toString() ?? '');
    _awayScorePenCtrl = TextEditingController(
        text: widget.match.awayScorePenalties?.toString() ?? '');

    _selectedStatus = widget.match.status;
    _selectedWinner = widget.match.winner;
    _selectedDuration = widget.match.duration ?? 'REGULAR';
  }

  @override
  void dispose() {
    _homeScoreCtrl.dispose();
    _awayScoreCtrl.dispose();
    _homeScoreExtraCtrl.dispose();
    _awayScoreExtraCtrl.dispose();
    _homeScorePenCtrl.dispose();
    _awayScorePenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AdminRepository>().fixMatch(
            id: widget.match.id,
            unlock: _unlock,
            status: _selectedStatus,
            homeScore: int.tryParse(_homeScoreCtrl.text),
            awayScore: int.tryParse(_awayScoreCtrl.text),
            homeScoreExtra: int.tryParse(_homeScoreExtraCtrl.text),
            awayScoreExtra: int.tryParse(_awayScoreExtraCtrl.text),
            homeScorePen: int.tryParse(_homeScorePenCtrl.text),
            awayScorePen: int.tryParse(_awayScorePenCtrl.text),
            winner: _selectedWinner,
            duration: _selectedDuration,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partida atualizada com sucesso!')),
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
    final showExtraTime = _selectedDuration == 'EXTRA_TIME' || _selectedDuration == 'PENALTY_SHOOTOUT';
    final showPenalties = _selectedDuration == 'PENALTY_SHOOTOUT';

    return AlertDialog(
      title: Text('Corrigir: ${widget.match.homeTeamName} x ${widget.match.awayTeamName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Destravar (API Automática)'),
              subtitle: const Text(
                'Remove a edição manual e permite que a API atualize o jogo.',
                style: TextStyle(fontSize: 12),
              ),
              value: _unlock,
              onChanged: (v) => setState(() => _unlock = v),
            ),
            const Divider(),
            if (!_unlock) ...[
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _homeScoreCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Placar Casa (Tempo Normal)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _awayScoreCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Placar Fora (Tempo Normal)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedWinner,
                decoration: const InputDecoration(labelText: 'Vencedor'),
                items: _winners
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedWinner = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedDuration,
                decoration: const InputDecoration(labelText: 'Duração'),
                items: _durations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDuration = v),
              ),
              if (showExtraTime) ...[
                const SizedBox(height: 16),
                const Text('Prorrogação', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _homeScoreExtraCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Casa (Extra)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _awayScoreExtraCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fora (Extra)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showPenalties) ...[
                const SizedBox(height: 16),
                const Text('Pênaltis', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _homeScorePenCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Casa (Pênaltis)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _awayScorePenCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fora (Pênaltis)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
