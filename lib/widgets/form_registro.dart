import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/registro_glicemia.dart';
import '../models/tipo_refeicao.dart';
import '../services/analytics_service.dart';
import '../services/glicemia_service.dart';

class FormRegistro extends StatefulWidget {
  final GlicemiaService service;
  final RegistroGlicemia? editando;
  final VoidCallback onCancelarEdicao;

  const FormRegistro({
    super.key,
    required this.service,
    required this.editando,
    required this.onCancelarEdicao,
  });

  @override
  State<FormRegistro> createState() => _FormRegistroState();
}

class _FormRegistroState extends State<FormRegistro> {
  final _glicemiaCtrl = TextEditingController();
  String? _refeicao;
  bool _salvando = false;

  @override
  void dispose() {
    _glicemiaCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FormRegistro old) {
    super.didUpdateWidget(old);
    final e = widget.editando;
    if (e != null && e != old.editando) {
      _glicemiaCtrl.text = e.valor.toString();
      _refeicao = e.refeicao;
    }
    if (e == null && old.editando != null) {
      _glicemiaCtrl.clear();
      _refeicao = null;
    }
  }

  Future<void> _salvar() async {
    final v = int.tryParse(_glicemiaCtrl.text);
    if (v == null || v < 20 || v > 600) {
      _snack('Informe um valor válido (20–600 mg/dL)', error: true);
      return;
    }
    if (_refeicao == null) {
      _snack('Selecione uma refeição', error: true);
      return;
    }
    setState(() => _salvando = true);
    try {
      final r = RegistroGlicemia(
        id: widget.editando?.id,
        dataHora: DateTime.now(),
        refeicao: _refeicao!,
        valor: v,
      );
      if (widget.editando != null) {
        await widget.service.editar(r);
        AnalyticsService.logMedicaoEditada(r);
        widget.onCancelarEdicao();
      } else {
        await widget.service.salvar(r);
        AnalyticsService.logMedicaoSalva(r);
      }
      if (mounted) {
        _glicemiaCtrl.clear();
        _refeicao = null;
        setState(() {});
        _snack('Registro salvo!');
      }
    } catch (e) {
      if (mounted) _snack('Não foi possível salvar. Tente novamente.', error: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.editando != null;
    return StreamBuilder<List<TipoRefeicao>>(
      stream: widget.service.streamRefeicoes(),
      builder: (context, snap) {
        final refeicoes = snap.data ?? [];
        String? atual = _refeicao;
        if (atual != null && !refeicoes.any((r) => r.nome == atual)) {
          atual = null;
        }
        if (atual == null && refeicoes.isNotEmpty) {
          atual = refeicoes.first.nome;
          WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _refeicao = atual));
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    editando ? 'Editar Registro' : 'Nova Medição',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1917),
                    ),
                  ),
                  if (editando) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.onCancelarEdicao,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Cancelar'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        textStyle: GoogleFonts.nunitoSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),
                _seletor(refeicoes, atual),
                const SizedBox(height: 12),
                _entradaGlicemia(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: _salvando
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(editando ? 'Salvar alterações' : 'Salvar registro'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _seletor(List<TipoRefeicao> refeicoes, String? valor) {
    return DropdownButtonFormField<String>(
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Refeição',
        prefixIcon: Icon(Icons.restaurant_menu_outlined, color: Color(0xFF2563EB)),
      ),
      items: refeicoes.isEmpty
          ? [const DropdownMenuItem(value: '', child: Text('Nenhuma refeição cadastrada'))]
          : refeicoes.map((r) => DropdownMenuItem(value: r.nome, child: Text(r.nome))).toList(),
      onChanged: refeicoes.isEmpty ? null : (v) => setState(() => _refeicao = v),
    );
  }

  Widget _entradaGlicemia() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: _glicemiaCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunitoSans(
            fontSize: 32, fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A), letterSpacing: 1,
          ),
          decoration: InputDecoration(
            hintText: '—',
            hintStyle: GoogleFonts.nunitoSans(
              fontSize: 32, fontWeight: FontWeight.w300, color: const Color(0xFFCBD5E1)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: Text('mg/dL',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8))),
        ),
      ],
    );
  }
}
