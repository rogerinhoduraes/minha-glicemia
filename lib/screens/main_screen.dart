import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ads_service.dart';
import '../services/auth_service.dart';
import '../services/glicemia_service.dart';
import '../widgets/ad_banner.dart';
import 'home_screen.dart';
import 'paciente_screen.dart';
import 'refeicao_screen.dart';
import 'relatorio_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _service = GlicemiaService();
  final _auth    = AuthService();
  int _tabIndex  = 0;

  @override
  void initState() {
    super.initState();
    _service.garantirRefeicoesIniciais();
    WidgetsBinding.instance.addPostFrameCallback((_) => AdsService.init());
  }

  void _onTabTap(int index) {
    if (index == 2) {
      _abrirMais();
      setState(() {}); // keep selection on current tab
      return;
    }
    setState(() => _tabIndex = index);
  }

  void _abrirMais() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAFAF8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MaisSheet(
        service: _service,
        onSignOut: () => _auth.signOut(),
        onDeleteAccount: _excluirConta,
      ),
    );
  }

  Future<void> _excluirConta() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Todos os seus registros, refeições e dados do paciente serão '
          'apagados permanentemente. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
              style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await _auth.deleteAccount(_service.deletarTodosDados);
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(
        e.code == 'requires-recent-login'
            ? 'Por segurança, saia, entre novamente e repita a exclusão.'
            : 'Não foi possível excluir a conta. Tente novamente.')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Não foi possível excluir a conta. Tente novamente.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                HomeScreen(service: _service),
                RelatorioScreen(service: _service),
              ],
            ),
          ),
          const AdBanner(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _onTabTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Relatório',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}

class _MaisSheet extends StatelessWidget {
  final GlicemiaService service;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  const _MaisSheet({
    required this.service,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E0D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
              title: Text('Dados do Paciente',
                style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PacienteScreen(service: service)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu_outlined, color: Color(0xFF2563EB)),
              title: Text('Tipos de Refeição',
                style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RefeicaoScreen(service: service)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF2563EB)),
              title: Text('Política de Privacidade',
                style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                launchUrl(
                  Uri.parse('https://rogerinhoduraes.github.io/minha-glicemia/privacy_policy.html'),
                  mode: LaunchMode.externalApplication);
              },
            ),
            if (AdsService.precisaOpcoesPrivacidade)
              ListTile(
                leading: const Icon(Icons.tune_outlined, color: Color(0xFF2563EB)),
                title: Text('Privacidade dos anúncios',
                  style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  AdsService.abrirOpcoesPrivacidade();
                },
              ),
            const Divider(indent: 16, endIndent: 16, height: 24),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: Text('Sair',
                style: GoogleFonts.nunitoSans(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444))),
              onTap: () {
                Navigator.pop(context);
                onSignOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Color(0xFFEF4444)),
              title: Text('Excluir conta',
                style: GoogleFonts.nunitoSans(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: const Color(0xFFEF4444))),
              onTap: () {
                Navigator.pop(context);
                onDeleteAccount();
              },
            ),
          ],
        ),
      ),
    );
  }
}
