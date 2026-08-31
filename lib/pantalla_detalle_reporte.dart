import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PantallaDetalleReporte extends StatefulWidget {
  final Map<String, dynamic> reporte;

  const PantallaDetalleReporte({super.key, required this.reporte});

  @override
  State<PantallaDetalleReporte> createState() => _PantallaDetalleReporteState();
}

class _PantallaDetalleReporteState extends State<PantallaDetalleReporte> {
  late String estadoActual;

  // ACÁ DEFINIMOS EL CORREO DEL ADMINISTRADOR DE LA MUNI
  final String correoAdmin = 'admin@muni.com';

  @override
  void initState() {
    super.initState();
    // Por defecto, si un reporte no tiene estado en la base de datos, es Pendiente
    estadoActual = widget.reporte['estado'] ?? 'Pendiente';
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Le avisamos a Supabase que actualice el estado de este reporte específico
      await Supabase.instance.client
          .from('reportes')
          .update({'estado': nuevoEstado})
          .eq(
            'id',
            widget.reporte['id'],
          ); // Buscamos por el ID único del reporte

      if (mounted) {
        setState(() {
          estadoActual = nuevoEstado;
        });
        Navigator.pop(context); // Cierra el circulito de carga
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Estado actualizado con éxito!')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _compartirPorWhatsApp() async {
    final texto =
        '🚨 *Nuevo Reporte Municipal*\n\n'
        '📋 *Categoría:* ${widget.reporte['categoria'] ?? 'N/A'}\n'
        '📍 *Ubicación:* ${widget.reporte['ubicacion'] ?? 'N/A'}\n'
        '📝 *Detalle:* ${widget.reporte['descripcion'] ?? 'N/A'}\n'
        '🚦 *Estado:* $estadoActual';

    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = Supabase.instance.client.auth.currentUser;
    // Verificamos si el que está mirando la pantalla es el empleado municipal
    final esAdministrador = usuarioActual?.email == correoAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // ACÁ AGREGAMOS EL BOTÓN DE COMPARTIR QUE FALTABA
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir por WhatsApp',
            onPressed: _compartirPorWhatsApp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FOTO DE LA DENUNCIA
            if (widget.reporte['url_foto'] != null)
              Image.network(
                widget.reporte['url_foto'],
                height: 300,
                fit: BoxFit.cover,
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ESTADO ACTUAL (Con colores)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estadoActual == 'Resuelto'
                          ? Colors.green
                          : (estadoActual == 'En progreso'
                                ? Colors.blue
                                : Colors.orange),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estadoActual.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // DATOS DE LA DENUNCIA
                  Text(
                    widget.reporte['categoria'] ?? 'Sin categoría',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.reporte['ubicacion'] ??
                              'Ubicación desconocida',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Descripción del vecino:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.reporte['descripcion'] ?? 'Sin detalles adicionales',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 40),

                  // BOTONES SECRETOS (Solo los ve el administrador)
                  if (esAdministrador) ...[
                    const Divider(),
                    const Text(
                      'GESTIÓN MUNICIPAL (Oculto para vecinos)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: estadoActual == 'En progreso'
                              ? null
                              : () => _cambiarEstado('En progreso'),
                          icon: const Icon(Icons.engineering),
                          label: const Text('En Progreso'),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: estadoActual == 'Resuelto'
                              ? null
                              : () => _cambiarEstado('Resuelto'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Resuelto'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
