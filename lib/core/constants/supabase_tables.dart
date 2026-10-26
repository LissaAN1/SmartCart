/// Nombres de tablas de Supabase usadas en el Sprint 1.
class SupabaseTables {
  const SupabaseTables._();

  static const usuario = 'usuario';
  static const rol = 'rol';
  static const usuarioRol = 'usuario_rol';
  static const perfilColaborador = 'perfil_colaborador';
  static const comercio = 'comercio';
}

/// Columnas que usa la autenticación. Las confirmamos contra
/// `information_schema.columns` del proyecto de Supabase (octubre de 2026).
class SupabaseColumns {
  const SupabaseColumns._();

  // usuario
  static const usuarioId = 'id_usuario';
  static const usuarioNombre = 'nombre';
  static const usuarioCorreo = 'correo';
  static const usuarioTelefono = 'telefono';

  // rol
  static const rolId = 'id_rol';
  static const rolCodigo = 'codigo';

  // usuario_rol
  static const usuarioRolUsuario = 'id_usuario';
  static const usuarioRolRol = 'id_rol';

  // perfil_colaborador: las políticas exigen estos valores iniciales
  static const colaboradorUsuario = 'id_usuario';
  static const colaboradorPuntos = 'puntos_saldo';
  static const colaboradorNivel = 'nivel';
  static const colaboradorReputacion = 'reputacion';
}
