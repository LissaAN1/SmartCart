import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/auth_scaffold.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/components/social_login_section.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/auth/domain/validators/auth_validators.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/login/ui/bloc/login_event.dart';
import 'package:smartcart/features/login/ui/bloc/login_state.dart';

/// Inicio de sesión de los cinco perfiles. Es una sola pantalla: el [role]
/// elegido en la selección define el color, el ícono y el lema; el formulario
/// y la lógica son los mismos.
class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<LoginBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: widget.role,
          ),
        );
  }

  void _showNotAvailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final perfil = PerfilVisual.de(widget.role);
    return AuthScaffold(
      tema: perfil.paleta,
      child: BlocListener<LoginBloc, LoginState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == LoginStatus.success && state.profile != null) {
            context.goHome(role: widget.role, profile: state.profile!);
          }
        },
        child: BlocBuilder<LoginBloc, LoginState>(
          builder: (context, state) {
            final loading = state.status == LoginStatus.loading;
            final error =
                state.status == LoginStatus.failure ? state.errorMessage : null;
            return _buildForm(context, perfil, loading, error);
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    PerfilVisual perfil,
    bool loading,
    String? error,
  ) {
    final t = perfil.paleta;
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 26,
                backgroundColor: t.primario,
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 24),
            EtiquetaEstado(
              texto: perfil.nombre,
              color: t.primario,
              fondo: t.suave,
              icono: perfil.icono,
            ),
            Center(
              child: Text(
                'Bienvenido a SmartCart',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: t.texto,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                perfil.lema,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: t.textoGris,
                ),
              ),
            ),
            const SizedBox(height: 28),
            AuthTextField(
              controller: _emailController,
              label: 'CORREO ELECTRÓNICO',
              hint: 'tu@correo.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
              enabled: !loading,
            ),
            const SizedBox(height: 18),
            AuthTextField(
              controller: _passwordController,
              label: 'CONTRASEÑA',
              hint: '••••••••',
              icon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: AuthValidators.existingPassword,
              onSubmitted: (_) => _submit(),
              enabled: !loading,
              labelTrailing: TextButton(
                onPressed: () => _showNotAvailable(
                  'La recuperación de contraseña aún no está disponible.',
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: t.primario,
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 22),
            if (error != null) ...[
              ErrorMessage(message: error),
              const SizedBox(height: 16),
            ],
            BotonPrimario(
              texto: 'Continuar',
              cargando: loading,
              onTap: _submit,
            ),
            const SizedBox(height: 20),
            const SocialLoginSection(),
            const SizedBox(height: 16),
            _buildRegisterLink(context, perfil, loading),
            const SizedBox(height: 20),
            _buildTerms(t),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(
    BuildContext context,
    PerfilVisual perfil,
    bool loading,
  ) {
    final t = perfil.paleta;

    if (!perfil.permiteRegistro) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          'Las cuentas de ${perfil.nombre.toLowerCase()} las asigna el equipo '
          'de SmartCart.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: t.textoGris,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '¿No tienes una cuenta? ',
            style: TextStyle(
              fontSize: 13.5,
              color: t.textoGris,
            ),
          ),
          TextButton(
            onPressed: loading
                ? null
                : () => Navigator.pushNamed(
                      context,
                      AppRoutes.register,
                      arguments: widget.role,
                    ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 40),
              foregroundColor: t.primario,
            ),
            child: const Text(
              'Regístrate aquí',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerms(TemaRol t) {
    final base = TextStyle(fontSize: 11.5, height: 1.4, color: t.textoGris);
    final link = base.copyWith(decoration: TextDecoration.underline);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Al continuar, aceptas nuestros '),
          TextSpan(text: 'Términos de Servicio', style: link),
          const TextSpan(text: ' y '),
          TextSpan(text: 'Política de Privacidad', style: link),
          const TextSpan(text: '. SmartCart Colombia.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
