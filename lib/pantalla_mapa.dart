import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pantalla_detalle_reporte.dart';

class PantallaMapa extends StatefulWidget {
  const PantallaMapa({super.key});

  @override
  State<PantallaMapa> createState() => _PantallaMapaState();
}

class _PantallaMapaState extends State<PantallaMapa> {
  // Esta variable guarda el filtro que el usuario tiene seleccionado
  String _filtroActual = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Interactivo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // MENÚ DESPLEGABLE PARA FILTRAR
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, size: 28),
            tooltip: 'Filtrar reportes',
            onSelected: (String valorSeleccionado) {
              setState(() {
                _filtroActual = valorSeleccionado;
              });
            },
            itemBuilder: (BuildContext context) {
              return ['Todos', 'Pendiente', 'En progreso', 'Resuelto'].map((
                String opcion,
              ) {
                return PopupMenuItem<String>(
                  value: opcion,
                  child: Text(opcion),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
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

          // 1. Descartamos los viejos sin GPS
          var reportesFiltrados = reportes
              .where((r) => r['latitud'] != null && r['longitud'] != null)
              .toList();

          // 2. Filtramos. Si el reporte no tiene estado, asumimos que es 'Pendiente'
          if (_filtroActual != 'Todos') {
            reportesFiltrados = reportesFiltrados.where((r) {
              final estado = r['estado'] ?? 'Pendiente';
              return estado == _filtroActual;
            }).toList();
          }

          return FlutterMap(
            options: MapOptions(
              initialCenter: reportesFiltrados.isNotEmpty
                  ? LatLng(
                      reportesFiltrados.first['latitud'],
                      reportesFiltrados.first['longitud'],
                    )
                  : const LatLng(-24.7821, -65.4233),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.municipio.denuncias',
              ),
              MarkerLayer(
                markers: reportesFiltrados.map((reporte) {
                  // LECTURA DE COLORES CORREGIDA
                  final estadoPin = reporte['estado'] ?? 'Pendiente';
                  Color colorPin = Colors.orange; // Naranja por defecto

                  if (estadoPin == 'Resuelto') colorPin = Colors.green;
                  if (estadoPin == 'En progreso') colorPin = Colors.blue;

                  return Marker(
                    point: LatLng(reporte['latitud'], reporte['longitud']),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PantallaDetalleReporte(reporte: reporte),
                          ),
                        );
                      },
                      child: Icon(Icons.location_on, color: colorPin, size: 40),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
