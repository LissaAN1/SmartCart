import 'package:flutter_test/flutter_test.dart';
import 'package:smartcart/core/domain/user_role.dart';
import 'package:smartcart/features/auth/domain/entities/app_user.dart';
import 'package:smartcart/features/auth/domain/entities/collaborator_stats.dart';
import 'package:smartcart/features/auth/domain/failures/auth_failure.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_event.dart';
import 'package:smartcart/features/colaborador/presentation/bloc/colaborador_onboarding_state.dart';

import '../support/fakes.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.auth.current = const AppUser(id: 'u1', email: 'ana@correo.com');
    env.profiles.stored = profileWith({UserRole.cliente});
  });

  group('ActivarModoColaboradorUseCase', () {
    test('un cliente que acepta las condiciones recibe el rol colaborador '
        'y conserva el de cliente', () async {
      final profile = await env.activarColaborador(acceptedTerms: true);

      expect(env.profiles.activateCalls, 1);
      expect(profile.roles, {UserRole.cliente, UserRole.colaborador});
      expect(profile.collaborator?.points, 0);
      expect(profile.collaborator?.level, 1);
      expect(profile.collaborator?.reputation, 0);
    });

    test('sin aceptar las condiciones no activa nada', () async {
      await expectLater(
        env.activarColaborador(acceptedTerms: false),
        throwsA(isA<AuthFailure>().having(
            (e) => e.message, 'message', contains('condiciones de uso'))),
      );
      expect(env.profiles.activateCalls, 0);
      expect(env.profiles.stored!.roles, {UserRole.cliente});
    });

    test('si ya es colaborador no duplica el perfil', () async {
      env.profiles.stored = profileWith(
        {UserRole.cliente, UserRole.colaborador},
        collaborator: CollaboratorStats.initial,
      );

      final profile = await env.activarColaborador(acceptedTerms: true);

      expect(env.profiles.activateCalls, 0);
      expect(profile.hasRole(UserRole.colaborador), isTrue);
    });

    test('exige el perfil de cliente', () async {
      env.profiles.stored = profileWith({UserRole.repartidor});

      await expectLater(
        env.activarColaborador(acceptedTerms: true),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.profiles.activateCalls, 0);
    });

    test('exige una sesión iniciada', () async {
      env.auth.current = null;

      await expectLater(
        env.activarColaborador(acceptedTerms: true),
        throwsA(isA<AuthFailure>()),
      );
      expect(env.profiles.activateCalls, 0);
    });

    test('propaga el error de la base de datos', () async {
      env.profiles.activateError =
          const AuthFailure('No tienes permiso para realizar esta acción.');

      await expectLater(
        env.activarColaborador(acceptedTerms: true),
        throwsA(isA<AuthFailure>()
            .having((e) => e.message, 'message', contains('permiso'))),
      );
    });
  });

  group('ColaboradorOnboardingBloc', () {
    Matcher status(ColaboradorOnboardingStatus s) =>
        isA<ColaboradorOnboardingState>().having((x) => x.status, 'status', s);

    test('aceptar y presionar Activar emite loading y success con el perfil',
        () async {
      final bloc = env.colaboradorBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ColaboradorOnboardingState>()
              .having((s) => s.termsAccepted, 'terms', true),
          status(ColaboradorOnboardingStatus.loading),
          isA<ColaboradorOnboardingState>()
              .having((s) => s.status, 'status',
                  ColaboradorOnboardingStatus.success)
              .having((s) => s.profile?.hasRole(UserRole.colaborador),
                  'colaborador', true),
        ]),
      );
      bloc
        ..add(TermsToggled(true))
        ..add(ActivationSubmitted());
      await expectation;
    });

    test('Activar sin aceptar las condiciones falla y pide aceptarlas',
        () async {
      final bloc = env.colaboradorBloc();
      addTearDown(bloc.close);

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          status(ColaboradorOnboardingStatus.loading),
          isA<ColaboradorOnboardingState>()
              .having((s) => s.status, 'status',
                  ColaboradorOnboardingStatus.failure)
              .having((s) => s.errorMessage, 'error',
                  contains('condiciones de uso')),
        ]),
      );
      bloc.add(ActivationSubmitted());
      await expectation;
      expect(env.profiles.activateCalls, 0);
    });

    test('marcar las condiciones después de un error borra el mensaje',
        () async {
      final bloc = env.colaboradorBloc();
      addTearDown(bloc.close);

      bloc.add(ActivationSubmitted());
      await bloc.stream
          .firstWhere((s) => s.status == ColaboradorOnboardingStatus.failure);
      bloc.add(TermsToggled(true));
      final next = await bloc.stream.first;

      expect(next.errorMessage, isNull);
      expect(next.termsAccepted, isTrue);
    });
  });
}
