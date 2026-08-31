import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pantalla_principal.dart';
import 'pantalla_login.dart'; // Importamos la nueva pantalla

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hekkzpckyolyuwdokfde.supabase.co',
    publishableKey: 'sb_publishable_5wwDhfZv4eWIuCWtUbarVA_ON_dVb6j', // Pegá tus datos reales acá
  );

  runApp(const AppDenuncias());
}

class AppDenuncias extends StatelessWidget {
  const AppDenuncias({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reportes Ciudadanos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // En vez de ir a la PantallaPrincipal directo, lo mandamos al "semáforo"
      home: const SemaforoAuth(),
    );
  }
}

// Este widget decide qué pantalla mostrar dependiendo de si hay sesión iniciada
class SemaforoAuth extends StatefulWidget {
  const SemaforoAuth({super.key});

  @override
  State<SemaforoAuth> createState() => _SemaforoAuthState();
}

class _SemaforoAuthState extends State<SemaforoAuth> {
  @override
  void initState() {
    super.initState();
    // Se queda "escuchando" por si el usuario entra o sale de su cuenta
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Revisamos si hay una sesión activa en Supabase
    final sesion = Supabase.instance.client.auth.currentSession;

    // Si la sesión está vacía, mostramos Login. Si no, entra a la app.
    if (sesion == null) {
      return const PantallaLogin();
    } else {
      return const PantallaPrincipal();
    }
  }
}
