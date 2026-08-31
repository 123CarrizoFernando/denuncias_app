import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pantalla_detalle_reporte.dart';

class PantallaEstadisticas extends StatelessWidget {
  const PantallaEstadisticas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablero Municipal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder(
        stream: Supabase.instance.client
            .from('reportes')
            .stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reportes = snapshot.data as List<Map<String, dynamic>>;

          int total = reportes.length;
          int pendientes = reportes
              .where((r) => (r['estado'] ?? 'Pendiente') == 'Pendiente')
              .length;
          int enProgreso = reportes
              .where((r) => r['estado'] == 'En progreso')
              .length;
          int resueltos = reportes
              .where((r) => r['estado'] == 'Resuelto')
              .length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Resumen de Gestión',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                _crearTarjeta(
                  context,
                  'TOTAL DE DENUNCIAS',
                  total,
                  Colors.purple,
                  Icons.summarize,
                  'Todos',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _crearTarjeta(
                        context,
                        'PENDIENTES',
                        pendientes,
                        Colors.orange,
                        Icons.warning,
                        'Pendiente',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _crearTarjeta(
                        context,
                        'EN PROGRESO',
                        enProgreso,
                        Colors.blue,
                        Icons.engineering,
                        'En progreso',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _crearTarjeta(
                  context,
                  'RESUELTOS',
                  resueltos,
                  Colors.green,
                  Icons.check_circle,
                  'Resuelto',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _crearTarjeta(
    BuildContext context,
    String titulo,
    int cantidad,
    Color color,
    IconData icono,
    String filtro,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Esto hace que la tarjeta tenga el efecto visual de "botón" al tocarla
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PantallaListaFiltrada(filtroEstado: filtro, color: color),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
            ),
          ),
          child: Column(
            children: [
              Icon(icono, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                cantidad.toString(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// NUEVA PANTALLA: Muestra la lista de reportes según la tarjeta que se tocó
class PantallaListaFiltrada extends StatelessWidget {
  final String filtroEstado;
  final Color color;

  const PantallaListaFiltrada({
    super.key,
    required this.filtroEstado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    // Si el filtro es 'Todos', traemos la tabla entera. Si no, filtramos por estado.
    final stream = filtroEstado == 'Todos'
        ? supabase
              .from('reportes')
              .stream(primaryKey: ['id'])
              .order('id', ascending: false)
        : supabase
              .from('reportes')
              .stream(primaryKey: ['id'])
              .eq('estado', filtroEstado)
              .order('id', ascending: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes: $filtroEstado'),
        backgroundColor: color,
      ),
      body: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reportes = snapshot.data as List<Map<String, dynamic>>;

          if (reportes.isEmpty) {
            return const Center(
              child: Text('No hay reportes en esta categoría.'),
            );
          }

          return ListView.builder(
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              return ListTile(
                leading: Icon(Icons.location_on, color: color),
                title: Text(
                  reporte['categoria'] ?? 'Sin categoría',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(reporte['ubicacion'] ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PantallaDetalleReporte(reporte: reporte),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
