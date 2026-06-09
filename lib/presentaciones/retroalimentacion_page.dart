import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RetroalimentacionPage extends StatefulWidget {
  const RetroalimentacionPage({super.key});

  @override
  State<RetroalimentacionPage> createState() =>
      _RetroalimentacionPageState();
}

class _RetroalimentacionPageState
    extends State<RetroalimentacionPage> {
  bool cargando = true;
  String retroalimentacion = '';

  @override
  void initState() {
    super.initState();
    cargarResultado();
  }

  // 🧠 Retroalimentación LOCAL
  String retroalimentacionLocal(double calificacion) {
    if (calificacion >= 90) {
      return "Excelente 🔥 Dominaste el examen. Solo refuerza detalles pequeños para perfeccionar.";
    }

    if (calificacion >= 80) {
      return "Muy bien 👍 Buen desempeño, pero aún puedes mejorar con más práctica.";
    }

    if (calificacion >= 70) {
      return "Bien 📚 Entiendes el tema, pero necesitas reforzar algunos puntos clave.";
    }

    if (calificacion >= 60) {
      return "Regular ⚠️ Te falta repasar varios temas importantes.";
    }

    return "Bajo rendimiento ❌ Debes estudiar el tema desde lo básico nuevamente.";
  }

  Future<void> cargarResultado() async {
    try {
      final supabase = Supabase.instance.client;

      final usuario = supabase.auth.currentUser;

      if (usuario == null) {
        setState(() {
          retroalimentacion = "No hay sesión activa 😅";
          cargando = false;
        });
        return;
      }

      // 🔥 obtener id_estudiante real
      final estudiante = await supabase
          .from('estudiantes')
          .select('id_estudiante')
          .eq('id_usuario', usuario.id)
          .maybeSingle();

      if (estudiante == null) {
        setState(() {
          retroalimentacion =
              "No se encontró el estudiante 😅";
          cargando = false;
        });
        return;
      }

      final idEstudiante = estudiante['id_estudiante'];

      // 🔥 último examen real del estudiante
      final data = await supabase
          .from('resultados')
          .select('calificacion')
          .eq('id_estudiante', idEstudiante)
          .order('id_resultado', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        setState(() {
          retroalimentacion =
              "No hay resultados aún 😅";
          cargando = false;
        });
        return;
      }

      double calificacion =
          double.parse(data['calificacion'].toString());

      final respuesta =
          retroalimentacionLocal(calificacion);

      setState(() {
        retroalimentacion = respuesta;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        retroalimentacion =
            'No se pudo cargar la retroalimentación 😅';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.amber,
          ),
        ),
      );
    }

    // Ajustes responsivos: calcular tamaño del título según ancho de pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    // 8% del ancho de la pantalla, limitado entre 18 y 34 para legibilidad
    final titleFontSize = (screenWidth * 0.08).clamp(18.0, 34.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Retroalimentación',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber,
                ),
              ),
              child: Text(
                retroalimentacion,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}