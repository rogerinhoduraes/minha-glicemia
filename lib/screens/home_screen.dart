import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/registro_glicemia.dart';
import '../services/analytics_service.dart';
import '../services/glicemia_service.dart';
import '../widgets/form_registro.dart';
import '../widgets/lista_historico.dart';

const _kHeader = Color(0xFF1A1E2E);

class HomeScreen extends StatefulWidget {
  final GlicemiaService service;
  const HomeScreen({super.key, required this.service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RegistroGlicemia? _editando;

  @override
  void initState() {
    super.initState();
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
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: FormRegistro(
                      service: widget.service,
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
                      service: widget.service,
                      onEditar: _iniciarEdicao,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      stretch: true,
      backgroundColor: _kHeader,
      title: const Text('Minha Glicemia'),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _HeaderWidget(service: widget.service),
      ),
    );
  }
}

class _HeaderWidget extends StatelessWidget {
  final GlicemiaService service;
  const _HeaderWidget({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _kHeader),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Minha Glicemia',
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
                  final cor   = _glicoseCor(r.nivel);
                  final label = _glicoseLabel(r.nivel);
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
                        Text('· ${r.refeicao}  · $label',
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
    NivelGlicemia.normal    => const Color(0xFF34D399),
    NivelGlicemia.alto      => const Color(0xFFFBBF24),
    NivelGlicemia.muitoAlto => const Color(0xFFF87171),
  };

  String _glicoseLabel(NivelGlicemia nivel) => switch (nivel) {
    NivelGlicemia.normal    => 'Normal',
    NivelGlicemia.alto      => 'Alto',
    NivelGlicemia.muitoAlto => 'Muito alto',
  };
}
