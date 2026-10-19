import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/paciente.dart';
import '../models/registro_glicemia.dart';
import '../widgets/fonte_faixas.dart';

class PdfService {
  // ── Cores ─────────────────────────────────────────────────────────────────
  static final _azulEscuro   = PdfColor.fromHex('#1E3A8A');
  static final _azul         = PdfColor.fromHex('#2563EB');
  static final _cinzaFundo   = PdfColor.fromHex('#F8FAFC');
  static final _cinzaBorda   = PdfColor.fromHex('#E2E8F0');
  static final _cinza        = PdfColor.fromHex('#64748B');
  static final _texto        = PdfColor.fromHex('#0F172A');
  static final _azulClaro    = PdfColor.fromHex('#93C5FD');

  static final _verde        = PdfColor.fromHex('#059669');
  static final _verdeClaro   = PdfColor.fromHex('#ECFDF5');
  static final _verdeBorda   = PdfColor.fromHex('#A7F3D0');

  static final _laranja      = PdfColor.fromHex('#D97706');
  static final _laranjaClaro = PdfColor.fromHex('#FFFBEB');
  static final _laranjaBorda = PdfColor.fromHex('#FDE68A');

  static final _vermelho     = PdfColor.fromHex('#DC2626');
  static final _vermelhoClaro = PdfColor.fromHex('#FEF2F2');
  static final _vermelhoBorda = PdfColor.fromHex('#FECACA');

  static final _fmtData  = DateFormat('dd/MM/yyyy');
  static final _fmtHora  = DateFormat('HH:mm');
  static final _fmtTs    = DateFormat("dd/MM/yyyy 'às' HH:mm");

  // ── API pública ───────────────────────────────────────────────────────────

  static Future<Uint8List> gerarRelatorio({
    required List<RegistroGlicemia> registros,
    Paciente? paciente,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final doc = pw.Document(
      title: 'Relatório de Glicemia',
      author: 'Minha Glicemia',
    );

    final bold    = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();
    final periodo = '${_fmtData.format(inicio)} – ${_fmtData.format(fim)}';
    final gerado  = _fmtTs.format(DateTime.now());

    // Página 1 — Resumo
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => _paginaResumo(registros, paciente, periodo, gerado, bold, regular),
    ));

