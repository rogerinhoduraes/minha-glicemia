# Minha Glicemia

App Flutter para monitoramento pessoal de glicemia. Registre medições, associe-as a refeições e acompanhe o histórico em tempo real — com sincronização via Firebase e suporte a Android e iOS.

---

## Funcionalidades

- Registro de medições de glicemia (mg/dL) associadas a tipos de refeição
- Classificação automática do nível: **Normal** (≤ 140), **Alto** (141–200), **Muito alto** (> 200)
- Histórico em tempo real com edição e exclusão de registros
- Relatório com seleção de período (padrão: últimos 30 dias) — gráfico de evolução com zonas coloridas por nível, média, menor/maior valor, distribuição e média por refeição
- Exportação de PDF diagramado com resumo estatístico e histórico completo
- Gestão de tipos de refeição personalizados com reordenação por arrastar
- Horário definível por tipo de refeição (ex: "Em jejum — 07:00")
- Lembretes push diários por refeição — ativar/desativar individualmente
- Perfil do paciente (nome, peso, data de nascimento / idade calculada)
- Autenticação com Google e Facebook
- Banner AdMob adaptativo
- Tema Material 3, localização pt-BR, fonte Nunito Sans

---

## Stack

| Camada | Tecnologia |
|---|---|
| UI | Flutter 3 · Material 3 · Google Fonts (Nunito Sans) |
| Autenticação | Firebase Auth · Google Sign-In · Facebook Auth |
| Banco de dados | Cloud Firestore |
| Anúncios | Google Mobile Ads (AdMob) |
| PDF / Impressão | `pdf` · `printing` |
| Notificações | `flutter_local_notifications` · `timezone` |
| Utilitários | `intl` (formatação de datas) |
| Build | flutter_launcher_icons · flutter_native_splash |

---

## Estrutura do projeto

```
lib/
├── main.dart                      # Bootstrap, tema e roteamento por auth state
├── firebase_options.dart          # Config gerada pelo FlutterFire CLI
├── models/
│   ├── paciente.dart              # Paciente (nome, peso, dataNascimento, idade)
│   ├── registro_glicemia.dart     # RegistroGlicemia + enum NivelGlicemia
│   └── tipo_refeicao.dart         # TipoRefeicao (nome, ordem, horario, lembreteAtivo)
├── services/
│   ├── auth_service.dart          # Login Google/Facebook, logout
│   ├── glicemia_service.dart      # CRUD registros, perfil, refeições (Firestore)
│   ├── notificacao_service.dart   # Agendamento de lembretes push diários
│   └── pdf_service.dart           # Geração de PDF do relatório
├── screens/
│   ├── login_screen.dart          # Tela de autenticação
│   ├── home_screen.dart           # Tela principal (form + histórico)
│   ├── paciente_screen.dart       # Edição de perfil do paciente
│   ├── refeicao_screen.dart       # Gerenciamento de tipos de refeição
│   └── relatorio_screen.dart      # Relatório com período e exportação PDF
└── widgets/
    ├── form_registro.dart         # Formulário de nova medição / edição
    ├── lista_historico.dart       # Lista em tempo real dos últimos registros
    └── ad_banner.dart             # Banner AdMob adaptativo
```

Consulte [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) para o modelo de dados do Firestore e o fluxo de autenticação.

---

## Configuração do ambiente

### Pré-requisitos

- Flutter SDK ≥ 3.x
- Dart SDK ≥ 3.11.5
- Conta Firebase (projeto criado)
- Conta AdMob (app registrado)
- App registrado no Google Cloud Console (OAuth) e no Facebook Developers

### 1. Clone e instale dependências

```bash
git clone <url-do-repo>
cd minha_glicemia
flutter pub get
```

### 2. Firebase

1. Instale o FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Conecte ao seu projeto Firebase:
   ```bash
   flutterfire configure
   ```
   Isso gera `lib/firebase_options.dart` e adiciona `google-services.json` (Android) e `GoogleService-Info.plist` (iOS).

3. No console do Firebase, ative os provedores de autenticação: **Google** e **Facebook**.

4. Publique as regras do Firestore (`firestore.rules`):
   ```bash
   firebase deploy --only firestore:rules
   ```

### 3. Google Sign-In

- **Android**: o `SHA-1` do certificado de debug/release deve estar registrado no Firebase Console → Configurações do projeto → Seus apps → Android.
- **iOS**: adicione `CFBundleURLSchemes` no `Info.plist` com o `REVERSED_CLIENT_ID` do `GoogleService-Info.plist`.

### 4. Facebook Login

- Crie um app em [developers.facebook.com](https://developers.facebook.com).
- **Android**: adicione `facebook_app_id`, `fb_login_protocol_scheme` e `facebook_client_token` no `AndroidManifest.xml`.
- **iOS**: configure `CFBundleURLSchemes`, `FacebookAppID` e `FacebookClientToken` no `Info.plist`.

### 5. AdMob

Substitua os IDs de teste em [lib/widgets/ad_banner.dart](lib/widgets/ad_banner.dart) pelos IDs de produção do seu app:

```dart
const _adUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
const _adUnitIdIos     = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
```

### 6. Ícone e splash screen

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## Executando o app

```bash
# Debug
flutter run

# Release Android
flutter build apk --release

# Release iOS
flutter build ipa --release
```

---

## Tópicos conhecidos

| Item | Status |
|---|---|
| IDs do AdMob ainda são de teste | Substituir antes de publicar |
| Regras do Firestore escopadas por UID | Já aplicadas — ver `firestore.rules` |
| Histórico limitado a 10 registros | Comportamento intencional para app simples |
| Login anônimo no startup | Silencioso — dados não migram se usuário fizer login depois; ver `ARCHITECTURE.md` |
| Lembretes push (Android 12+) | Requerem permissão `POST_NOTIFICATIONS` solicitada em tempo de execução |

---

## Changelog

Ver [CHANGELOG.md](CHANGELOG.md).
