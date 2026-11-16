import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/di/injector.dart';
import 'package:smartcart/core/pagination/paginated_bloc.dart';
import 'package:smartcart/features/aprobaciones/domain/entities/solicitud.dart';
import 'package:smartcart/features/aprobaciones/domain/repository/solicitudes_repository.dart';
import 'package:smartcart/features/aprobaciones/domain/usecases/decidir_solicitud_usecase.dart';
import 'package:smartcart/features/aprobaciones/presentation/bloc/decision_solicitud_bloc.dart';
import 'package:smartcart/features/notificaciones/domain/repository/notificacion_repository.dart';
import 'package:smartcart/features/notificaciones/presentation/bloc/notificaciones_bloc.dart';
import 'package:smartcart/features/auth/domain/repository/auth_repository.dart';
import 'package:smartcart/features/catalog/data/repository/catalogo_repository_impl.dart';
import 'package:smartcart/features/catalog/data/source/file_picker_selector_csv.dart';
import 'package:smartcart/features/catalog/domain/entities/producto.dart';
import 'package:smartcart/features/catalog/domain/repository/catalogo_repository.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_archivo_csv.dart';
import 'package:smartcart/features/catalog/domain/usecases/cargar_productos_csv_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/crear_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/editar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/eliminar_producto_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_comercio_aprobado_usecase.dart';
import 'package:smartcart/features/catalog/domain/usecases/get_productos_usecase.dart';
import 'package:smartcart/features/catalog/presentation/bloc/carga_csv_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/producto_form_bloc.dart';
import 'package:smartcart/features/prices/data/repository/precios_repository_impl.dart';
import 'package:smartcart/features/prices/domain/repository/precios_repository.dart';
import 'package:smartcart/features/prices/domain/usecases/actualizar_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/get_ficha_precio_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_promocion_usecase.dart';
import 'package:smartcart/features/prices/domain/usecases/quitar_promocion_usecase.dart';
import 'package:smartcart/features/prices/presentation/bloc/precio_producto_bloc.dart';
import 'package:smartcart/features/prices/domain/usecases/guardar_producto_usecase.dart';
import 'package:smartcart/features/catalog/data/source/file_picker_selector_imagen.dart';
import 'package:smartcart/features/catalog/domain/repository/selector_imagen.dart';
import 'package:smartcart/features/catalog/presentation/bloc/catalogo_lista_bloc.dart';
import 'package:smartcart/features/catalog/presentation/bloc/inventario_bloc.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_bloc.dart';
import 'package:smartcart/features/comercio/domain/repository/comercio_repository.dart';
import 'package:smartcart/features/comercio/presentation/bloc/comercio_bloc.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';
import 'package:smartcart/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:smartcart/features/login/ui/bloc/login_bloc.dart';
import 'package:smartcart/features/register/ui/bloc/register_bloc.dart';
import 'package:smartcart/features/session/ui/bloc/session_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  tearDown(() => sl.reset());

  test('registra los repositorios con el tipo del contrato del dominio', () {
    setupDependencies();

    expect(sl.isRegistered<AuthRepository>(), isTrue);
    expect(sl.isRegistered<ProfileRepository>(), isTrue);
    expect(sl.isRegistered<ComercioRepository>(), isTrue);
    expect(sl.isRegistered<SignInUseCase>(), isTrue);
  });

  test('los Bloc se registran como fábrica: cada pantalla recibe uno nuevo', () {
    setupDependencies();

    expect(sl.isRegistered<LoginBloc>(), isTrue);
    expect(sl.isRegistered<RegisterBloc>(), isTrue);
    expect(sl.isRegistered<SessionBloc>(), isTrue);
    expect(sl.isRegistered<ColaboradorOnboardingBloc>(), isTrue);
    expect(sl.isRegistered<ComercioBloc>(), isTrue);
    expect(sl.isRegistered<NotificacionesBloc>(), isTrue);
    expect(sl.isRegistered<DecisionSolicitudBloc>(), isTrue);
    expect(sl.isRegistered<PaginatedBloc<Solicitud>>(), isTrue);
  });

  test('HU-24: repositorios y caso de uso de aprobación registrados', () {
    setupDependencies();

    expect(sl.isRegistered<SolicitudesRepository>(), isTrue);
    expect(sl.isRegistered<NotificacionRepository>(), isTrue);
    expect(sl.isRegistered<DecidirSolicitudUseCase>(), isTrue);
  });

  test('HU-10: el catálogo se registra con los tipos del contrato', () {
    setupDependencies();

    expect(sl.isRegistered<CatalogoRepository>(), isTrue);
    expect(sl.isRegistered<SelectorArchivoCsv>(), isTrue);
    expect(sl.isRegistered<GetComercioAprobadoUseCase>(), isTrue);
    expect(sl.isRegistered<GetProductosUseCase>(), isTrue);
    expect(sl.isRegistered<CrearProductoUseCase>(), isTrue);
    expect(sl.isRegistered<EditarProductoUseCase>(), isTrue);
    expect(sl.isRegistered<EliminarProductoUseCase>(), isTrue);
    expect(sl.isRegistered<CargarProductosCsvUseCase>(), isTrue);
    expect(sl.isRegistered<ProductoFormBloc>(), isTrue);
    expect(sl.isRegistered<CargaCsvBloc>(), isTrue);
    expect(sl.isRegistered<PaginatedBloc<Producto>>(), isTrue);
  });

  group('HU-10: el localizador arma la cadena completa del catálogo', () {
    // Un cliente de Supabase sin conexión: basta para construir las
    // dependencias, porque ninguna llama a la red al crearse.
    setUp(() {
      setupDependencies();
      sl.unregister<SupabaseClient>();
      sl.registerLazySingleton<SupabaseClient>(
        () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
      );
    });

    test('los Bloc son fábricas: cada pantalla recibe uno nuevo', () {
      expect(identical(sl<CargaCsvBloc>(), sl<CargaCsvBloc>()), isFalse);
      expect(
        identical(sl<PaginatedBloc<Producto>>(), sl<PaginatedBloc<Producto>>()),
        isFalse,
      );
    });

    test('los casos de uso son únicos y comparten el repositorio', () {
      expect(
        identical(sl<CrearProductoUseCase>(), sl<CrearProductoUseCase>()),
        isTrue,
      );
      expect(sl<CatalogoRepository>(), isA<CatalogoRepositoryImpl>());
      expect(sl<SelectorArchivoCsv>(), isA<FilePickerSelectorCsv>());
    });

    test('el formulario acepta un producto para editar y null para crear', () {
      const producto = Producto(
        id: 'p1',
        nombre: 'Arroz blanco',
        idCategoria: 'cat-super',
        categoria: 'Super',
      );

      expect(sl<ProductoFormBloc>(param1: producto).editando, producto);
      expect(sl<ProductoFormBloc>(param1: null).editando, isNull);
    });
  });

  test('HU-11: precios y promociones se registran con el tipo del contrato',
      () {
    setupDependencies();

    expect(sl.isRegistered<PreciosRepository>(), isTrue);
    expect(sl.isRegistered<GetFichaPrecioUseCase>(), isTrue);
    expect(sl.isRegistered<ActualizarPrecioUseCase>(), isTrue);
    expect(sl.isRegistered<GuardarPromocionUseCase>(), isTrue);
    expect(sl.isRegistered<QuitarPromocionUseCase>(), isTrue);
    expect(sl.isRegistered<PrecioProductoBloc>(), isTrue);
    expect(sl.isRegistered<GuardarProductoUseCase>(), isTrue);
    expect(sl.isRegistered<SelectorImagen>(), isTrue);
    expect(sl.isRegistered<InventarioBloc>(), isTrue);
  });

  test('HU-11: el Bloc de precios recibe el producto y usa el repositorio real',
      () {
    setupDependencies();
    sl.unregister<SupabaseClient>();
    sl.registerLazySingleton<SupabaseClient>(
      () => SupabaseClient('http://localhost:54321', 'llave-de-prueba'),
    );
    const producto = Producto(
      id: 'p1',
      nombre: 'Arroz blanco',
      idCategoria: 'cat-super',
      categoria: 'Super',
    );

    final bloc = sl<PrecioProductoBloc>(param1: producto);

    expect(bloc.producto, producto);
    expect(identical(bloc, sl<PrecioProductoBloc>(param1: producto)), isFalse);
    expect(sl<PreciosRepository>(), isA<PreciosRepositoryImpl>());
    expect(sl<SelectorImagen>(), isA<FilePickerSelectorImagen>());
    // La lista del catálogo agrega búsqueda y filtro por categoría.
    expect(sl<PaginatedBloc<Producto>>(), isA<CatalogoListaBloc>());
    expect(sl<InventarioBloc>(), isNot(same(sl<InventarioBloc>())));
    expect(sl<GuardarProductoUseCase>(), same(sl<GuardarProductoUseCase>()));
  });

  test('llamar dos veces a setupDependencies no duplica los registros', () {
    setupDependencies();

    expect(setupDependencies, returnsNormally);
  });
}
