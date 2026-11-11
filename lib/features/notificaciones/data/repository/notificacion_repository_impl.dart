import 'package:smartcart/features/notificaciones/data/source/supabase_notificacion_data_source.dart';
import 'package:smartcart/features/notificaciones/domain/entities/notificacion.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';

/// Cumple NotificacionRepository delegando en el data source de Supabase.
class NotificacionRepositoryImpl implements NotificacionRepository {
  final SupabaseNotificacionDataSource _dataSource;

  NotificacionRepositoryImpl({
    required SupabaseNotificacionDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<List<Notificacion>> noLeidas(String userId) =>
      _dataSource.noLeidas(userId);

  @override
  Future<void> marcarLeidas(List<String> ids) => _dataSource.marcarLeidas(ids);
}
