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
  final String correoAdmin = 'admin@muni.com';

  // NUEVO: Controlador para el campo de texto del chat
  final TextEditingController _mensajeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    estadoActual = widget.reporte['estado'] ?? 'Pendiente';
  }

  Future<void> _cambiarEstado(String nuevoEstado) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await Supabase.instance.client
          .from('reportes')
          .update({'estado': nuevoEstado})
          .eq('id', widget.reporte['id']);
      if (mounted) {
        setState(() => estadoActual = nuevoEstado);
        Navigator.pop(context);
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

  // NUEVA FUNCIÓN: Enviar un mensaje al chat
  Future<void> _enviarMensaje(bool esAdministrador) async {
    if (_mensajeController.text.trim().isEmpty) {
      return; // No enviar mensajes vacíos
    }

    final textoMensaje = _mensajeController.text.trim();
    _mensajeController
        .clear(); // Limpiamos la cajita rápido para que sea cómodo

    try {
      await Supabase.instance.client.from('comentarios').insert({
        'reporte_id': widget.reporte['id'],
        'mensaje': textoMensaje,
        'es_admin': esAdministrador,
      });
    } catch (e) {
      if (mounted) {
        // Ahora la barrita nos va a mostrar el error exacto que tira la base de datos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(
              seconds: 5,
            ), // Le damos más tiempo para leerlo
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = Supabase.instance.client.auth.currentUser;
    final esAdministrador = usuarioActual?.email == correoAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir por WhatsApp',
            onPressed: _compartirPorWhatsApp,
          ),
        ],
      ),
      // Usamos un Column general para dejar la barra de chat fija abajo
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // FOTO
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
                        // ESTADO
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

                        // DATOS
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
                          widget.reporte['descripcion'] ??
                              'Sin detalles adicionales',
                          style: const TextStyle(fontSize: 16),
                        ),

                        // BOTONES DE ADMIN
                        if (esAdministrador) ...[
                          const SizedBox(height: 24),
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

                        // ==========================================
                        // SECCIÓN DE COMENTARIOS (CHAT)
                        // ==========================================
                        const Divider(height: 40, thickness: 2),
                        const Text(
                          'Mensajes / Actualizaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        StreamBuilder(
                          // Leemos los comentarios que correspondan a este reporte específico
                          stream: Supabase.instance.client
                              .from('comentarios')
                              .stream(primaryKey: ['id'])
                              .eq('reporte_id', widget.reporte['id'])
                              .order('created_at', ascending: true),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final comentarios =
                                snapshot.data as List<Map<String, dynamic>>;

                            if (comentarios.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No hay mensajes todavía.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comentarios.length,
                              itemBuilder: (context, index) {
                                final c = comentarios[index];
                                final esMensajeAdmin = c['es_admin'] == true;

                                return Align(
                                  // Alineamos a la derecha si es la Muni, a la izq si es el vecino
                                  alignment: esMensajeAdmin
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: esMensajeAdmin
                                          ? Colors.teal[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          esMensajeAdmin
                                              ? 'Municipalidad'
                                              : 'Vecino',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: esMensajeAdmin
                                                ? Colors.teal[800]
                                                : Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(c['mensaje'] ?? ''),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // BARRA INFERIOR FIJA PARA ESCRIBIR MENSAJES
          // ==========================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: InputDecoration(
                      hintText: 'Escribí un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _enviarMensaje(esAdministrador),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
