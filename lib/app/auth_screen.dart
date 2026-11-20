import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:material_ui/material_ui.dart';

import 'ui_kit.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _loading = false;
  bool _creating = false;
  bool _phoneMode = false;
  String? _verificationId;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = _email.text.trim();
      final password = _password.text;
      if (!email.contains('@') || password.length < 6) {
        throw FirebaseAuthException(
          code: 'invalid-credentials',
          message: 'Ingresá un email válido y una contraseña de 6 caracteres.',
        );
      }
      if (_creating) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await GoogleSignIn.instance.initialize();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google no entregó un token de identidad válido.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (mounted) {
        setState(() => _error = error.description ?? error.code.name);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPhoneCode() async {
    final phone = _phone.text.trim();
    if (!phone.startsWith('+') || phone.length < 8) {
      setState(() => _error = 'Ingresá el teléfono con prefijo internacional.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = error.message ?? error.code;
          });
        }
      },
      codeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() {
            _loading = false;
            _verificationId = verificationId;
          });
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (mounted) setState(() => _verificationId = verificationId);
      },
    );
  }

  Future<void> _confirmPhoneCode() async {
    final verificationId = _verificationId;
    final code = _code.text.trim();
    if (verificationId == null || code.length < 6) {
      setState(() => _error = 'Ingresá el código de 6 dígitos.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = error.message ?? error.code);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: DemoPanel(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const BrandMark(size: 58),
                      const SizedBox(height: 16),
                      Text(
                        _phoneMode
                            ? 'Entrar con teléfono'
                            : _creating
                                ? 'Crear cuenta'
                                : 'Iniciar sesión',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hay Equipo · producción',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),
                      if (!_phoneMode) ...[
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loading ? null : _submitEmail,
                          child: Text(
                            _creating ? 'Crear cuenta' : 'Iniciar sesión',
                          ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() => _creating = !_creating),
                          child: Text(
                            _creating
                                ? 'Ya tengo una cuenta'
                                : 'Crear una cuenta nueva',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _googleSignIn,
                          icon: const Icon(Icons.account_circle_outlined),
                          label: const Text('Continuar con Google'),
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            hintText: '+54 9 11...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_verificationId != null)
                          TextField(
                            controller: _code,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Código SMS',
                            ),
                          ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loading
                              ? null
                              : _verificationId == null
                                  ? _sendPhoneCode
                                  : _confirmPhoneCode,
                          child: Text(
                            _verificationId == null
                                ? 'Enviar código'
                                : 'Confirmar código',
                          ),
                        ),
                      ],
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _phoneMode = !_phoneMode;
                                  _error = null;
                                }),
                        child: Text(
                          _phoneMode ? 'Usar email' : 'Entrar con teléfono',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const LocalDemoBadge(
                        label: 'Tu cuenta se autentica con Firebase',
                        icon: Icons.verified_user_outlined,
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
