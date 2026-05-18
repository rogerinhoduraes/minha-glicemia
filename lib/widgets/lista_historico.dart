import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/registro_glicemia.dart';
import '../services/analytics_service.dart';
import '../services/glicemia_service.dart';

class ListaHistorico extends StatelessWidget {
  final GlicemiaService service;
  final void Function(RegistroGlicemia) onEditar;

  const ListaHistorico({super.key, required this.service, required this.onEditar});

  static Color nivelCor(NivelGlicemia n) => switch (n) {
    NivelGlicemia.normal    => const Color(0xFF059669),
    NivelGlicemia.alto      => const Color(0xFFD97706),
    NivelGlicemia.muitoAlto => const Color(0xFFDC2626),
  };

  static Color nivelFundo(NivelGlicemia n) => switch (n) {
    NivelGlicemia.normal    => const Color(0xFFECFDF5),
    NivelGlicemia.alto      => const Color(0xFFFFFBEB),
    NivelGlicemia.muitoAlto => const Color(0xFFFEF2F2),
  };

  static String nivelLabel(NivelGlicemia n) => switch (n) {
    NivelGlicemia.normal    => 'Normal',
    NivelGlicemia.alto      => 'Alto',
    NivelGlicemia.muitoAlto => 'Muito alto',
  };

  Future<void> _deletar(BuildContext context, RegistroGlicemia r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apagar registro?',
            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w800)),
        content: Text('${r.refeicao} — ${r.valor} mg/dL'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await service.deletar(r.id!);
      AnalyticsService.logMedicaoExcluida();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              Container(width: 4, height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 10),
              Text('Histórico',
                style: GoogleFonts.nunitoSans(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A))),
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<RegistroGlicemia>>(
              stream: service.ultimosRegistros(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erro: ${snap.error}',
                        style: const TextStyle(color: Color(0xFFEF4444))),
                  );
                }
                final registros = snap.data ?? [];
                if (registros.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.monitor_heart_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Nenhuma medição ainda',
                          style: GoogleFonts.nunitoSans(
                            fontSize: 15, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: registros.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ItemRegistro(
                    registro: registros[i],
                    onEditar: () => onEditar(registros[i]),
                    onDeletar: () => _deletar(context, registros[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRegistro extends StatelessWidget {
  final RegistroGlicemia registro;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  const _ItemRegistro({
    required this.registro,
    required this.onEditar,
    required this.onDeletar,
  });

  @override
  Widget build(BuildContext context) {
    final r    = registro;
    final cor  = ListaHistorico.nivelCor(r.nivel);
    final fundo = ListaHistorico.nivelFundo(r.nivel);
    final label = ListaHistorico.nivelLabel(r.nivel);
    final hora  = DateFormat('HH:mm').format(r.dataHora);
    final data  = DateFormat('dd/MM').format(r.dataHora);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: cor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.refeicao,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text('$data · $hora',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12, color: const Color(0xFF94A3B8))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: fundo, borderRadius: BorderRadius.circular(20)),
                      child: Text(label,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 11, fontWeight: FontWeight.w700, color: cor)),
                    ),
                  ]),
                ],
              ),
            ),
            Text('${r.valor}',
              style: GoogleFonts.nunitoSans(
                fontSize: 36, fontWeight: FontWeight.w900, color: cor)),
            const SizedBox(width: 4),
            Column(
              children: [
                _Acao(icon: Icons.edit_outlined,
                    color: const Color(0xFF2563EB), onTap: onEditar),
                const SizedBox(height: 4),
                _Acao(icon: Icons.delete_outline,
                    color: const Color(0xFFEF4444), onTap: onDeletar),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Acao({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
