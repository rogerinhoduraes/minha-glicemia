import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/registro_glicemia.dart';
import '../services/analytics_service.dart';
import '../services/glicemia_service.dart';
import '../services/pdf_service.dart';

const _kPrimary   = Color(0xFF2563EB);
const _kGradStart = Color(0xFF1E3A8A);

class RelatorioScreen extends StatefulWidget {
  final GlicemiaService service;
  const RelatorioScreen({super.key, required this.service});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  List<RegistroGlicemia>? _registros;
  bool _carregando = true;
  bool _exportando = false;
  bool _erro = false;

  late DateTime _inicio;
  late DateTime _fim;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _fim   = DateTime(hoje.year, hoje.month, hoje.day);
    _inicio = _fim.subtract(const Duration(days: 29));
    AnalyticsService.logTela('relatorio');
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _carregando = true; _erro = false; });
    try {
      final lista = await widget.service.buscarRegistrosPorPeriodo(_inicio, _fim);
      if (mounted) {
        setState(() { _registros = lista; _carregando = false; });
        final dias = _fim.difference(_inicio).inDays + 1;
        AnalyticsService.logRelatorioVisto(dias, lista.length);
      }
    } catch (_) {
      if (mounted) setState(() { _erro = true; _carregando = false; });
    }
  }

  Future<void> _selecionarData({required bool ehInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ehInicio ? _inicio : _fim,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (ehInicio) {
        _inicio = picked;
        if (_inicio.isAfter(_fim)) _fim = _inicio;
      } else {
        _fim = picked;
        if (_fim.isBefore(_inicio)) _inicio = _fim;
      }
    });
    _carregar();
  }

  Future<void> _exportarPdf() async {
    if (_registros == null || _exportando) return;
    setState(() => _exportando = true);
    try {
      final paciente = await widget.service.buscarPaciente();
      final bytes = await PdfService.gerarRelatorio(
        registros: _registros!,
        paciente: paciente,
        inicio: _inicio,
        fim: _fim,
      );
      final fmt = DateFormat('yyyyMMdd');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'glicemia_${fmt.format(_inicio)}_${fmt.format(_fim)}.pdf',
      );
      AnalyticsService.logPdfExportado(_registros!.length);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kGradStart,
        title: const Text('Relatório'),
        actions: [
          if (_exportando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Exportar PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
              onPressed: (_registros != null && _registros!.isNotEmpty) ? _exportarPdf : null,
            ),
        ],
      ),
      body: Column(
        children: [
          _seletorPeriodo(),
          Expanded(child: _corpo()),
        ],
      ),
    );
  }

  // ── Seletor de período ────────────────────────────────────────────────────

  Widget _seletorPeriodo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(children: [
        const Icon(Icons.date_range_outlined, size: 18, color: _kPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: _DataChip(
            prefixo: 'De',
            data: _inicio,
            onTap: () => _selecionarData(ehInicio: true),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFF94A3B8)),
        ),
        Expanded(
          child: _DataChip(
            prefixo: 'Até',
            data: _fim,
            onTap: () => _selecionarData(ehInicio: false),
          ),
        ),
      ]),
    );
  }

  // ── Corpo ─────────────────────────────────────────────────────────────────

  Widget _corpo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    if (_erro) {
      return const Center(
        child: Text('Erro ao carregar dados.',
            style: TextStyle(color: Color(0xFFEF4444))),
      );
    }

    if (_registros == null || _registros!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Nenhuma medição no período selecionado.',
              style: GoogleFonts.nunitoSans(
                  fontSize: 15, color: const Color(0xFF94A3B8)),
              textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final stats = _Estatisticas.calcular(_registros!);
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _secaoPeriodo(stats),
          const SizedBox(height: 12),
          _secaoGrafico(),
          const SizedBox(height: 12),
          _secaoResumo(stats),
          const SizedBox(height: 12),
          _secaoDistribuicao(stats),
          const SizedBox(height: 12),
          _secaoRefeicoes(stats),
        ],
      ),
    );
  }

  // ── Seções de estatísticas ────────────────────────────────────────────────

  Widget _secaoPeriodo(_Estatisticas s) {
    final fmt = DateFormat('dd/MM/yyyy');
    return _Card(
      titulo: 'Período analisado',
      icone: Icons.date_range_outlined,
      children: [
        Row(children: [
          _PillInfo(label: 'Início', valor: fmt.format(_registros!.first.dataHora)),
          const SizedBox(width: 10),
          _PillInfo(label: 'Fim',    valor: fmt.format(_registros!.last.dataHora)),
          const SizedBox(width: 10),
          _PillInfo(label: 'Total',  valor: '${s.total} medições'),
        ]),
      ],
    );
  }

  Widget _secaoResumo(_Estatisticas s) {
    return _Card(
      titulo: 'Resumo geral',
      icone: Icons.summarize_outlined,
      children: [
        Row(children: [
          _StatBox(label: 'Média', valor: '${s.media.round()}', unidade: 'mg/dL',
              cor: _corNivel(_nivelDe(s.media.round()))),
          const SizedBox(width: 10),
          _StatBox(label: 'Menor', valor: '${s.menor}', unidade: 'mg/dL',
              cor: _corNivel(_nivelDe(s.menor))),
          const SizedBox(width: 10),
          _StatBox(label: 'Maior', valor: '${s.maior}', unidade: 'mg/dL',
              cor: _corNivel(_nivelDe(s.maior))),
        ]),
      ],
    );
  }

  Widget _secaoDistribuicao(_Estatisticas s) {
    return _Card(
      titulo: 'Distribuição por nível',
      icone: Icons.pie_chart_outline,
      children: [
        _BarraNivel(label: 'Normal  (≤ 140)', count: s.normal,    total: s.total,
            cor: const Color(0xFF059669), fundo: const Color(0xFFECFDF5)),
        const SizedBox(height: 10),
        _BarraNivel(label: 'Alto  (141–200)',  count: s.alto,      total: s.total,
            cor: const Color(0xFFD97706), fundo: const Color(0xFFFFFBEB)),
        const SizedBox(height: 10),
        _BarraNivel(label: 'Muito alto  (> 200)', count: s.muitoAlto, total: s.total,
            cor: const Color(0xFFDC2626), fundo: const Color(0xFFFEF2F2)),
      ],
    );
  }

  Widget _secaoGrafico() {
    return _Card(
      titulo: 'Evolução das medições',
      icone: Icons.show_chart_outlined,
      children: [
        _GraficoGlicemia(registros: _registros!),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendaItem(cor: Color(0xFF059669), label: 'Normal ≤ 140'),
            SizedBox(width: 14),
            _LegendaItem(cor: Color(0xFFD97706), label: 'Alto 141–200'),
            SizedBox(width: 14),
            _LegendaItem(cor: Color(0xFFDC2626), label: 'Muito alto > 200'),
          ],
        ),
      ],
    );
  }

  Widget _secaoRefeicoes(_Estatisticas s) {
    if (s.mediaPorRefeicao.isEmpty) return const SizedBox.shrink();
    final entradas = s.mediaPorRefeicao.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return _Card(
      titulo: 'Média por refeição',
      icone: Icons.restaurant_menu_outlined,
      children: [
        for (final e in entradas) ...[
          _LinhaRefeicao(nome: e.key, media: e.value),
          if (e != entradas.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NivelGlicemia _nivelDe(int v) {
    if (v <= 140) return NivelGlicemia.normal;
    if (v <= 200) return NivelGlicemia.alto;
    return NivelGlicemia.muitoAlto;
  }

  Color _corNivel(NivelGlicemia n) => switch (n) {
    NivelGlicemia.normal    => const Color(0xFF059669),
    NivelGlicemia.alto      => const Color(0xFFD97706),
    NivelGlicemia.muitoAlto => const Color(0xFFDC2626),
  };
}

// ── Estatísticas ──────────────────────────────────────────────────────────────

class _Estatisticas {
  final int total, normal, alto, muitoAlto, menor, maior;
  final double media;
  final Map<String, double> mediaPorRefeicao;

  const _Estatisticas({
    required this.total, required this.normal, required this.alto,
    required this.muitoAlto, required this.menor, required this.maior,
    required this.media, required this.mediaPorRefeicao,
  });

  factory _Estatisticas.calcular(List<RegistroGlicemia> lista) {
    int norm = 0, alt = 0, mAlto = 0;
    int minV = lista.first.valor, maxV = lista.first.valor, soma = 0;
    final somaRef = <String, int>{};
    final contRef = <String, int>{};

    for (final r in lista) {
      soma += r.valor;
      if (r.valor < minV) minV = r.valor;
      if (r.valor > maxV) maxV = r.valor;
      switch (r.nivel) {
        case NivelGlicemia.normal:    norm++;  break;
        case NivelGlicemia.alto:      alt++;   break;
        case NivelGlicemia.muitoAlto: mAlto++; break;
      }
      somaRef[r.refeicao] = (somaRef[r.refeicao] ?? 0) + r.valor;
      contRef[r.refeicao] = (contRef[r.refeicao] ?? 0) + 1;
    }

    return _Estatisticas(
      total: lista.length, normal: norm, alto: alt, muitoAlto: mAlto,
      menor: minV, maior: maxV, media: soma / lista.length,
      mediaPorRefeicao: {
        for (final k in somaRef.keys) k: somaRef[k]! / contRef[k]!,
      },
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _DataChip extends StatelessWidget {
  final String prefixo;
  final DateTime data;
  final VoidCallback onTap;
  const _DataChip({required this.prefixo, required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(children: [
          Text('$prefixo  ',
            style: GoogleFonts.nunitoSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8))),
          Expanded(
            child: Text(DateFormat('dd/MM/yy').format(data),
              style: GoogleFonts.nunitoSans(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A))),
          ),
          const Icon(Icons.edit_calendar_outlined, size: 14, color: _kPrimary),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final List<Widget> children;
  const _Card({required this.titulo, required this.icone, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 4, height: 22,
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icone, size: 17, color: _kPrimary),
              const SizedBox(width: 6),
              Text(titulo,
                style: GoogleFonts.nunitoSans(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
            ]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, valor, unidade;
  final Color cor;
  const _StatBox(
      {required this.label, required this.valor,
       required this.unidade, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cor.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(label,
            style: GoogleFonts.nunitoSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(valor,
            style: GoogleFonts.nunitoSans(
                fontSize: 26, fontWeight: FontWeight.w900, color: cor)),
          Text(unidade,
            style: GoogleFonts.nunitoSans(
                fontSize: 10, color: const Color(0xFF94A3B8))),
        ]),
      ),
    );
  }
}

class _PillInfo extends StatelessWidget {
  final String label, valor;
  const _PillInfo({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
          style: GoogleFonts.nunitoSans(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: const Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(valor,
          style: GoogleFonts.nunitoSans(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A))),
      ]),
    );
  }
}

class _BarraNivel extends StatelessWidget {
  final String label;
  final int count, total;
  final Color cor, fundo;
  const _BarraNivel(
      {required this.label, required this.count, required this.total,
       required this.cor, required this.fundo});

  @override
  Widget build(BuildContext context) {
    final pct    = total > 0 ? count / total : 0.0;
    final pctStr = '${(pct * 100).round()}%';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
            style: GoogleFonts.nunitoSans(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
          Text('$count  ·  $pctStr',
            style: GoogleFonts.nunitoSans(
                fontSize: 13, fontWeight: FontWeight.w800, color: cor)),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: pct, minHeight: 10,
          backgroundColor: fundo,
          valueColor: AlwaysStoppedAnimation<Color>(cor),
        ),
      ),
    ]);
  }
}

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final String label;
  const _LegendaItem({required this.cor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.nunitoSans(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B))),
    ]);
  }
}

