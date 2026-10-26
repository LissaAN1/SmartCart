import 'package:smartcart/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:smartcart/features/auth/domain/entities/profile.dart';
import 'package:smartcart/features/auth/domain/repository/profile_repository.dart';

/// Cumple ProfileRepository delegando en el data source de Supabase.
class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseProfileDataSource _dataSource = SupabaseProfileDataSource();

  @override
  Future<void> createProfile(Profile profile) {
    return _dataSource.createProfile(profile);
  }

  @override
  Future<void> createCollaboratorProfile(String userId) {
    return _dataSource.createCollaboratorProfile(userId);
  }

  @override
  Future<Profile> getProfile(String id) {
    return _dataSource.getProfile(id);
  }
}
