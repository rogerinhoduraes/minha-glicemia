import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';

const _kPrimary  = Color(0xFF2563EB);
const _kDark     = Color(0xFF1A1E2E);
const _kBg       = Color(0xFFF2EFE9);
const _kMuted    = Color(0xFF6B6860);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth       = AuthService();
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _senhaCtrl  = TextEditingController();

  bool _loading      = false;
  bool _isLogin      = true;   // false = cadastro
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logTela('login');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _mostrarErro(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _mostrarSucesso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _traduzirErro(dynamic e) {
    if (e is! Exception) return e.toString();
    final msg = e.toString();
    if (msg.contains('user-not-found'))       return 'E-mail não cadastrado.';
    if (msg.contains('wrong-password'))       return 'Senha incorreta.';
    if (msg.contains('email-already-in-use')) return 'E-mail já cadastrado. Faça login.';
    if (msg.contains('weak-password'))        return 'Senha muito fraca (mínimo 6 caracteres).';
    if (msg.contains('invalid-email'))        return 'E-mail inválido.';
    if (msg.contains('network-request-failed')) return 'Sem conexão com a internet.';
    if (msg.contains('too-many-requests'))    return 'Muitas tentativas. Tente mais tarde.';
    return 'Erro ao autenticar. Tente novamente.';
  }

  // ── Ações ──────────────────────────────────────────────────────────────────

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await _auth.signInWithEmail(_emailCtrl.text, _senhaCtrl.text);
        AnalyticsService.logLogin('email');
      } else {
        await _auth.registerWithEmail(_emailCtrl.text, _senhaCtrl.text);
        AnalyticsService.logCadastro('email');
      }
    } catch (e) {
      _mostrarErro(_traduzirErro(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) AnalyticsService.logLogin('google');
    } catch (e) {
      _mostrarErro('Erro ao entrar com Google.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entrarComApple() async {
    setState(() => _loading = true);
    try {
      final user = await _auth.signInWithApple();
      if (user != null) AnalyticsService.logLogin('apple');
    } catch (e) {
      _mostrarErro('Erro ao entrar com Apple.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _esqueceuSenha() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _mostrarErro('Digite seu e-mail antes de redefinir a senha.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.sendPasswordReset(email);
      _mostrarSucesso('E-mail de redefinição enviado para $email.');
    } catch (e) {
      _mostrarErro('Não foi possível enviar o e-mail.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const SizedBox(height: 16),
                const Icon(Icons.water_drop_outlined, size: 72, color: _kDark),
                const SizedBox(height: 14),
                Text('Minha Glicemia',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunitoSans(
                        fontSize: 30, fontWeight: FontWeight.w900,
                        color: _kDark)),
                const SizedBox(height: 6),
                Text('Monitore sua glicemia com facilidade',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunitoSans(
                        fontSize: 14, color: _kMuted)),
                const SizedBox(height: 40),

                // ── Toggle login / cadastro ──────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E0D8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    _Tab('Entrar',       selected: _isLogin,  onTap: () => setState(() => _isLogin = true)),
                    _Tab('Criar conta',  selected: !_isLogin, onTap: () => setState(() => _isLogin = false)),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── Campos ──────────────────────────────────────────────────
                _Campo(
                  controller: _emailCtrl,
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                  tipo: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                    if (!v.contains('@')) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _Campo(
                  controller: _senhaCtrl,
                  label: 'Senha',
                  icon: Icons.lock_outline,
                  obscure: !_senhaVisivel,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _kMuted, size: 20),
                    onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (!_isLogin && v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),

                // ── Esqueci senha ────────────────────────────────────────────
                if (_isLogin) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _esqueceuSenha,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: Text('Esqueci minha senha',
                          style: GoogleFonts.nunitoSans(
                              fontSize: 13, color: _kPrimary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // ── Botão principal ──────────────────────────────────────────
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ElevatedButton(
                    onPressed: _submeter,
                    child: Text(_isLogin ? 'Entrar' : 'Criar conta'),
                  ),
                  const SizedBox(height: 20),

                  // ── Divisor ──────────────────────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou',
                          style: GoogleFonts.nunitoSans(
                              fontSize: 13, color: _kMuted)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),

                  // ── Google ───────────────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: _entrarComGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: Color(0xFFE5E0D8), width: 2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      foregroundColor: const Color(0xFF0F172A),
                      textStyle: GoogleFonts.nunitoSans(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    icon: const Icon(Icons.g_mobiledata, size: 26,
                        color: Color(0xFF4285F4)),
                    label: const Text('Continuar com Google'),
                  ),
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _entrarComApple,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        side: const BorderSide(color: Color(0xFFE5E0D8), width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        foregroundColor: const Color(0xFF0F172A),
                        textStyle: GoogleFonts.nunitoSans(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.apple, size: 24),
                      label: const Text('Continuar com Apple'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(this.label, {required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? _kPrimary : _kMuted)),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType tipo;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _Campo({
    required this.controller,
    required this.label,
    required this.icon,
    this.tipo = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.nunitoSans(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kMuted, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
