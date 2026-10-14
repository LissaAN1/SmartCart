import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<void> _connection;

  @override
  void initState() {
    super.initState();
    _connection = _checkConnection();
  }

  Future<void> _checkConnection() async {
    await _supabase.from(SupabaseTables.rol).select('id_rol').limit(1);
  }

  void _retry() => setState(() => _connection = _checkConnection());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartCart')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 72),
              const SizedBox(height: 12),
              Text(
                'Compara menos, decide mejor',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              FutureBuilder<void>(
                future: _connection,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const CircularProgressIndicator();
                  }
                  final ok = !snapshot.hasError;
                  return Column(
                    children: [
                      Icon(
                        ok ? Icons.cloud_done : Icons.cloud_off,
                        color: ok ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(ok
                          ? 'Conectado a Supabase'
                          : 'Error de conexión: ${snapshot.error}'),
                      if (!ok)
                        TextButton(
                            onPressed: _retry, child: const Text('Reintentar')),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text('Login y registro: pendiente (equipo auth)'),
            ],
          ),
        ),
      ),
    );
  }
}
