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
  // Guardamos qué filtros eligió el usuario
  String _estadoFiltro = 'Todos';
  String _categoriaFiltro = 'Todas';

  // Las categorías rápidas que van a aparecer en los botones redondos
  // (Si en tu app usaste otras palabras, podés cambiarlas acá)
  final List<String> categorias = [
    'Todas',
    'Bache',
    'Basura',
    'Luz',
    'Vandalismo',
    'Agua',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Municipal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // FILTRO 1: Por Estado (Pendiente, Resuelto, etc.)
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt),
            tooltip: 'Filtrar por Estado',
            onSelected: (valor) => setState(() => _estadoFiltro = valor),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Todos', child: Text('Mostrar Todos')),
              const PopupMenuItem(
                value: 'Pendiente',
                child: Text('🔴 Pendientes'),
              ),
              const PopupMenuItem(
                value: 'En progreso',
                child: Text('🔵 En Progreso'),
              ),
              const PopupMenuItem(
                value: 'Resuelto',
                child: Text('🟢 Resueltos'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // FILTRO 2: La nueva barra de categorías horizontal
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final cat = categorias[index];
                final bool seleccionado = _categoriaFiltro == cat;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: seleccionado ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: seleccionado,
                    selectedColor: Theme.of(context).primaryColor,
                    backgroundColor: Colors.grey[200],
                    showCheckmark:
                        false, // Ocultamos el tilde para que sea más limpio
                    onSelected: (bool selected) {
                      setState(() {
                        _categoriaFiltro = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // EL MAPA
          Expanded(
            child: StreamBuilder(
              stream: Supabase.instance.client
                  .from('reportes')
                  .stream(primaryKey: ['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final reportes = snapshot.data as List<Map<String, dynamic>>;

                // 1. Limpiamos los que no tienen GPS
                var reportesFiltrados = reportes
                    .where((r) => r['latitud'] != null && r['longitud'] != null)
                    .toList();

                // 2. Aplicamos el filtro de ESTADO
                if (_estadoFiltro != 'Todos') {
                  reportesFiltrados = reportesFiltrados
                      .where(
                        (r) => (r['estado'] ?? 'Pendiente') == _estadoFiltro,
                      )
                      .toList();
                }

                // 3. Aplicamos el filtro de CATEGORÍA
                if (_categoriaFiltro != 'Todas') {
                  reportesFiltrados = reportesFiltrados
                      .where(
                        (r) =>
                            // Usamos contains() por si la categoría dice "Bache profundo" y buscamos "Bache"
                            (r['categoria'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(_categoriaFiltro.toLowerCase()),
                      )
                      .toList();
                }

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: reportesFiltrados.isNotEmpty
                        ? LatLng(
                            reportesFiltrados.first['latitud'],
                            reportesFiltrados.first['longitud'],
                          )
                        : const LatLng(
                            -24.7821,
                            -65.4233,
                          ), // Coordenada por defecto (Salta)
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.municipio.denuncias',
                    ),
                    MarkerLayer(
                      markers: reportesFiltrados.map((reporte) {
                        final estadoPin = reporte['estado'] ?? 'Pendiente';
                        Color colorPin = Colors.orange;
                        if (estadoPin == 'Resuelto') colorPin = Colors.green;
                        if (estadoPin == 'En progreso') colorPin = Colors.blue;

                        return Marker(
                          point: LatLng(
                            reporte['latitud'],
                            reporte['longitud'],
                          ),
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
                            child: Icon(
                              Icons.location_on,
                              color: colorPin,
                              size: 40,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
