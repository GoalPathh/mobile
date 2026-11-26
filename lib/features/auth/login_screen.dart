import 'package:flutter/material.dart';

import '../../data/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.api,
    required this.onAuthenticated,
    super.key,
  });

  final ApiClient api;
  final VoidCallback onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _registerMode = false;
  var _showPassword = false;
  var _busy = false;
  String? _message;
  var _messageIsError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _message = null;
      _messageIsError = false;
    });
    try {
      if (_registerMode) {
        final hasSession = await widget.api.signUp(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
        if (hasSession) {
          widget.onAuthenticated();
        } else {
          setState(() {
            _message = 'Akun dibuat. Periksa email untuk menyelesaikan verifikasi, lalu login.';
            _messageIsError = false;
          });
        }
      } else {
        await widget.api.signIn(_email.text.trim(), _password.text);
        widget.onAuthenticated();
      }
    } on ApiException catch (error) {
      setState(() {
        _message = error.message;
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/goalpath-logo.webp',
                        width: 76,
                        height: 76,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _registerMode
                          ? 'Buat akun GoalPath'
                          : 'Selamat datang kembali',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _registerMode
                          ? 'Mulai bangun kebiasaan kecil menuju tujuanmu.'
                          : 'Lanjutkan langkah kecilmu hari ini.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_registerMode) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) => (value?.trim().length ?? 0) < 2
                            ? 'Nama minimal 2 karakter.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return email.contains('@') && email.contains('.')
                            ? null
                            : 'Masukkan email yang valid.';
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Sembunyikan password'
                              : 'Tampilkan password',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value?.length ?? 0) < 8
                          ? 'Password minimal 8 karakter.'
                          : null,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _message!,
                        style: TextStyle(
                          color: _messageIsError
                              ? Theme.of(context).colorScheme.error
                              : color,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_registerMode ? 'Buat akun' : 'Login'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _registerMode = !_registerMode;
                              _message = null;
                              _messageIsError = false;
                            }),
                      child: Text(
                        _registerMode
                            ? 'Sudah punya akun? Login'
                            : 'Belum punya akun? Daftar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
