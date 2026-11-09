import 'dart:developer' as developer;

import 'package:smartcart/core/constants/supabase_tables.dart';
import 'package:smartcart/core/domain/approval_status.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/data/source/supabase_error_mapper.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Único archivo que lee y escribe `usuario`, `usuario_rol`, `rol`,
/// `perfil_colaborador` y `perfil_repartidor`.
///
/// Consultamos `rol` y `usuario_rol` por separado en lugar de pedir la
/// relación embebida para no depender de que exista la llave foránea.
class SupabaseProfileDataSource {
  final SupabaseClient _client;

  SupabaseProfileDataSource({required SupabaseClient client})
      : _client = client;

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
      await _insertCollaboratorRow(userId);
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<void> createCourierProfile(String userId) async {
    try {
      // Valores que exige la política de insert: la cuenta nace pendiente y
      // sin disponibilidad; solo el administrador la aprueba (HU-24).
      await _client.from(SupabaseTables.perfilRepartidor).insert({
        SupabaseColumns.repartidorUsuario: userId,
        SupabaseColumns.repartidorEstado: ApprovalStatus.pendiente.dbName,
        SupabaseColumns.repartidorDisponible: false,
      });
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  Future<void> activateCollaboratorMode(String userId) async {
    try {
      // Cada paso comprueba antes de insertar: si un intento anterior quedó a
      // medias o la persona ya activó el modo, no se duplica nada.
      final existing = await _client
          .from(SupabaseTables.perfilColaborador)
          .select(SupabaseColumns.colaboradorUsuario)
          .eq(SupabaseColumns.colaboradorUsuario, userId)
          .maybeSingle();
      if (existing == null) await _insertCollaboratorRow(userId);

      final roleId = await _roleId(UserRole.colaborador);
      final assigned = await _client
          .from(SupabaseTables.usuarioRol)
          .select(SupabaseColumns.usuarioRolRol)
          .eq(SupabaseColumns.usuarioRolUsuario, userId)
          .eq(SupabaseColumns.usuarioRolRol, roleId)
          .maybeSingle();
      if (assigned == null) {
        await _client.from(SupabaseTables.usuarioRol).insert({
          SupabaseColumns.usuarioRolUsuario: userId,
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

  /// Valores iniciales que exige la política perfil_colab_insert_own.
  Future<void> _insertCollaboratorRow(String userId) {
    return _client.from(SupabaseTables.perfilColaborador).insert({
      SupabaseColumns.colaboradorUsuario: userId,
      SupabaseColumns.colaboradorPuntos: CollaboratorStats.initial.points,
      SupabaseColumns.colaboradorNivel: CollaboratorStats.initial.level,
      SupabaseColumns.colaboradorReputacion:
          CollaboratorStats.initial.reputation,
    });
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
      final roles = _toRoles(assigned, catalog);

      return Profile(
        id: row[SupabaseColumns.usuarioId] as String,
        fullName: row[SupabaseColumns.usuarioNombre] as String,
        email: row[SupabaseColumns.usuarioCorreo] as String,
        phone: row[SupabaseColumns.usuarioTelefono] as String?,
        roles: roles,
        collaborator: roles.contains(UserRole.colaborador)
            ? await _collaboratorStats(id)
            : null,
        courierStatus: roles.contains(UserRole.repartidor)
            ? await _courierStatus(id)
            : null,
      );
    } on AuthFailure {
      rethrow;
    } on PostgrestException catch (e) {
      throw mapPostgrestException(e);
    } on Exception {
      throw connectionFailure();
    }
  }

  /// Puntos, nivel y reputación. Si la fila no existe o no se puede leer
  /// devuelve `null` y la pantalla muestra los valores iniciales: no vale la
  /// pena impedir el ingreso por un dato que solo se muestra.
  Future<CollaboratorStats?> _collaboratorStats(String id) async {
    try {
      final row = await _client
          .from(SupabaseTables.perfilColaborador)
          .select()
          .eq(SupabaseColumns.colaboradorUsuario, id)
          .maybeSingle();
      if (row == null) return null;
      return CollaboratorStats(
        points: (row[SupabaseColumns.colaboradorPuntos] as num?)?.toInt() ?? 0,
        level: (row[SupabaseColumns.colaboradorNivel] as num?)?.toInt() ?? 1,
        reputation: (row[SupabaseColumns.colaboradorReputacion] as num?) ?? 0,
      );
    } on PostgrestException catch (e) {
      developer.log('perfil_colaborador: ${e.message}', name: 'smartcart.auth');
      return null;
    }
  }

  /// Estado de aprobación del repartidor. Ante la duda (sin fila, estado
  /// desconocido o error de lectura) se considera pendiente: es el estado
  /// más restrictivo y nunca habilita la disponibilidad por error.
  Future<ApprovalStatus> _courierStatus(String id) async {
    try {
      final row = await _client
          .from(SupabaseTables.perfilRepartidor)
          .select(SupabaseColumns.repartidorEstado)
          .eq(SupabaseColumns.repartidorUsuario, id)
          .maybeSingle();
      return ApprovalStatus.fromDbName(
              row?[SupabaseColumns.repartidorEstado] as String?) ??
          ApprovalStatus.pendiente;
    } on PostgrestException catch (e) {
      developer.log('perfil_repartidor: ${e.message}', name: 'smartcart.auth');
      return ApprovalStatus.pendiente;
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
