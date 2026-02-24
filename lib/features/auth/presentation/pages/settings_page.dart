import 'package:flutter/material.dart';
import 'package:football_predictions/core/auth/auth_notifier.dart';
import 'package:football_predictions/core/providers/theme_provider.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _updatingResults = false;
  bool _updatingReminders = false;
  bool _updatingNotifyChat = false;

  Future<void> _updateSettings({
    bool? notifyResults,
    bool? notifyReminders,
    bool? notifyChat,
  }) async {
    setState(() {
      if (notifyResults != null) _updatingResults = true;
      if (notifyReminders != null) _updatingReminders = true;
      if (notifyChat != null) _updatingNotifyChat = true;
    });

    final authNotifier = context.read<AuthNotifier>();
    final user = authNotifier.backendUser;
    if (user == null) {
      setState(() {
        _updatingResults = false;
        _updatingReminders = false;
        _updatingNotifyChat = false;
      });
      return;
    }

    final newResults = notifyResults ?? user.notifyResults;
    final newReminders = notifyReminders ?? user.notifyReminders;
    final newChat = notifyChat ?? user.notifyChat;


    // Atualização otimista local
    final updatedUser = user.copyWith(
      notifyResults: newResults,
      notifyReminders: newReminders,
      notifyChat: newChat,
    );
    authNotifier.refreshUser(updatedUser);

    try {
      await context.read<DioClient>().dio.post('user/settings', data: {
        'notify_results': newResults,
        'notify_reminders': newReminders,
        'notify_chat': newChat,
      });

      if (mounted) {
        String message = 'Configurações atualizadas!';
        if (notifyResults != null) {
          message = notifyResults
              ? 'Notificações de resultados ativadas'
              : 'Notificações de resultados desativadas';
        } else if (notifyReminders != null) {
          message = notifyReminders
              ? 'Lembretes ativados'
              : 'Lembretes desativados';
        } else if (notifyChat != null) {
          message = notifyChat
              ? 'Chat de ligas ativado'
              : 'Chat de ligas desativado';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // Reverte em caso de erro
      authNotifier.refreshUser(user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao atualizar configurações'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingResults = false;
          _updatingReminders = false;
          _updatingNotifyChat = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final user = context.watch<AuthNotifier>().backendUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text(
                    'Editar Perfil',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: () => context.push('/perfil/editar'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.sports_soccer),
                  title: const Text(
                    'Resultados dos Jogos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Receba notificações quando os jogos terminarem',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: user?.notifyResults ?? false,
                  onChanged: _updatingResults
                      ? null
                      : (val) => _updateSettings(notifyResults: val),
                  activeColor: isDark
                      ? Colors.greenAccent
                      : Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.access_alarm),
                  title: const Text(
                    'Lembretes de Palpites',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Seja avisado de jogos próximos sem palpite',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: user?.notifyReminders ?? false,
                  onChanged: _updatingReminders
                      ? null
                      : (val) => _updateSettings(notifyReminders: val),
                  activeColor: isDark
                      ? Colors.greenAccent
                      : Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.chat_bubble_outline),
                  title: const Text(
                    'Chat de ligas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Receba notificações de mensagens de suas ligas',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: user?.notifyChat ?? false,
                  onChanged: _updatingNotifyChat
                      ? null
                      : (val) => _updateSettings(notifyChat: val),
                  activeColor: isDark
                      ? Colors.greenAccent
                      : Theme.of(context).colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.dark_mode,
                  ),
                  title: const Text(
                    'Modo Escuro',
                  ),
                  // Se for ThemeMode.system, verificamos o brilho atual do sistema
                  value: themeProvider.themeMode == ThemeMode.system
                      ? MediaQuery.of(context).platformBrightness ==
                          Brightness.dark
                      : themeProvider.isDarkMode,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                  activeColor: isDark
                      ? Colors.greenAccent
                      : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sair da Conta',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await context.read<AuthNotifier>().logout();
                // O Router redirecionará automaticamente
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
