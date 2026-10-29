import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const fonteFaixasTitulo =
    'Diretriz da Sociedade Brasileira de Diabetes, ed. 2026 — Diagnóstico de diabetes mellitus';
const fonteFaixasUrl =
    'https://diretriz.diabetes.org.br/diagnostico-de-diabetes-mellitus/';
const fonteFaixasAviso =
    'Faixas de referência informativas. Não substituem a avaliação do seu médico, '
    'que pode definir metas diferentes para você.';

/// Link "Faixas e fonte" que abre a explicação das faixas com a citação.
class FonteFaixasLink extends StatelessWidget {
  const FonteFaixasLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => mostrarFonteFaixas(context),
      icon: const Icon(Icons.info_outline, size: 16),
      label: Text('Faixas e fonte',
        style: GoogleFonts.nunitoSans(fontSize: 13, fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2563EB),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

Future<void> mostrarFonteFaixas(BuildContext context) {
  Widget faixa(Color cor, String nome, String valores) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(width: 10, height: 10,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Text(nome, style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w700)),
      const Spacer(),
      Text(valores, style: GoogleFonts.nunitoSans(fontSize: 15)),
    ]),
  );

  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faixas de glicemia',
              style: GoogleFonts.nunitoSans(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            faixa(const Color(0xFF059669), 'Normal', '< 140 mg/dL'),
            faixa(const Color(0xFFD97706), 'Alto', '140–199 mg/dL'),
            faixa(const Color(0xFFDC2626), 'Muito alto', '≥ 200 mg/dL'),
            const SizedBox(height: 16),
            Text('Fonte', style: GoogleFonts.nunitoSans(fontSize: 13,
              fontWeight: FontWeight.w800, color: const Color(0xFF6B6860))),
            const SizedBox(height: 4),
            Text('$fonteFaixasTitulo (Tabela 1).',
              style: GoogleFonts.nunitoSans(fontSize: 14)),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(fonteFaixasUrl),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('diretriz.diabetes.org.br'),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
            const SizedBox(height: 8),
            Text(fonteFaixasAviso,
              style: GoogleFonts.nunitoSans(fontSize: 13, color: const Color(0xFF6B6860))),
          ],
        ),
      ),
    ),
  );
}
