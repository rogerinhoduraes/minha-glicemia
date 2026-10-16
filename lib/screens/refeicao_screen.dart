import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tipo_refeicao.dart';
import '../services/analytics_service.dart';
import '../services/glicemia_service.dart';
import '../services/notificacao_service.dart';

const _kPrimary = Color(0xFF2563EB);
const _kHeader  = Color(0xFF1A1E2E);
const _kStone   = Color(0xFFF2EFE9);

class RefeicaoScreen extends StatefulWidget {
  final GlicemiaService service;
  const RefeicaoScreen({super.key, required this.service});

  @override
  State<RefeicaoScreen> createState() => _RefeicaoScreenState();
}

class _RefeicaoScreenState extends State<RefeicaoScreen> {
  final _nomeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.logTela('refeicoes');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _adicionar(List<TipoRefeicao> atual) async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) return;
    await widget.service.adicionarRefeicao(nome, atual.length);
    AnalyticsService.logRefeicaoAdicionada();
    _nomeCtrl.clear();
  }

  Future<void> _deletar(TipoRefeicao r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover refeição?',
            style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w800)),
        content: Text(r.nome),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await NotificacaoService.cancelarLembrete(r);
      await widget.service.deletarRefeicao(r.id!);
      AnalyticsService.logRefeicaoRemovida();
    }
  }

  Future<void> _editarHorario(TipoRefeicao r) async {
    if (r.horario != null) {
      final acao = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Horário — ${r.nome}',
              style: GoogleFonts.nunitoSans(fontWeight: FontWeight.w800)),
          content: Text('Horário atual: ${r.horario}',
              style: GoogleFonts.nunitoSans()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'remover'),
              child: const Text('Remover', style: TextStyle(color: Color(0xFFEF4444))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'alterar'),
              child: const Text('Alterar'),
            ),
          ],
        ),
      );
      if (acao == null) return;
      if (acao == 'remover') {
        final atualizado = r.copyWith(horario: null, lembreteAtivo: false);
        await widget.service.atualizarRefeicao(atualizado);
        await NotificacaoService.cancelarLembrete(r);
        return;
      }
    }

    final parts = r.horario?.split(':');
    final inicial = parts != null
        ? TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
        : TimeOfDay.now();

    if (!mounted) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: inicial,
      helpText: 'Horário do lembrete',
    );
    if (picked == null || !mounted) return;

    final horario =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final atualizado = r.copyWith(horario: horario);
    await widget.service.atualizarRefeicao(atualizado);
    if (atualizado.lembreteAtivo) {
      await NotificacaoService.agendarLembrete(atualizado);
    }
  }

  Future<void> _toggleLembrete(TipoRefeicao r) async {
    if (r.horario == null) return;
    final atualizado = r.copyWith(lembreteAtivo: !r.lembreteAtivo);
    await widget.service.atualizarRefeicao(atualizado);
    await NotificacaoService.agendarLembrete(atualizado);
    AnalyticsService.logLembreteAlterado(
        ativo: atualizado.lembreteAtivo, nome: atualizado.nome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kHeader,
        title: const Text('Tipos de Refeição'),
      ),
      body: StreamBuilder<List<TipoRefeicao>>(
        stream: widget.service.streamRefeicoes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
                child: Text('Erro: ${snap.error}',
                    style: const TextStyle(color: Color(0xFFEF4444))));
          }
          final lista = snap.data ?? [];
          return Column(
            children: [
              Expanded(
                child: lista.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Nenhuma refeição cadastrada',
                                style: GoogleFonts.nunitoSans(
                                    fontSize: 15,
                                    color: const Color(0xFF94A3B8))),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        itemCount: lista.length,
                        onReorderItem: (oldIndex, newIndex) {
                          final atualizada =
                              List<TipoRefeicao>.from(lista);
                          final item = atualizada.removeAt(oldIndex);
                          atualizada.insert(newIndex, item);
                          widget.service.reordenarRefeicoes(atualizada);
                        },
                        itemBuilder: (context, i) {
                          final r = lista[i];
                          return _ItemRefeicao(
                            key: ValueKey(r.id),
                            refeicao: r,
                            onEditarHorario: () => _editarHorario(r),
                            onToggleLembrete: () => _toggleLembrete(r),
                            onDeletar: () => _deletar(r),
                            index: i,
                          );
                        },
                      ),
              ),
              _painelAdicionar(snap.data ?? []),
            ],
          );
        },
      ),
    );
  }

  Widget _painelAdicionar(List<TipoRefeicao> atual) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nomeCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Nova refeição...',
                prefixIcon:
                    Icon(Icons.add_circle_outline, color: _kPrimary),
              ),
              onSubmitted: (_) => _adicionar(atual),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            width: 52,
            child: ElevatedButton(
              onPressed: () => _adicionar(atual),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Icon(Icons.check, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRefeicao extends StatelessWidget {
  final TipoRefeicao refeicao;
  final VoidCallback onEditarHorario;
  final VoidCallback onToggleLembrete;
  final VoidCallback onDeletar;
  final int index;

  const _ItemRefeicao({
    super.key,
    required this.refeicao,
    required this.onEditarHorario,
    required this.onToggleLembrete,
    required this.onDeletar,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final temHorario = refeicao.horario != null;
    final ativo = temHorario && refeicao.lembreteAtivo;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.restaurant_menu,
              color: _kPrimary, size: 18),
        ),
        title: Text(refeicao.nome,
            style: GoogleFonts.nunitoSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A))),
        subtitle: GestureDetector(
          onTap: onEditarHorario,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  temHorario ? Icons.alarm : Icons.alarm_add_outlined,
                  size: 13,
                  color: temHorario
                      ? _kPrimary
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  temHorario ? refeicao.horario! : 'Definir horário',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: temHorario
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: temHorario
                        ? _kPrimary
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bell toggle
            GestureDetector(
              onTap: temHorario ? onToggleLembrete : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ativo
                      ? _kPrimary.withValues(alpha: 0.1)
                      : const Color(0xFFF2EFE9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ativo
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: ativo ? _kPrimary : const Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Delete
            GestureDetector(
              onTap: onDeletar,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.delete_outline,
                    color: Color(0xFFEF4444), size: 20),
              ),
            ),
            const SizedBox(width: 6),
            // Drag
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: _kStone,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.drag_handle,
                    color: Color(0xFF94A3B8), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
