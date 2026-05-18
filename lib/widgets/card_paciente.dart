import 'package:flutter/material.dart';
import '../models/paciente.dart';
import '../services/glicemia_service.dart';

class CardPaciente extends StatefulWidget {
  final GlicemiaService service;
  const CardPaciente({super.key, required this.service});

  @override
  State<CardPaciente> createState() => _CardPacienteState();
}

class _CardPacienteState extends State<CardPaciente> {
  bool _expandido = false;
  Paciente? _paciente;

  final _nomeCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  DateTime? _dataNasc;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final p = await widget.service.buscarPaciente();
    if (p != null && mounted) {
      setState(() {
        _paciente = p;
        _nomeCtrl.text = p.nome;
        _pesoCtrl.text = p.peso?.toString() ?? '';
        _dataNasc = p.dataNascimento;
      });
    }
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) return;
    final p = Paciente(
      nome: nome,
      dataNascimento: _dataNasc,
      peso: double.tryParse(_pesoCtrl.text),
    );
    await widget.service.salvarPaciente(p);
    if (mounted) {
      setState(() { _paciente = p; _expandido = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados salvos!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _expandido = !_expandido),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  const Text('👤 Dados do Paciente',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2B6CB0))),
                  const Spacer(),
                  if (_paciente != null)
                    Text(_paciente!.nome,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF718096))),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFA0AEC0)),
                  ),
                ],
              ),
            ),
            if (_expandido) ...[
              const SizedBox(height: 20),
              _campo('Nome completo', _nomeCtrl, TextInputType.text),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _campoPeso()),
                const SizedBox(width: 12),
                Expanded(child: _campoData(context)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: _salvar,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2B6CB0), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: const Color(0xFF2B6CB0),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Salvar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, TextInputType tipo) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _campoPeso() {
    return TextField(
      controller: _pesoCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Peso (kg)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _campoData(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _dataNasc ?? DateTime(1970),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (d != null) setState(() => _dataNasc = d);
      },
      child: Container(
        height: 60,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _dataNasc != null
              ? '${_dataNasc!.day.toString().padLeft(2, '0')}/${_dataNasc!.month.toString().padLeft(2, '0')}/${_dataNasc!.year}'
              : 'Nascimento',
          style: const TextStyle(fontSize: 16, color: Color(0xFF718096)),
        ),
      ),
    );
  }
}
