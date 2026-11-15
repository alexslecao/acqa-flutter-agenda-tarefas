import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/violet_backdrop.dart';

/// Tela de Login e Cadastro (autenticação local demonstrativa).
///
/// Um seletor no topo do cartão alterna entre os dois modos. Depois do login
/// ou cadastro, o [AuthController] avisa o app, que troca para a tela
/// principal.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});

  final AuthController auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Uma chave por modo: ao alternar, o formulário é recriado e as mensagens
  // de validação antigas somem (o texto digitado fica nos controladores).
  final GlobalKey<FormState> _signInFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static const int _minPasswordLength = 6;

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  GlobalKey<FormState> get _formKey =>
      _isSignUp ? _signUpFormKey : _signInFormKey;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setMode(bool signUp) {
    if (_isSubmitting || signUp == _isSignUp) return;
    setState(() {
      _isSignUp = signUp;
      _errorMessage = null;
      _confirmController.clear();
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu nome.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!_emailPattern.hasMatch(email)) return 'Digite um e-mail válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Informe a senha.';
    if (_isSignUp && password.length < _minPasswordLength) {
      return 'A senha deve ter pelo menos $_minPasswordLength caracteres.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Repita a senha.';
    if (value != _passwordController.text) return 'As senhas não coincidem.';
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      setState(() => _errorMessage = null);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final String? error;
    if (_isSignUp) {
      error = await widget.auth.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      error = await widget.auth.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.deepViolet,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const Positioned.fill(child: VioletBackdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(0.0, constraints.maxHeight - 48),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const _Brand(),
                              const SizedBox(height: 28),
                              _buildCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard() {
    final error = _errorMessage;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.card,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ModeSwitch(isSignUp: _isSignUp, onChanged: _setMode),
              const SizedBox(height: 22),
              Text(
                _isSignUp ? 'Crie sua conta' : 'Entrar na conta',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignUp
                    ? 'Leva menos de um minuto para começar.'
                    : 'Que bom ver você de novo.',
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 20),
              if (_isSignUp) ...<Widget>[
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSubmitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.name],
                  validator: _validateName,
                  decoration: AppTheme.inputDecoration(
                    label: 'Nome',
                    icon: Icons.person_outline_rounded,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _emailController,
                enabled: !_isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const <String>[AutofillHints.email],
                validator: _validateEmail,
                decoration: AppTheme.inputDecoration(
                  label: 'E-mail',
                  hint: 'voce@exemplo.com',
                  icon: Icons.mail_outline_rounded,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                enabled: !_isSubmitting,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction:
                    _isSignUp ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: _isSignUp ? null : (_) => _submit(),
                validator: _validatePassword,
                decoration: AppTheme.inputDecoration(
                  label: 'Senha',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              if (_isSignUp) ...<Widget>[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  enabled: !_isSubmitting,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: _validateConfirmation,
                  decoration: AppTheme.inputDecoration(
                    label: 'Confirmar senha',
                    icon: Icons.lock_outline_rounded,
                  ),
                ),
              ],
              if (error != null) ...<Widget>[
                const SizedBox(height: 14),
                _ErrorBanner(message: error),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : Text(_isSignUp ? 'Criar conta' : 'Entrar'),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _isSubmitting ? null : () => _setMode(!_isSignUp),
                child: Text(
                  _isSignUp
                      ? 'Já tenho conta. Fazer login'
                      : 'Ainda não tenho conta. Cadastrar',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              const _DemoNotice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AppLogo(),
        SizedBox(height: 18),
        Text(
          'Lavanda',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Seu dia, uma tarefa de cada vez.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.lavender),
        ),
      ],
    );
  }
}

/// Seletor "Login | Cadastro" em formato de pílula.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ModeTab(
              label: 'Login',
              isActive: !isSignUp,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Cadastro',
              isActive: isSignUp,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? AppColors.violet : Colors.transparent,
              borderRadius: borderRadius,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8EF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: AppColors.danger,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso fixo de que o login é apenas demonstrativo.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lavender),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.violet),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Login demonstrativo: a conta fica salva só neste aparelho e não '
              'tem a segurança de um sistema real. Não use uma senha que você '
              'usa em outros lugares.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
