import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe `usuario`, `usuario_rol`, `rol` y
/// `perfil_colaborador`.
///
/// Consultamos `rol` y `usuario_rol` por separado en lugar de pedir la
/// relación embebida para no depender de que exista la llave foránea.
class SupabaseProfileDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createProfile(Profile profile) async {
    try {
      await _client.from(SupabaseTables.usuario).insert({
        SupabaseColumns.usuarioId: profile.id,
        SupabaseColumns.usuarioNombre: profile.fullName,
        SupabaseColumns.usuarioCorreo: profile.email,
        SupabaseColumns.usuarioTelefono: profile.phone,
      });
      for (final role in profile.roles) {
        final roleId = await _roleId(role);
        await _client.from(SupabaseTables.usuarioRol).insert({
          SupabaseColumns.usuarioRolUsuario: profile.id,
          SupabaseColumns.usuarioRolRol: roleId,
        });
      }
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<void> createCollaboratorProfile(String userId) async {
    try {
      // Valores iniciales que exige la política perfil_colab_insert_own.
      await _client.from(SupabaseTables.perfilColaborador).insert({
        SupabaseColumns.colaboradorUsuario: userId,
        SupabaseColumns.colaboradorPuntos: 0,
        SupabaseColumns.colaboradorNivel: 1,
        SupabaseColumns.colaboradorReputacion: 0,
      });
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<Profile> getProfile(String id) async {
    try {
      final row = await _client
          .from(SupabaseTables.usuario)
          .select()
          .eq(SupabaseColumns.usuarioId, id)
          .maybeSingle();
      if (row == null) {
        throw const AuthFailure(
          'Tu cuenta no tiene un perfil registrado en SmartCart.',
        );
      }

      final assigned = await _client
          .from(SupabaseTables.usuarioRol)
          .select(SupabaseColumns.usuarioRolRol)
          .eq(SupabaseColumns.usuarioRolUsuario, id);
      final catalog = await _client
          .from(SupabaseTables.rol)
          .select('${SupabaseColumns.rolId}, ${SupabaseColumns.rolCodigo}');

      return Profile(
        id: row[SupabaseColumns.usuarioId] as String,
        fullName: row[SupabaseColumns.usuarioNombre] as String,
        email: row[SupabaseColumns.usuarioCorreo] as String,
        phone: row[SupabaseColumns.usuarioTelefono] as String?,
        roles: _toRoles(assigned, catalog),
      );
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<int> _roleId(UserRole role) async {
    final row = await _client
        .from(SupabaseTables.rol)
        .select(SupabaseColumns.rolId)
        .eq(SupabaseColumns.rolCodigo, role.dbName)
        .maybeSingle();
    if (row == null) {
      throw AuthFailure('El perfil de ${role.label} no existe en el sistema.');
    }
    return row[SupabaseColumns.rolId] as int;
  }

  /// Cruza los ids asignados a la cuenta con el catálogo de `rol`. Ignora los
  /// códigos que la app no conoce.
  Set<UserRole> _toRoles(
    List<Map<String, dynamic>> assigned,
    List<Map<String, dynamic>> catalog,
  ) {
    final assignedIds = {
      for (final row in assigned) row[SupabaseColumns.usuarioRolRol] as int,
    };
    final roles = <UserRole>{};
    for (final row in catalog) {
      if (!assignedIds.contains(row[SupabaseColumns.rolId] as int)) continue;
      final role = UserRole.fromDbName(row[SupabaseColumns.rolCodigo] as String?);
      if (role != null) roles.add(role);
    }
    return roles;
  }
}
