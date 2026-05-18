import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/registro_glicemia.dart';

class AnalyticsService {
  static final _fa = FirebaseAnalytics.instance;

  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _fa);

  // ── Autenticação ──────────────────────────────────────────────────────────
  static void logLogin(String metodo) =>
      _fa.logLogin(loginMethod: metodo).ignore();

  static void logCadastro(String metodo) =>
      _fa.logSignUp(signUpMethod: metodo).ignore();

  // ── Telas ─────────────────────────────────────────────────────────────────
  static void logTela(String nome) =>
      _fa.logScreenView(screenName: nome).ignore();

  // ── Medições ──────────────────────────────────────────────────────────────
  static void logMedicaoSalva(RegistroGlicemia r) =>
      _fa.logEvent(name: 'medicao_salva', parameters: {
        'valor': r.valor,
        'nivel': r.nivel.name,
        'refeicao': r.refeicao,
      }).ignore();

  static void logMedicaoEditada(RegistroGlicemia r) =>
      _fa.logEvent(name: 'medicao_editada', parameters: {
        'valor': r.valor,
        'nivel': r.nivel.name,
        'refeicao': r.refeicao,
      }).ignore();

  static void logMedicaoExcluida() =>
      _fa.logEvent(name: 'medicao_excluida').ignore();

  // ── Relatório ─────────────────────────────────────────────────────────────
  static void logRelatorioVisto(int dias, int totalRegistros) =>
      _fa.logEvent(name: 'relatorio_visto', parameters: {
        'periodo_dias': dias,
        'total_registros': totalRegistros,
      }).ignore();

  static void logPdfExportado(int totalRegistros) =>
      _fa.logEvent(name: 'pdf_exportado', parameters: {
        'total_registros': totalRegistros,
      }).ignore();

  // ── Refeições ─────────────────────────────────────────────────────────────
  static void logRefeicaoAdicionada() =>
      _fa.logEvent(name: 'refeicao_adicionada').ignore();

  static void logRefeicaoRemovida() =>
      _fa.logEvent(name: 'refeicao_removida').ignore();

  static void logLembreteAlterado({required bool ativo, required String nome}) =>
      _fa.logEvent(name: 'lembrete_alterado', parameters: {
        'ativo': ativo ? 1 : 0,
        'refeicao': nome,
      }).ignore();

  // ── Paciente ──────────────────────────────────────────────────────────────
  static void logPerfilSalvo() =>
      _fa.logEvent(name: 'perfil_salvo').ignore();

  // ── Usuário ───────────────────────────────────────────────────────────────
  static void setUserId(String uid) =>
      _fa.setUserId(id: uid).ignore();
}
