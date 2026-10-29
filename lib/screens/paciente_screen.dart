import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/paciente.dart';
import '../services/analytics_service.dart';
import '../services/foto_perfil_service.dart';
import '../services/glicemia_service.dart';

const _kPrimary = Color(0xFF2563EB);
const _kHeader  = Color(0xFF1A1E2E);

class PacienteScreen extends StatefulWidget {
  final GlicemiaService service;
  const PacienteScreen({super.key, required this.service});

  @override
  State<PacienteScreen> createState() => _PacienteScreenState();
}

class _PacienteScreenState extends State<PacienteScreen> {
  final _fotoService = FotoPerfilService();
  File? _foto;
  final _nomeCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  DateTime? _dataNasc;
  final _formKey = GlobalKey<FormState>();
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logTela('perfil_paciente');
    _carregar();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final p = await widget.service.buscarPaciente();
    final foto = await _fotoService.buscar();
    if (mounted) {
      setState(() {
        _carregando = false;
        _foto = foto;
        if (p != null) {
          _nomeCtrl.text = p.nome;
          _pesoCtrl.text = p.peso?.toStringAsFixed(1) ?? '';
          _dataNasc = p.dataNascimento;
        }
      });
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      final pesoLimpo = _pesoCtrl.text.replaceAll(',', '.');
      
      await widget.service.salvarPaciente(Paciente(
        nome: _nomeCtrl.text.trim(),
        dataNascimento: _dataNasc,
        peso: double.tryParse(pesoLimpo),
      ));
      if (mounted) {
        AnalyticsService.logPerfilSalvo();
        _snack('Dados salvos!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', error: true);
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

  String get _idadeTexto {
    if (_dataNasc == null) return '—';
    final hoje = DateTime.now();
    int idade = hoje.year - _dataNasc!.year;
    if (hoje.month < _dataNasc!.month ||
       (hoje.month == _dataNasc!.month && hoje.day < _dataNasc!.day)) {
      idade--;
    }
    return '$idade ${idade == 1 ? 'ano' : 'anos'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kHeader,
        title: const Text('Dados do Paciente'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _avatar(),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _campo('Nome completo', _nomeCtrl,
                                Icons.person_outline, TextInputType.name,
                                validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null),
                            const SizedBox(height: 16),
                            _campo('Peso (kg)', _pesoCtrl,
                                Icons.monitor_weight_outlined,
                                const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return null;
                                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Peso inválido';
                                  return null;
                                }),
                            const SizedBox(height: 16),
                            _campoData(context),
                            if (_dataNasc != null) ...[
                              const SizedBox(height: 12),
                              Row(children: [
                                Icon(Icons.cake_outlined, size: 16,
                                    color: Colors.grey.shade400),
                                const SizedBox(width: 8),
                                Text('Idade: $_idadeTexto',
                                    style: GoogleFonts.nunitoSans(
                                        fontSize: 14, color: const Color(0xFF64748B))),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      child: _salvando
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final img = await ImagePicker()
          .pickImage(source: origem, maxWidth: 512, imageQuality: 85);
      if (img == null) return;
      final salva = await _fotoService.salvar(img.path);
      await FileImage(salva).evict(); // mesmo caminho: descarta a imagem em cache
      if (mounted) setState(() => _foto = salva);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Não foi possível usar a câmera ou a galeria.')));
    }
  }

  Future<void> _removerFoto() async {
    final antiga = _foto;
    await _fotoService.remover();
    if (antiga != null) await FileImage(antiga).evict();
    if (mounted) setState(() => _foto = null);
  }

  void _menuFoto() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () {
              Navigator.pop(ctx);
              _escolherFoto(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar foto'),
            onTap: () {
              Navigator.pop(ctx);
              _escolherFoto(ImageSource.camera);
            },
          ),
          if (_foto != null)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              title: const Text('Remover foto',
                  style: TextStyle(color: Color(0xFFEF4444))),
              onTap: () {
                Navigator.pop(ctx);
                _removerFoto();
              },
            ),
        ]),
      ),
    );
  }

  Widget _avatar() {
    return GestureDetector(
      onTap: _menuFoto,
      child: Semantics(
        button: true,
        label: 'Alterar foto do paciente',
        child: Stack(children: [
          _avatarImagem(),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                  color: _kPrimary, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera, size: 16, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _avatarImagem() {
    final nome = _nomeCtrl.text.trim();
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';
    return Container(
      width: 88, height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: _foto == null
            ? null
            : DecorationImage(image: FileImage(_foto!), fit: BoxFit.cover),
        gradient: const LinearGradient(
          colors: [_kHeader, _kPrimary],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(
            color: _kPrimary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: _foto != null
          ? null
          : Center(
              child: Text(inicial,
                style: GoogleFonts.nunitoSans(
                  fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, IconData icon, TextInputType tipo, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: tipo,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
      ),
    );
  }

  Widget _campoData(BuildContext context) {
    final texto = _dataNasc != null
        ? DateFormat('dd/MM/yyyy').format(_dataNasc!)
        : 'Data de nascimento';

    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: _dataNasc ?? DateTime(1990),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            locale: const Locale('pt', 'BR'),
          );
          if (d != null) setState(() => _dataNasc = d);
        },
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, color: _kPrimary, size: 20),
            const SizedBox(width: 12),
            Text(texto,
              style: TextStyle(
                fontSize: 15,
                color: _dataNasc != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
          ]),
        ),
      ),
    );
  }
}
