import 'package:flutter/material.dart';
import 'package:smartcart/core/ui/roles/roles_ui.dart';

/// Estructura común de login y registro: fondo blanco, color del perfil,
/// flecha de regreso, scroll vertical y un ancho máximo para tablet y
/// escritorio. Con el scroll, los campos siguen alcanzables cuando se abre el
/// teclado o la pantalla es baja.
class AuthScaffold extends StatelessWidget {
  final TemaRol tema;
  final String? title;
  final Widget child;

  /// Ancho máximo del formulario en pantallas grandes.
  static const double maxContentWidth = 480;

  const AuthScaffold({
    super.key,
    required this.tema,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return TemaRolScope(
      tema: tema,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: tema.texto),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: title == null
              ? null
              : Text(
                  title!,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: tema.texto,
                  ),
                ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth >= 600 ? 32.0 : 24.0;
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: maxContentWidth),
                    child: child,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
