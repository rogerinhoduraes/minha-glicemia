import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/registro_glicemia.dart';
import '../services/auth_service.dart';
import '../services/glicemia_service.dart';
import '../widgets/ad_banner.dart';
import '../widgets/form_registro.dart';
import '../widgets/lista_historico.dart';
import '../services/analytics_service.dart';
import 'paciente_screen.dart';
import 'refeicao_screen.dart';
import 'relatorio_screen.dart';

const _gradStart = Color(0xFF1E3A8A);
const _gradEnd   = Color(0xFF2563EB);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = GlicemiaService();
  final _auth    = AuthService();
  RegistroGlicemia? _editando;

  @override
  void initState() {
    super.initState();
    _service.garantirRefeicoesIniciais();
    AnalyticsService.logTela('home');
  }

  void _iniciarEdicao(RegistroGlicemia r) => setState(() => _editando = r);
  void _cancelarEdicao()                  => setState(() => _editando = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: FormRegistro(
                      service: _service,
                      editando: _editando,
                      onCancelarEdicao: _cancelarEdicao,
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: ListaHistorico(
                      service: _service,
                      onEditar: _iniciarEdicao,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const AdBanner(),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: _gradStart,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _GradientHeader(service: _service),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (v) {
            if (v == 'paciente') {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => PacienteScreen(service: _service)));
            } else if (v == 'refeicoes') {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => RefeicaoScreen(service: _service)));
            } else if (v == 'relatorio') {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => RelatorioScreen(service: _service)));
            } else if (v == 'sair') {
              _auth.signOut();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'paciente', child: ListTile(
              leading: Icon(Icons.person_outline), title: Text('Dados do Paciente'),
              contentPadding: EdgeInsets.zero)),
            PopupMenuItem(value: 'refeicoes', child: ListTile(
              leading: Icon(Icons.restaurant_menu), title: Text('Tipos de Refeição'),
              contentPadding: EdgeInsets.zero)),
            PopupMenuItem(value: 'relatorio', child: ListTile(
              leading: Icon(Icons.bar_chart_outlined), title: Text('Relatório'),
              contentPadding: EdgeInsets.zero)),
            PopupMenuDivider(),
            PopupMenuItem(value: 'sair', child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Sair', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero)),
          ],
        ),
      ],
    );
  }
}

class _GradientHeader extends StatelessWidget {
  final GlicemiaService service;
  const _GradientHeader({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradStart, _gradEnd],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 80, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('🩸 Minha Glicemia',
                style: GoogleFonts.nunitoSans(
                  fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 10),
              StreamBuilder<List<RegistroGlicemia>>(
                stream: service.ultimosRegistros(limite: 1),
                builder: (ctx, snap) {
                  final r = snap.data?.firstOrNull;
                  if (r == null) {
                    return Text('Nenhuma medição ainda',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13, color: Colors.white60));
                  }
                  final cor = _glicoseCor(r.nivel);
                  return Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(children: [
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text('${r.valor} mg/dL',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 15, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                        const SizedBox(width: 6),
                        Text('· ${r.refeicao}',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 13, color: Colors.white70)),
                      ]),
                    ),
                  ]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _glicoseCor(NivelGlicemia nivel) => switch (nivel) {
    NivelGlicemia.normal   => const Color(0xFF34D399),
    NivelGlicemia.alto     => const Color(0xFFFBBF24),
    NivelGlicemia.muitoAlto => const Color(0xFFF87171),
  };
}
