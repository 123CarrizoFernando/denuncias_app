import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pantalla_nuevo_reporte.dart';
import 'pantalla_mapa.dart';
import 'pantalla_detalle_reporte.dart';
import 'pantalla_estadisticas.dart';

class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final usuario = supabase.auth.currentUser;
    final nombre = usuario?.userMetadata?['nombre'] ?? 'Vecino';
    final esAdministrador = usuario?.email == 'admin@muni.com';

    // 1. EL DETECTOR DE PANTALLAS: Preguntamos cuánto mide la pantalla
    final anchoPantalla = MediaQuery.of(context).size.width;
    final esPC =
        anchoPantalla >
        800; // Si tiene más de 800px, asumimos que es una computadora

    // 2. LA DECISIÓN: ¿Mostramos la vista de PC o la de Celular?
    if (esPC && esAdministrador) {
      return _construirVistaWeb(context, supabase, nombre);
    } else {
      return _construirVistaMovil(
        context,
        supabase,
        nombre,
        esAdministrador,
        usuario!.id,
      );
    }
  }

  // =====================================================================
  // VISTA PARA COMPUTADORAS (Panel de Control Profesional con Tabla)
  // =====================================================================
  Widget _construirVistaWeb(
    BuildContext context,
    SupabaseClient supabase,
    String nombre,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // MENÚ LATERAL IZQUIERDO (SIDEBAR)
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.inversePrimary,
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.location_city, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  'Municipio\nPanel Admin',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: const Text(
                    'Reportes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  selected: true,
                  selectedTileColor: Colors.white.withValues(alpha: 0.2),
                  onTap: () {}, // Ya estamos acá
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Estadísticas'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PantallaEstadisticas(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Mapa Interactivo'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PantallaMapa(),
                    ),
                  ),
                ),
                const Spacer(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar Sesión'),
                  onTap: () async => await supabase.auth.signOut(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // CONTENIDO PRINCIPAL DERECHO (LA TABLA DE DATOS)
          Expanded(
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $nombre',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Gestión de denuncias ciudadanas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // LA TABLA CON LOS REPORTES
                  Expanded(
                    child: Card(
                      elevation: 4,
                      clipBehavior: Clip.antiAlias,
                      child: StreamBuilder(
                        stream: supabase
                            .from('reportes')
                            .stream(primaryKey: ['id'])
                            .order('id', ascending: false),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final reportes =
                              snapshot.data as List<Map<String, dynamic>>;

                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal, // Permite scrollear a los lados si la tabla es muy ancha
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.grey[200],
                                ),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'ID',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Categoría',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Ubicación',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Estado',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Acción',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: reportes.map((reporte) {
                                  final estado =
                                      reporte['estado'] ?? 'Pendiente';
                                  Color colorEstado = estado == 'Resuelto'
                                      ? Colors.green
                                      : (estado == 'En progreso'
                                            ? Colors.blue
                                            : Colors.orange);

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          '#${reporte['id'].toString().substring(0, 4)}...',
                                        ),
                                      ),
                                      DataCell(
                                        Text(reporte['categoria'] ?? '-'),
                                      ),
                                      DataCell(
                                        Text(
                                          reporte['ubicacion'] ?? '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorEstado.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            estado.toUpperCase(),
                                            style: TextStyle(
                                              color: colorEstado,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        ElevatedButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PantallaDetalleReporte(
                                                    reporte: reporte,
                                                  ),
                                            ),
                                          ),
                                          child: const Text('Ver detalle'),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // VISTA PARA CELULARES (El código que ya teníamos)
  // =====================================================================
  Widget _construirVistaMovil(
    BuildContext context,
    SupabaseClient supabase,
    String nombre,
    bool esAdministrador,
    String userId,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hola, $nombre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () async => await supabase.auth.signOut(),
          ),
          if (esAdministrador)
            IconButton(
              icon: const Icon(Icons.map, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PantallaMapa()),
              ),
            ),
          if (esAdministrador)
            IconButton(
              icon: const Icon(Icons.bar_chart, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaEstadisticas(),
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder(
        stream: esAdministrador
            ? supabase
                  .from('reportes')
                  .stream(primaryKey: ['id'])
                  .order('id', ascending: false)
            : supabase
                  .from('reportes')
                  .stream(primaryKey: ['id'])
                  .eq('usuario_id', userId)
                  .order('id', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reportes = snapshot.data as List<Map<String, dynamic>>;
          if (reportes.isEmpty) {
            return const Center(
              child: Text('Todavía no tenés reportes. ¡Creá el primero!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reportes.length,
            itemBuilder: (context, index) {
              final reporte = reportes[index];
              final estado = reporte['estado'] ?? 'Pendiente';
              Color colorEstado = estado == 'Resuelto'
                  ? Colors.green
                  : (estado == 'En progreso' ? Colors.blue : Colors.orange);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: colorEstado.withValues(alpha: 0.2),
                    radius: 25,
                    child: Icon(
                      Icons.report_problem,
                      color: colorEstado,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    reporte['categoria'] ?? 'Denuncia',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        reporte['ubicacion'] ?? 'Sin ubicación',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorEstado,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estado.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PantallaDetalleReporte(reporte: reporte),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: esAdministrador
          ? null
          : FloatingActionButton.extended(
              // Ocultamos el FAB al admin
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaNuevoReporte(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'NUEVO REPORTE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
