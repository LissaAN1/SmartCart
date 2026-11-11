import 'package:get_it/get_it.dart';
import 'package:smartcart/features/admin/data/repository/aprobacion_repository_impl.dart';
import 'package:smartcart/features/admin/data/source/supabase_aprobacion_data_source.dart';
import 'package:smartcart/features/admin/domain/repository/aprobacion_repository.dart';
import 'package:smartcart/features/admin/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/admin/domain/usecases/get_solicitudes_pendientes_usecase.dart';
import 'package:smartcart/features/admin/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/auth/data/repository/auth_repository_impl.dart';
import 'package:smartcart/features/auth/data/repository/profile_repository_impl.dart';
import 'package:smartcart/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:smartcart/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/get_my_profile_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/activar_modo_colaborador_usecase.dart';
import 'package:smartcart/features/auth/domain/usecases/cambiar_disponibilidad_usecase.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/comercio/data/repository/comercio_repository_impl.dart';
import 'package:smartcart/features/comercio/data/source/supabase_comercio_data_source.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/domain/usecases/get_mi_comercio_usecase.dart';
import 'package:smartcart/features/comercio/domain/usecases/registrar_comercio_usecase.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Localizador de servicios (patrón Service Locator) de la app.
///
/// Es el único lugar que conoce las clases concretas. La cadena de cada
/// funcionalidad se registra de adentro hacia afuera:
/// cliente -> DataSource -> RepositoryImpl -> UseCase -> Bloc.
///
/// Las pantallas y el `AppRouter` piden lo que necesitan con `sl<LoginBloc>()`
/// y nunca construyen las dependencias a mano.
final GetIt sl = GetIt.instance;

/// Registra todas las dependencias. Se llama una sola vez en `main`, después
/// de `Supabase.initialize`. Llamarla de nuevo no duplica los registros.
void setupDependencies() {
  if (sl.isRegistered<SupabaseClient>()) return;

  // ── Infraestructura ──
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  sl.registerLazySingleton<SupabaseAuthDataSource>(
    () => SupabaseAuthDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseProfileDataSource>(
    () => SupabaseProfileDataSource(client: sl()),
  );
  sl.registerLazySingleton<SupabaseComercioDataSource>(
    () => SupabaseComercioDataSource(client: sl()),
  );

  sl.registerLazySingleton<SupabaseAprobacionDataSource>(
    () => SupabaseAprobacionDataSource(client: sl()),
  );

  // ── Repositorios: se registran con el tipo del contrato del dominio ──
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton<ComercioRepository>(
    () => ComercioRepositoryImpl(dataSource: sl()),
  );

  sl.registerLazySingleton<AprobacionRepository>(
    () => AprobacionRepositoryImpl(dataSource: sl()),
  );

  // ── Casos de uso ──
  sl.registerLazySingleton(() => SignInUseCase(auth: sl(), profiles: sl()));
  sl.registerLazySingleton(() => SignUpUseCase(auth: sl(), profiles: sl()));
  sl.registerLazySingleton(
    () => GetMyProfileUseCase(auth: sl(), profiles: sl()),
  );
  sl.registerLazySingleton(() => SignOutUseCase(auth: sl()));
  sl.registerLazySingleton(
    () => ActivarModoColaboradorUseCase(auth: sl(), profiles: sl()),
  );
  sl.registerLazySingleton(
    () => CambiarDisponibilidadUseCase(auth: sl(), profiles: sl()),
  );
  sl.registerLazySingleton(
    () => RegistrarComercioUseCase(auth: sl(), comercios: sl()),
  );
  sl.registerLazySingleton(
    () => GetMiComercioUseCase(auth: sl(), comercios: sl()),
  );
  sl.registerLazySingleton(
    () => GetSolicitudesPendientesUseCase(repository: sl()),
  );
  sl.registerLazySingleton(
    () => DecidirSolicitudUseCase(auth: sl(), profiles: sl(), repository: sl()),
  );

  // ── Blocs: uno nuevo por pantalla (factory), porque guardan estado ──
  sl.registerFactory(() => LoginBloc(signIn: sl()));
  sl.registerFactory(() => RegisterBloc(signUp: sl()));
  sl.registerFactory(() => SessionBloc(getMyProfile: sl(), signOut: sl()));
  sl.registerFactory(() => ColaboradorOnboardingBloc(activar: sl()));
  sl.registerFactory(() => DecisionSolicitudBloc(decidir: sl()));
  sl.registerFactory(() => ComercioBloc(getMine: sl(), registrar: sl()));
}
