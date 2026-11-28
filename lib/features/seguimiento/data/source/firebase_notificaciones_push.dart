import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:smartcart/features/seguimiento/domain/notificaciones_push.dart';

/// Las notificaciones push con Firebase Cloud Messaging (HU-23). Es la única
/// clase que conoce Firebase.
///
/// Si el proyecto todavía no tiene la configuración de Firebase
/// (`google-services.json` / `GoogleService-Info.plist`), [activar] devuelve
/// `null` y la app sigue con los avisos dentro de la app. Los pasos para
/// configurarlo están en docs/HU23_informe_implementacion.md.
class FirebaseNotificacionesPush implements NotificacionesPush {
  bool? _listo;

  @override
  String get plataforma => switch (defaultTargetPlatform) {
        _ when kIsWeb => 'web',
        TargetPlatform.iOS || TargetPlatform.macOS => 'ios',
        _ => 'android',
      };

  /// Inicia Firebase una sola vez. `false` si no está configurado.
  Future<bool> _iniciar() async {
    final listo = _listo;
    if (listo != null) return listo;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      return _listo = true;
    } catch (e) {
      developer.log('Firebase sin configurar: $e', name: 'smartcart.push');
      return _listo = false;
    }
  }

  @override
  Future<String?> activar() async {
    if (!await _iniciar()) return null;
    try {
      final permiso = await FirebaseMessaging.instance.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      // getToken/onTokenRefresh están marcados como obsoletos en favor de
      // register/onRegistered, que entregan un id de instalación para otro
      // modo de envío. La Edge Function usa la API HTTP v1 con el token de
      // registro, que es lo que devuelven estos dos y siguen funcionando.
      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      developer.log('No se obtuvo el token push: $e', name: 'smartcart.push');
      return null;
    }
  }

  @override
  Stream<String> get tokenRenovado => _siListo(
        // ignore: deprecated_member_use
        () => FirebaseMessaging.instance.onTokenRefresh,
      );

  @override
  Stream<AvisoPush> get enPrimerPlano => _siListo(
        () => FirebaseMessaging.onMessage.map(
          (m) => AvisoPush(
            titulo: m.notification?.title ?? 'SmartCart',
            mensaje: m.notification?.body ?? '',
          ),
        ),
      );

  @override
  Stream<void> get avisoAbierto => _siListo(
        () => FirebaseMessaging.onMessageOpenedApp.map((_) {}),
      );

  /// El stream de Firebase si está configurado; uno vacío si no.
  Stream<T> _siListo<T>(Stream<T> Function() stream) async* {
    if (await _iniciar()) yield* stream();
  }
}
