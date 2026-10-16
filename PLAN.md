# Minha Glicemia — plano

## Registrar medições {#registro}
tech: HomeScreen + FormRegistro + ListaHistorico + GlicemiaService
files: [lib/screens/home_screen.dart, lib/widgets/form_registro.dart, lib/widgets/lista_historico.dart, lib/services/glicemia_service.dart, lib/models/**, test/**]
- [x] Testes dos models e do GlicemiaService {#testes}
  by: claude
links: [anuncios]

## Gerar relatório em PDF {#relatorio}
tech: RelatorioScreen + PdfService
files: [lib/screens/relatorio_screen.dart, lib/services/pdf_service.dart]
needs: [registro]
links: [anuncios]

## Cadastrar paciente e refeições {#cadastros}
tech: PacienteScreen, RefeicaoScreen, lembretes via NotificacaoService
files: [lib/screens/paciente_screen.dart, lib/screens/refeicao_screen.dart, lib/services/notificacao_service.dart]
- [x] Trocar onReorder obsoleto por onReorderItem {#onreorder}
  by: claude

## Entrar e gerenciar a conta {#conta}
tech: AuthService (e-mail, Google, Apple), exclusão de conta
files: [lib/screens/login_screen.dart, lib/screens/main_screen.dart, lib/services/auth_service.dart, firestore.rules]
- [x] Atualizar login Google para google_sign_in 7 {#google-sign-in-7}
  by: claude
- [ ] Configurar login Google no iOS (CLIENT_ID + URL scheme) {#google-ios}
  from: agent

## Mostrar anúncios {#anuncios}
tech: google_mobile_ads — UMP (consentimento), ATT, banner, intersticial
files: [lib/services/ads_service.dart, lib/widgets/ad_banner.dart, lib/main.dart]
- [~] Pedir consentimento (UMP) antes de carregar anúncios {#consentimento}
  by: claude
- [~] Mostrar intersticial ao exportar PDF {#intersticial}
  by: claude
- [~] Banner único na tela principal (Início + Relatório) {#banner-telas}
  by: claude
- [x] app-ads.txt publicado em rogerinhoduraes.github.io {#app-ads}
- [x] Atualizar Firebase (core 4 / Firestore 6) e AdMob 9 {#deps}
  by: claude

## Publicar nas lojas {#lojas}
tech: assinatura Android, entitlements/ATT/SKAdNetwork iOS, assets de loja
files: [android/**, ios/**, docs/**, pubspec.yaml]
- [ ] Restaurar CODE_SIGN_ENTITLEMENTS antes de enviar à App Store {#entitlements}
  from: agent
- [x] Atualizar Gradle 9.3.1, AGP 9.1.0 e Kotlin 2.4.0 {#gradle}
  by: claude

## decisions
- 2026-10-16: intersticial só ao exportar PDF (antes do compartilhamento, cooldown de 3 min) — não após salvar medição, que é a ação central e frequente.
- 2026-10-16: banner único no MainScreen (cobre Início e Relatório); IndexedStack manteria dois banners montados, um invisível.
