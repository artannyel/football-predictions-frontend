# Palpites Futebol ⚽

O **Palpites Futebol** é um aplicativo desenvolvido em Flutter para a gestão e participação em ligas de palpites de futebol. O projeto oferece uma experiência completa para usuários acompanharem partidas, gerenciarem suas ligas, visualizarem rankings e enviarem seus palpites em tempo real.

## 🚀 Funcionalidades

- **Gestão de Ligas**: Crie ou entre em ligas de palpites.
- **Palpites em Tempo Real**: Envie e acompanhe seus palpites para partidas de diversas competições.
- **Rankings**: Visualize a sua posição e a de seus amigos em tempo real.
- **Chat da Liga**: Comunique-se com outros participantes diretamente no aplicativo.
- **Notificações Push**: Receba atualizações sobre partidas, resultados e convites.
- **Painel Administrativo**: Ferramentas para gerenciamento de insígnias (badges), logs e partidas.

## 🛠️ Tecnologias Utilizadas

- **Framework**: [Flutter](https://flutter.dev/)
- **Gerenciamento de Estado**: [Provider](https://pub.dev/packages/provider)
- **Navegação**: [GoRouter](https://pub.dev/packages/go_router)
- **Comunicação API**: [Dio](https://pub.dev/packages/dio)
- **Backend**: [Firebase](https://firebase.google.com/) (Auth, Firestore)
- **Notificações**: [OneSignal](https://onesignal.com/)
- **Imagens**: [Cached Network Image](https://pub.dev/packages/cached_network_image) e [Flutter SVG](https://pub.dev/packages/flutter_svg)

## 🏗️ Arquitetura

O projeto utiliza uma arquitetura modular baseada em funcionalidades (features), separando as responsabilidades em duas camadas principais:

- **Core (`lib/core/`)**: Contém a infraestrutura compartilhada, como autenticação global, configuração de rotas, widgets genéricos e utilitários.
- **Features (`lib/features/`)**: Cada diretório representa um módulo funcional independente (ex: `auth`, `home`, `predictions`, `ranking`, `admin`).

## 💻 Como Executar o Projeto

### Pré-requisitos

- Flutter SDK (versão compatível com o `pubspec.yaml`)
- Projeto Firebase configurado e arquivos de configuração (`google-services.json` ou `firebase_options.dart`) instalados.

### Ambientes (Flavors)

O projeto suporta múltiplos ambientes através de diferentes pontos de entrada:

| Ambiente | Comando para Execução |
| :--- | :--- |
| **Desenvolvimento** | `flutter run -t lib/main_dev.dart` |
| **Produção** | `flutter run -t lib/main_prod.dart` |
| **Administração** | `flutter run -t lib/main_admin.dart` |

### Outros Comandos Úteis

```bash
# Instalar dependências
flutter pub get

# Executar análise de código (Lint)
flutter analyze

# Executar testes unitários
flutter test

# Build para Web (Produção)
flutter build web -t lib/main_prod.dart

# Build APK (Produção)
flutter build apk -t lib/main_prod.dart
```

## 📝 Convenções de Desenvolvimento

- **Padronização**: O código segue as regras definidas no `analysis_options.yaml` (Flutter Lints).
- **Nomenclatura**: Arquivos em `lower_snake_case` e classes em `UpperCamelCase`.
- **Rotas**: Todas as rotas devem ser declaradas centralizadamente em `lib/core/navigation/app_router.dart`.
- **Segurança**: Variáveis sensíveis (como IDs de API) devem ser passadas via `--dart-define` e nunca commitadas diretamente no código.

---
Desenvolvido com ❤️ para fãs de futebol.
