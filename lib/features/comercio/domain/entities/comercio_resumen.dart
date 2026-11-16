/// Lo mínimo de un comercio aprobado que necesita el cliente para
/// reconocerlo en una lista: explorar y favoritos (HU-17).
class ComercioResumen {
  final String id;
  final String nombre;
  final String direccion;
  final String ciudad;

  const ComercioResumen({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
  });
}
