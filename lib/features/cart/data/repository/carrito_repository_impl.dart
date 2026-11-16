import 'package:smartcart/features/cart/data/source/supabase_carrito_data_source.dart';
import 'package:smartcart/features/cart/domain/entities/item_carrito.dart';
import 'package:smartcart/features/cart/domain/repository/carrito_repository.dart';

/// Cumple CarritoRepository delegando en el data source de Supabase.
class CarritoRepositoryImpl implements CarritoRepository {
  final SupabaseCarritoDataSource _dataSource;

  CarritoRepositoryImpl({required SupabaseCarritoDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<ItemCarrito>> obtener() => _dataSource.obtener();

  @override
  Future<int> agregar(String idProducto) => _dataSource.agregar(idProducto);

  @override
  Future<void> cambiarCantidad(String idProducto, int cantidad) =>
      _dataSource.cambiarCantidad(idProducto, cantidad);

  @override
  Future<void> quitar(String idProducto) => _dataSource.quitar(idProducto);
}
