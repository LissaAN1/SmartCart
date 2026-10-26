import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartcart/components/auth_scaffold.dart';
import 'package:smartcart/components/auth_text_field.dart';
import 'package:smartcart/components/error_message.dart';
import 'package:smartcart/components/social_login_section.dart';
import 'package:smartcart/core/constants/app_assets.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/core/routes/app_navigation.dart';
import 'package:smartcart/core/routes/app_routes.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';
import 'package:smartcart/features/auth/domain/validators/auth_validators.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_event.dart';
import 'package:smartcart/features/register/ui/bloc/register_state.dart';
import 'package:smartcart/features/register/ui/widgets/role_selector.dart';
import 'package:smartcart/features/register/ui/widgets/terms_checkbox.dart';

/// Registro común a todos los perfiles. La persona elige su perfil en el
/// selector; el color de la pantalla sigue a la selección.
class RegisterScreen extends StatefulWidget {
  /// Perfil preseleccionado (el del login desde el que se llegó). El
  /// administrador no se puede elegir al registrarse, así que se ignora.
  final UserRole? initialRole;

  const RegisterScreen({super.key, this.initialRole});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRole;
    _role = (initial != null && initial.canSelfRegister)
        ? initial
        : UserRole.cliente;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<RegisterBloc>().add(
          RegisterSubmitted(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _role,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final perfil = PerfilVisual.de(_role);
    return AuthScaffold(
      tema: perfil.paleta,
      title: 'Crear cuenta',
      child: BlocListener<RegisterBloc, RegisterState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == RegisterStatus.success &&
              state.profile != null) {
            context.goHome(role: _role, profile: state.profile!);
          }
        },
        child: BlocBuilder<RegisterBloc, RegisterState>(
          builder: (context, state) {
            final loading = state.status == RegisterStatus.loading;
            final error = state.status == RegisterStatus.failure
                ? state.errorMessage
                : null;
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
            _buildHero(t),
            const SizedBox(height: 22),
            Text(
              '¿Cómo quieres usar SmartCart?',
              style: TextStyle(
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: t.texto,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Elige el perfil que mejor se adapte a ti.',
              style: TextStyle(fontSize: 14, color: t.textoGris),
            ),
            const SizedBox(height: 18),
            RoleSelector(
              selected: _role,
              enabled: !loading,
              onChanged: (role) => setState(() => _role = role),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: _nameController,
              label: 'Nombre completo',
              hint: 'Tu nombre completo',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: AuthValidators.fullName,
              enabled: !loading,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              label: 'Correo electrónico',
              hint: 'nombre@ejemplo.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
              enabled: !loading,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _phoneController,
              label: 'Teléfono (opcional)',
              hint: '+57 300 000 0000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: AuthValidators.phone,
              enabled: !loading,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _passwordController,
              label: 'Contraseña',
              hint: 'Mínimo ${AuthValidators.minPasswordLength} caracteres',
              icon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: AuthValidators.newPassword,
              enabled: !loading,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _confirmController,
              label: 'Confirmar contraseña',
              hint: 'Repite tu contraseña',
              icon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (value) => AuthValidators.confirmPassword(
                value,
                _passwordController.text,
              ),
              onSubmitted: (_) => _submit(),
              enabled: !loading,
            ),
            const SizedBox(height: 12),
            TermsCheckbox(enabled: !loading),
            const SizedBox(height: 16),
            if (error != null) ...[
              ErrorMessage(message: error),
              const SizedBox(height: 16),
            ],
            BotonPrimario(
              texto: 'Crear cuenta',
              cargando: loading,
              onTap: _submit,
            ),
            const SizedBox(height: 20),
            const SocialLoginSection(),
            const SizedBox(height: 12),
            _buildLoginLink(context, t, loading),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(TemaRol t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              AppAssets.registerHero,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, __, ___) => Container(color: t.suave),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: t.primario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLoginLink(BuildContext context, TemaRol t, bool loading) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '¿Ya tienes una cuenta? ',
            style: TextStyle(
              fontSize: 13.5,
              color: t.textoGris,
            ),
          ),
          TextButton(
            onPressed: loading
                ? null
                : () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.login,
                      arguments: _role,
                    ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 40),
              foregroundColor: t.primario,
            ),
            child: const Text(
              'Inicia sesión',
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
}
