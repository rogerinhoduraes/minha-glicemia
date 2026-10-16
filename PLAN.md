# Minha Glicemia — plano

## Registrar medições {#registro}
tech: HomeScreen + FormRegistro + ListaHistorico + GlicemiaService
files: [lib/screens/home_screen.dart, lib/widgets/form_registro.dart, lib/widgets/lista_historico.dart, lib/services/glicemia_service.dart, lib/models/**, test/**]
- [x] Testes dos models e do GlicemiaService {#testes}
  by: claude
- [x] Corrigir erro do seletor de refeição e histórico espremido em telas baixas {#layout-home}
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
- [x] Impedir exclusão das refeições padrão {#refeicoes-padrao}
  by: claude
- [x] Alinhar sino e ícone de ordem na lista de refeições {#icones-refeicao}
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
- [~] Vender a remoção de anúncios (compra única) e aceitar cupons das lojas {#remover-anuncios}
  by: claude
  tech: in_app_purchase, produto `remover_anuncios`, códigos de oferta (Apple) e promocionais (Google)

## Publicar nas lojas {#lojas}
tech: assinatura Android, entitlements/ATT/SKAdNetwork iOS, assets de loja
files: [android/**, ios/**, docs/**, pubspec.yaml]
- [x] Restaurar CODE_SIGN_ENTITLEMENTS antes de enviar à App Store {#entitlements}
  by: claude
- [x] Atualizar Gradle 9.3.1, AGP 9.1.0 e Kotlin 2.4.0 {#gradle}
  by: claude
- [x] Assinar iOS com o time S75AESUE2H e ativar o provedor Apple no Firebase {#ios-time}
  by: claude
- [x] Criar o app no App Store Connect e enviar o build 1.0.0 (1) {#asc-build1}
  by: claude
- [~] Preencher a ficha da App Store (capturas iPhone e iPad, textos, privacidade, conta demo) {#asc-ficha}
  by: claude
  tech: feito textos, categoria, idade, preço, privacidade; faltam capturas 6,9" e iPad 13" (docs/store_assets/ios), enviar build 1.0.0 (2), captura da compra e enviar para revisão
- [ ] Transferir o app Android da conta pessoal para a Novo Consultoria (4810291150440712710) {#play-transfer}
  from: agent

## decisions
- 2026-10-16: intersticial só ao exportar PDF (antes do compartilhamento, cooldown de 3 min) — não após salvar medição, que é a ação central e frequente.
- 2026-10-16: banner único no MainScreen (cobre Início e Relatório); IndexedStack manteria dois banners montados, um invisível.
- 2026-10-16: remoção de anúncios é compra única (não assinatura), vinculada à conta da loja (Apple ID / conta Google) e restaurada pela loja — sem validação em servidor.
- 2026-10-16: cupons de isenção usam os códigos das lojas (oferta na Apple, promocionais no Google); cupom próprio no app violaria a diretriz 3.1.1 da Apple.
