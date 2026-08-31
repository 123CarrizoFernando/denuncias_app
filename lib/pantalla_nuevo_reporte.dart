import 'dart:io';
import 'dart:convert'; // Para entender la respuesta de internet

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; // Nuestra nueva herramienta
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaNuevoReporte extends StatefulWidget {
  const PantallaNuevoReporte({super.key});

  @override
  State<PantallaNuevoReporte> createState() => _PantallaNuevoReporteState();
}

class _PantallaNuevoReporteState extends State<PantallaNuevoReporte> {
  String? categoriaSeleccionada;
  final TextEditingController _descripcionController = TextEditingController();
  File? _imagenSeleccionada;
  String _direccionUbicacion = 'Buscando ubicación...';
  bool _buscandoUbicacion = true;

  double? _latitud;
  double? _longitud;

  final List<String> categorias = [
    'Escombros / Basura',
    'Auto mal estacionado',
    'Bache en la calle',
    'Luminaria rota',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      setState(() {
        _direccionUbicacion = 'El GPS está desactivado';
        _buscandoUbicacion = false;
      });
      return;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        setState(() {
          _direccionUbicacion = 'Permiso denegado';
          _buscandoUbicacion = false;
        });
        return;
      }
    }

    try {
      Position posicion = await Geolocator.getCurrentPosition();

      // NUEVO MÉTODO: Le preguntamos la calle directamente a OpenStreetMap
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${posicion.latitude}&lon=${posicion.longitude}',
      );

      // Hacemos la consulta a internet
      final respuesta = await http.get(
        url,
        headers: {'User-Agent': 'AppDenuncias'},
      );

      String calleEncontrada = 'Ubicación aproximada';

      if (respuesta.statusCode == 200) {
        final datos = json.decode(respuesta.body);
        if (datos['address'] != null) {
          final calle =
              datos['address']['road'] ?? datos['address']['pedestrian'] ?? '';
          final numero = datos['address']['house_number'] ?? '';
          final ciudad =
              datos['address']['city'] ??
              datos['address']['town'] ??
              datos['address']['village'] ??
              '';

          calleEncontrada = '$calle $numero, $ciudad'
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }
      }

      setState(() {
        _latitud = posicion.latitude;
        _longitud = posicion.longitude;
        _direccionUbicacion = calleEncontrada;
        _buscandoUbicacion = false;
      });
    } catch (e) {
      setState(() {
        _direccionUbicacion = 'Ubicación guardada en mapa';
        _buscandoUbicacion = false;
      });
    }
  }

  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);
    if (foto != null) setState(() => _imagenSeleccionada = File(foto.path));
  }

  Future<void> _enviarReporte() async {
    if (_imagenSeleccionada == null ||
        categoriaSeleccionada == null ||
        _buscandoUbicacion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completá todos los campos y esperá el GPS'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final supabase = Supabase.instance.client;
      final String extensionFoto = _imagenSeleccionada!.path.split('.').last;
      final String nombreArchivo =
          '${DateTime.now().millisecondsSinceEpoch}.$extensionFoto';

      await supabase.storage
          .from('evidencias')
          .upload(nombreArchivo, _imagenSeleccionada!);
      final String urlFoto = supabase.storage
          .from('evidencias')
          .getPublicUrl(nombreArchivo);

      await supabase.from('reportes').insert({
        'categoria': categoriaSeleccionada,
        'descripcion': _descripcionController.text,
        'ubicacion': _direccionUbicacion,
        'url_foto': urlFoto,
        'latitud': _latitud,
        'longitud': _longitud,
        'usuario_id': supabase.auth.currentUser!.id,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reporte enviado con éxito!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al enviar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Reporte')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: _tomarFoto,
              child: Container(
                height: 200,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imagenSeleccionada != null
                    ? Image.file(_imagenSeleccionada!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text('Tocar para tomar foto'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              initialValue: categoriaSeleccionada,
              items: categorias
                  .map((String c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (String? val) =>
                  setState(() => categoriaSeleccionada = val),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción adicional (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buscandoUbicacion
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_on, color: Colors.teal),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_direccionUbicacion)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _enviarReporte,
              icon: const Icon(Icons.send),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('ENVIAR REPORTE', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