    // Páginas 2+ — Histórico
    if (registros.isNotEmpty) {
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 16, 28, 24),
        header: (ctx) => _headerHistorico(periodo, ctx.pageNumber, bold, regular),
        footer: (ctx) => _rodape(ctx.pageNumber + 1, regular),
        build: (_)   => [_tabelaHistorico(registros, bold, regular)],
      ));
    }

    return doc.save();
  }

  // ── Página de resumo ──────────────────────────────────────────────────────

  static pw.Widget _paginaResumo(
    List<RegistroGlicemia> registros,
    Paciente? paciente,
    String periodo,
    String gerado,
    pw.Font bold,
    pw.Font regular,
  ) {
    final stats = registros.isEmpty ? null : _calcularStats(registros);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _headerPrincipal(periodo, gerado, bold, regular),
        pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                if (paciente != null) ...[
                  _cardPaciente(paciente, bold, regular),
                  pw.SizedBox(height: 16),
                ],
                if (stats == null)
                  pw.Center(
                    child: pw.Text('Nenhuma medição no período.',
                      style: pw.TextStyle(font: regular, fontSize: 12, color: _cinza)),
                  )
                else ...[
                  _tituloSecao('Resumo Geral', bold),
                  pw.SizedBox(height: 10),
                  _secaoResumo(stats, bold, regular),
                  pw.SizedBox(height: 18),
                  _tituloSecao('Distribuição por Nível', bold),
                  pw.SizedBox(height: 10),
                  _secaoDistribuicao(stats, bold, regular),
                  pw.SizedBox(height: 18),
                  _tituloSecao('Média por Refeição', bold),
                  pw.SizedBox(height: 10),
                  _secaoRefeicoes(stats, bold, regular),
                ],
              ],
            ),
          ),
        ),
        _rodape(1, regular),
      ],
    );
  }

  // ── Cabeçalho principal ───────────────────────────────────────────────────

  static pw.Widget _headerPrincipal(
      String periodo, String gerado, pw.Font bold, pw.Font regular) {
    return pw.Container(
      color: _azulEscuro,
      padding: const pw.EdgeInsets.fromLTRB(28, 22, 28, 22),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Minha Glicemia',
              style: pw.TextStyle(font: bold, fontSize: 20, color: PdfColors.white)),
            pw.SizedBox(height: 3),
            pw.Text('Relatório de Glicemia',
              style: pw.TextStyle(font: regular, fontSize: 11, color: _azulClaro)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Período: $periodo',
              style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.white)),
            pw.SizedBox(height: 3),
            pw.Text('Gerado em: $gerado',
              style: pw.TextStyle(font: regular, fontSize: 9, color: _azulClaro)),
          ]),
        ],
      ),
    );
  }

  // ── Cabeçalho do histórico ────────────────────────────────────────────────

  static pw.Widget _headerHistorico(
      String periodo, int pagina, pw.Font bold, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _cinzaBorda, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            pw.Container(
              width: 4, height: 14,
              decoration: pw.BoxDecoration(
                color: _azul,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text('Histórico de Medições',
              style: pw.TextStyle(font: bold, fontSize: 13, color: _texto)),
          ]),
          pw.Text('Período: $periodo',
            style: pw.TextStyle(font: regular, fontSize: 9, color: _cinza)),
        ],
      ),
    );
  }

  // ── Rodapé ────────────────────────────────────────────────────────────────

  static pw.Widget _rodape(int pagina, pw.Font regular) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(28, 8, 28, 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _cinzaBorda, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Minha Glicemia — Relatório de Glicemia',
            style: pw.TextStyle(font: regular, fontSize: 8, color: _cinza)),
          pw.Text('Página $pagina',
            style: pw.TextStyle(font: regular, fontSize: 8, color: _cinza)),
        ],
      ),
    );
  }

  // ── Card do paciente ──────────────────────────────────────────────────────

  static pw.Widget _cardPaciente(Paciente p, pw.Font bold, pw.Font regular) {
    final partes = [
      p.nome,
      if (p.idade != null) 'Idade: ${p.idade} anos',
      if (p.peso != null) 'Peso: ${p.peso!.toStringAsFixed(1)} kg',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EFF6FF'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE'), width: 0.5),
      ),
      child: pw.Row(children: [
        pw.Text('Paciente:  ',
          style: pw.TextStyle(font: regular, fontSize: 10, color: _cinza)),
        pw.Text(partes.join('  •  '),
          style: pw.TextStyle(font: bold, fontSize: 10, color: _texto)),
      ]),
    );
  }

  // ── Título de seção ───────────────────────────────────────────────────────

  static pw.Widget _tituloSecao(String texto, pw.Font bold) {
    return pw.Row(children: [
      pw.Container(
        width: 4, height: 14,
        decoration: pw.BoxDecoration(
          color: _azul,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
        ),
      ),
      pw.SizedBox(width: 8),
      pw.Text(texto,
        style: pw.TextStyle(font: bold, fontSize: 13, color: _texto)),
    ]);
  }

  // ── Resumo geral ──────────────────────────────────────────────────────────

  static pw.Widget _secaoResumo(_Stats s, pw.Font bold, pw.Font regular) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(children: [
          pw.Expanded(child: _statBox('Média',  s.media.round(), bold, regular)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: _statBox('Menor',  s.menor, bold, regular)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: _statBox('Maior',  s.maior, bold, regular)),
        ]),
        pw.SizedBox(height: 8),
        pw.Text('Total de medições no período: ${s.total}',
          style: pw.TextStyle(font: regular, fontSize: 10, color: _cinza)),
      ],
    );
  }

  static pw.Widget _statBox(String label, int valor, pw.Font bold, pw.Font regular) {
    final nivel = _nivelDe(valor);
    final (cor, corClara, corBorda) = _coresNivel(nivel);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: corClara,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: corBorda, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label,
            style: pw.TextStyle(font: regular, fontSize: 9, color: _cinza)),
          pw.SizedBox(height: 5),
          pw.Text('$valor',
            style: pw.TextStyle(font: bold, fontSize: 24, color: cor)),
          pw.Text('mg/dL',
            style: pw.TextStyle(font: regular, fontSize: 8, color: _cinza)),
          pw.SizedBox(height: 5),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: pw.BoxDecoration(
              color: cor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Text(_labelNivel(nivel),
              style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white)),
          ),
        ],
      ),
    );
  }

  // ── Distribuição ──────────────────────────────────────────────────────────

  static pw.Widget _secaoDistribuicao(_Stats s, pw.Font bold, pw.Font regular) {
    return pw.Column(children: [
      _barraNivel('Normal  (< 140)',      s.normal,    s.total, _verde,   _verdeClaro,   bold, regular),
      pw.SizedBox(height: 8),
      _barraNivel('Alto  (140–199)',       s.alto,      s.total, _laranja, _laranjaClaro, bold, regular),
      pw.SizedBox(height: 8),
      _barraNivel('Muito Alto  (200 ou mais)',   s.muitoAlto, s.total, _vermelho, _vermelhoClaro, bold, regular),
      pw.SizedBox(height: 8),
      pw.Align(
        alignment: pw.Alignment.centerLeft,
        child: pw.Text('Fonte: $fonteFaixasTitulo, Tabela 1 — $fonteFaixasUrl. $fonteFaixasAviso',
          style: pw.TextStyle(font: regular, fontSize: 7, color: _cinza)),
      ),
    ]);
  }

  static pw.Widget _barraNivel(
    String label, int count, int total,
    PdfColor cor, PdfColor corClara,
    pw.Font bold, pw.Font regular,
  ) {
    final pct       = total > 0 ? count / total : 0.0;
    final filled    = (pct * 100).round().clamp(0, 100);
    final empty     = 100 - filled;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
              style: pw.TextStyle(font: regular, fontSize: 10, color: _texto)),
            pw.Text('$count  •  ${(pct * 100).round()}%',
              style: pw.TextStyle(font: bold, fontSize: 10, color: cor)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(children: [
          if (filled > 0)
            pw.Expanded(flex: filled, child: pw.Container(height: 8, color: cor)),
          if (empty > 0)
            pw.Expanded(flex: empty,  child: pw.Container(height: 8, color: corClara)),
        ]),
      ],
    );
  }

  // ── Média por refeição ────────────────────────────────────────────────────

  static pw.Widget _secaoRefeicoes(_Stats s, pw.Font bold, pw.Font regular) {
    if (s.mediaPorRefeicao.isEmpty) return pw.SizedBox();
    final entradas = s.mediaPorRefeicao.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return pw.Table(
      border: pw.TableBorder.all(color: _cinzaBorda, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _azulEscuro),
          children: [
            _celulaHeader('Refeição', bold),
            _celulaHeader('Média', bold),
            _celulaHeader('Nível', bold),
          ],
        ),
        for (int i = 0; i < entradas.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? _cinzaFundo : PdfColors.white,
            ),
            children: [
              _celulaTexto(entradas[i].key, regular),
              _celulaTexto('${entradas[i].value.round()} mg/dL', bold),
              _celulaNivel(_nivelDe(entradas[i].value.round()), bold),
            ],
          ),
      ],
    );
  }

  // ── Tabela de histórico ───────────────────────────────────────────────────

  static pw.Widget _tabelaHistorico(
      List<RegistroGlicemia> registros, pw.Font bold, pw.Font regular) {
    return pw.Table(
      border: pw.TableBorder.all(color: _cinzaBorda, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(68),
        1: pw.FixedColumnWidth(36),
        2: pw.FlexColumnWidth(3),
        3: pw.FixedColumnWidth(72),
        4: pw.FixedColumnWidth(66),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _azulEscuro),
          children: [
            _celulaHeader('Data',     bold),
            _celulaHeader('Hora',     bold),
            _celulaHeader('Refeição', bold),
            _celulaHeader('Valor',    bold),
            _celulaHeader('Nível',    bold),
          ],
        ),
        for (int i = 0; i < registros.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isEven ? _cinzaFundo : PdfColors.white,
            ),
            children: [
              _celulaTexto(_fmtData.format(registros[i].dataHora), regular),
              _celulaTexto(_fmtHora.format(registros[i].dataHora), regular),
              _celulaTexto(registros[i].refeicao, regular),
              _celulaValor(registros[i].valor, registros[i].nivel, bold),
              _celulaNivel(registros[i].nivel, bold),
            ],
          ),
      ],
    );
  }

  // ── Células ───────────────────────────────────────────────────────────────

  static pw.Widget _celulaHeader(String texto, pw.Font bold) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(texto,
      style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
  );

  static pw.Widget _celulaTexto(String texto, pw.Font font) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: pw.Text(texto,
      style: pw.TextStyle(font: font, fontSize: 9, color: _texto)),
  );

  static pw.Widget _celulaValor(int valor, NivelGlicemia nivel, pw.Font bold) {
    final (cor, _, _) = _coresNivel(nivel);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text('$valor mg/dL',
        style: pw.TextStyle(font: bold, fontSize: 9, color: cor)),
    );
  }

  static pw.Widget _celulaNivel(NivelGlicemia nivel, pw.Font bold) {
    final (cor, corClara, _) = _coresNivel(nivel);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: pw.BoxDecoration(
          color: corClara,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Text(_labelNivel(nivel),
          style: pw.TextStyle(font: bold, fontSize: 8, color: cor)),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static NivelGlicemia _nivelDe(int v) {
    if (v < 140) return NivelGlicemia.normal;
    if (v < 200) return NivelGlicemia.alto;
    return NivelGlicemia.muitoAlto;
  }

  static String _labelNivel(NivelGlicemia n) => switch (n) {
    NivelGlicemia.normal    => 'Normal',
    NivelGlicemia.alto      => 'Alto',
    NivelGlicemia.muitoAlto => 'Muito Alto',
  };

  static (PdfColor, PdfColor, PdfColor) _coresNivel(NivelGlicemia n) => switch (n) {
    NivelGlicemia.normal    => (_verde,   _verdeClaro,   _verdeBorda),
    NivelGlicemia.alto      => (_laranja, _laranjaClaro, _laranjaBorda),
    NivelGlicemia.muitoAlto => (_vermelho, _vermelhoClaro, _vermelhoBorda),
  };

  static _Stats _calcularStats(List<RegistroGlicemia> lista) {
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

    return _Stats(
      total: lista.length,
      normal: norm, alto: alt, muitoAlto: mAlto,
      menor: minV, maior: maxV,
      media: soma / lista.length,
      mediaPorRefeicao: {
        for (final k in somaRef.keys) k: somaRef[k]! / contRef[k]!,
      },
    );
  }
}

class _Stats {
  final int total, normal, alto, muitoAlto, menor, maior;
  final double media;
  final Map<String, double> mediaPorRefeicao;

  const _Stats({
    required this.total,
    required this.normal, required this.alto, required this.muitoAlto,
    required this.menor,  required this.maior, required this.media,
    required this.mediaPorRefeicao,
  });
}