class _GraficoGlicemia extends StatelessWidget {
  final List<RegistroGlicemia> registros;

  static const _kGray  = Color(0xFF94A3B8);
  static const _padL   = 46.0;
  static const _chartH = 158.0;

  const _GraficoGlicemia({required this.registros});

  @override
  Widget build(BuildContext context) {
    final n = registros.length;
    final maxVal = n > 0
        ? registros.map((r) => r.valor).reduce((a, b) => a > b ? a : b)
        : 240;
    final yMax = (maxVal > 220 ? maxVal + 30 : 240).toDouble();
    const yMin = 50.0;

    double yPct(double v) => 1.0 - (v - yMin) / (yMax - yMin);
    final labelStyle = GoogleFonts.nunitoSans(
        fontSize: 9.5, fontWeight: FontWeight.w600, color: _kGray);
    final fmt = DateFormat('dd/MM');

    return SizedBox(
      height: _chartH + 30,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Y-axis labels ────────────────────────────────────────────────
          SizedBox(
            width: _padL,
            height: _chartH + 8,
            child: Stack(
              children: [
                for (final v in [60, 100, 140, 200, 240])
                  if (v >= yMin && v <= yMax)
                    Positioned(
                      top: 8 + yPct(v.toDouble()) * _chartH - 7,
                      right: 4,
                      child: Text('$v', style: labelStyle),
                    ),
              ],
            ),
          ),
          // ── Chart + X labels ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _chartH + 8,
                  child: LayoutBuilder(
                    builder: (_, constraints) => CustomPaint(
                      size: Size(constraints.maxWidth, _chartH + 8),
                      painter: _ChartPainter(
                          registros: registros, yMin: yMin, yMax: yMax),
                    ),
                  ),
                ),
                // ── X labels ──────────────────────────────────────────────
                if (n >= 2)
                  SizedBox(
                    height: 20,
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        final w = constraints.maxWidth;
                        double cx(int i) => n == 1 ? w / 2 : i * w / (n - 1);
                        return Stack(children: [
                          Positioned(left: cx(0),
                              child: Text(fmt.format(registros.first.dataHora), style: labelStyle)),
                          if (n >= 3)
                            Positioned(left: (cx(n ~/ 2) - 15).clamp(0, w - 30),
                                child: Text(fmt.format(registros[n ~/ 2].dataHora), style: labelStyle)),
                          Positioned(right: 0,
                              child: Text(fmt.format(registros.last.dataHora), style: labelStyle)),
                        ]);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<RegistroGlicemia> registros;
  final double yMin, yMax;

  static const _kNormal = Color(0xFF059669);
  static const _kAlto   = Color(0xFFD97706);
  static const _kMuito  = Color(0xFFDC2626);
  static const _kGray   = Color(0xFF94A3B8);

  const _ChartPainter(
      {required this.registros, required this.yMin, required this.yMax});

  @override
  void paint(Canvas canvas, Size size) {
    const padT = 8.0;
    final w = size.width;
    final h = size.height - padT;
    final n = registros.length;
    if (n == 0) return;

    double cx(int i) => n == 1 ? w / 2 : i * w / (n - 1);
    double cy(double v) => padT + h - h * ((v - yMin) / (yMax - yMin));

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, padT, w, h));

    // Zones
    void fillZone(double y1, double y2, Color c) => canvas.drawRect(
        Rect.fromLTRB(0, cy(y2.clamp(yMin, yMax)), w, cy(y1.clamp(yMin, yMax))),
        Paint()..color = c.withValues(alpha: 0.08));
    fillZone(yMin, 140, _kNormal);
    fillZone(140, 200, _kAlto);
    fillZone(200, yMax, _kMuito);

    // Dashed reference lines
    void dashed(double yVal, Color c) {
      final y = cy(yVal);
      final p = Paint()..color = c.withValues(alpha: 0.55)..strokeWidth = 1.0;
      double x = 0;
      while (x < w) {
        canvas.drawLine(Offset(x, y), Offset((x + 6).clamp(0, w), y), p);
        x += 10;
      }
    }
    dashed(140, _kNormal);
    dashed(200, _kMuito);

    // Connecting line
    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = Offset(cx(i), cy(registros[i].valor.toDouble()));
      if (i == 0) { path.moveTo(p.dx, p.dy); } else { path.lineTo(p.dx, p.dy); }
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = _kGray.withValues(alpha: 0.35)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);

    // Colored dots
    final dotR = n > 60 ? 2.5 : 4.0;
    for (var i = 0; i < n; i++) {
      final reg = registros[i];
      final cor = switch (reg.nivel) {
        NivelGlicemia.normal    => _kNormal,
        NivelGlicemia.alto      => _kAlto,
        NivelGlicemia.muitoAlto => _kMuito,
      };
      final center = Offset(cx(i), cy(reg.valor.toDouble()));
      canvas.drawCircle(center, dotR, Paint()..color = cor);
      canvas.drawCircle(center, dotR,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.registros != registros || old.yMin != yMin || old.yMax != yMax;
}

class _LinhaRefeicao extends StatelessWidget {
  final String nome;
  final double media;
  const _LinhaRefeicao({required this.nome, required this.media});

  Color get _cor {
    final v = media.round();
    if (v <= 140) return const Color(0xFF059669);
    if (v <= 200) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(nome,
          style: GoogleFonts.nunitoSans(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: const Color(0xFF334155))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _cor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text('${media.round()} mg/dL',
          style: GoogleFonts.nunitoSans(
              fontSize: 13, fontWeight: FontWeight.w800, color: _cor)),
      ),
    ]);
  }
}
