/// Cuenta que devuelve Supabase Auth: solo su id y su correo.
class AppUser {
  final String id;
  final String email;

  const AppUser({required this.id, required this.email});
}
