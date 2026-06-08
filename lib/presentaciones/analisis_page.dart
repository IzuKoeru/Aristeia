import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalisisPage extends StatefulWidget {
  const AnalisisPage({super.key});

  @override
  State<AnalisisPage> createState() => _AnalisisPageState();
}

class _AnalisisPageState extends State<AnalisisPage> {
  // Estado y datos calculados desde Supabase
  bool _cargando = true;
  List<Map<String, dynamic>> fortalezas = [];
  List<Map<String, dynamic>> mejoras = [];
  Map<String, double> promedioPorMateria = {};
  Map<String, double> fortalezasMap = {};
  Map<String, double> mejorasMap = {};

  @override
  void initState() {
    super.initState();
    _cargarAnalisis();
  }

  Future<void> _cargarAnalisis() async {
    setState(() => _cargando = true);

    try {
      final supabase = Supabase.instance.client;
      final usuario = supabase.auth.currentUser;
      if (usuario == null) {
        setState(() => _cargando = false);
        return;
      }

      final estudiante = await supabase
          .from('estudiantes')
          .select('id_estudiante')
          .eq('id_usuario', usuario.id)
          .maybeSingle();

      final idEstudiante = estudiante?['id_estudiante'];
      if (idEstudiante == null) {
        setState(() => _cargando = false);
        return;
      }

      // traer resultados y examenes relacionados para obtener id_materia
      final List<dynamic> resultados = await supabase
          .from('resultados')
          .select('porcentaje, id_examen')
          .eq('id_estudiante', idEstudiante);

      final examenIds = resultados
          .map((r) => r['id_examen'])
          .whereType<int>()
          .toSet()
          .toList();

      final List<dynamic> examenes = examenIds.isEmpty
          ? <dynamic>[]
          : await supabase
              .from('examenes')
              .select('id_examen, id_materia')
              .filter('id_examen', 'in', '(${examenIds.join(',')})');

      final List<dynamic> materias = await supabase
          .from('materias')
          .select('id_materia, nombre');

      final examenParaMateria = {
        for (var row in examenes)
          if (row['id_examen'] is int && row['id_materia'] is int)
            row['id_examen'] as int: row['id_materia'] as int,
      };

      final nombresPorMateria = {
        for (var row in materias)
          if (row['id_materia'] is int && row['nombre'] is String)
            row['id_materia'] as int: row['nombre'] as String,
      };

      final Map<String, List<double>> notasPorMateria = {};

      for (var r in resultados) {
        final examenId = r['id_examen'];
        final porcentaje = double.tryParse(r['porcentaje']?.toString() ?? '') ?? 0.0;
        if (examenId is! int) continue;
        final materiaId = examenParaMateria[examenId];
        if (materiaId == null) continue;
        final nombre = nombresPorMateria[materiaId] ?? 'Materia desconocida';
        notasPorMateria.putIfAbsent(nombre, () => []).add(porcentaje);
      }

      // calcular promedios por materia y contar examenes
      final List<Map<String, dynamic>> promedios = [];
      notasPorMateria.forEach((nombre, lista) {
        if (lista.isEmpty) return;
        final avg = lista.reduce((a, b) => a + b) / lista.length;
        promedios.add({'nombre': nombre, 'promedio': avg, 'count': lista.length});
      });

      // asegurar que todas las materias existan en el mapa (valor 0 si no hay resultados)
      promedioPorMateria = {};
      for (var row in materias) {
        final nombre = (row['nombre'] is String) ? row['nombre'] as String : 'Materia desconocida';
        promedioPorMateria[nombre] = 0.0;
      }

      for (var p in promedios) {
        promedioPorMateria[p['nombre'] as String] = (p['promedio'] as double);
      }

      // crear mapas filtrados por umbral: >=80 -> fortalezas, <80 -> mejoras
      final Map<String, double> mapFortalezas = {};
      final Map<String, double> mapMejoras = {};

      promedioPorMateria.forEach((nombre, avg) {
        if (avg >= 80.0) {
          mapFortalezas[nombre] = avg;
        } else {
          mapMejoras[nombre] = avg;
        }
      });

      // construir listas para los paneles superiores (ordenadas)
      final fortalezasEntries = mapFortalezas.entries.toList()
          ..sort((a, b) => (b.value).compareTo(a.value));
      final mejorasEntries = mapMejoras.entries.toList()
          ..sort((a, b) => (a.value).compareTo(b.value));

      final top = fortalezasEntries.take(6).map((e) => {'titulo': e.key, 'porcentaje': e.value}).toList();
      final bottom = mejorasEntries.take(6).map((e) => {'titulo': e.key, 'porcentaje': e.value}).toList();

      setState(() {
        fortalezas = top;
        mejoras = bottom;
        fortalezasMap = mapFortalezas;
        mejorasMap = mapMejoras;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error cargando analisis: $e');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            panelSuperior(
              titulo: "Fortalezas",
              icono: Icons.check_circle_outline,
              color: Colors.green,
              datos: fortalezas,
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 20),

            panelSuperior(
              titulo: "Áreas de Mejora",
              icono: Icons.warning_amber_rounded,
              color: Colors.orange,
              datos: mejoras,
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 20),

            panelInferiorChart(
              titulo: "Fortalezas",
              color: Colors.green,
              datosCompletos: fortalezasMap,
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 20),

            panelInferiorChart(
              titulo: "Áreas de Mejora",
              color: Colors.orange,
              datosCompletos: mejorasMap,
            ),
          ],
        ),
      ),
    );
  }

  Widget panelSuperior({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Map<String, dynamic>> datos,
  }) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withAlpha(38),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icono, color: color),

              const SizedBox(width: 10),

              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : ListView.builder(
                    itemCount: datos.length,
                    itemBuilder: (context, index) {
                      final item = datos[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 25),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              item['titulo'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),

                            const SizedBox(height: 10),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),

                              child: LinearProgressIndicator(
                                value: (item['porcentaje'] as double) / 100,
                                minHeight: 55,
                                color: color,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget panelInferior({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Map<String, dynamic>> datos,
  }) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.15),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(icono, color: color),

              const SizedBox(width: 10),

              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Expanded(
            child: ListView.builder(
              itemCount: datos.length,
              itemBuilder: (context, index) {
                final item = datos[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),

                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [
                          Expanded(
                            child: Text(
                              item['titulo'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),

                          Text(
                            "${item['porcentaje']}%",
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),

                        child: LinearProgressIndicator(
                          value: item['porcentaje'] / 100,
                          minHeight: 8,
                          color: color,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget panelInferiorChart({
    required String titulo,
    required Color color,
    required Map<String, double> datosCompletos,
  }) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withAlpha(38)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: color),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child: datosCompletos.isEmpty
                ? const Center(child: Text('No hay datos suficientes', style: TextStyle(color: Colors.white54)))
                : Center(child: RadarChartWidget.fromMap(dataMap: datosCompletos, color: color)),
          ),
        ],
      ),
    );
  }
}

class RadarChartWidget extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color color;

  const RadarChartWidget({super.key, required this.labels, required this.values, required this.color});

  factory RadarChartWidget.fromMap({required Map<String, double> dataMap, required Color color}) {
    final sortedKeys = dataMap.keys.toList()..sort();
    final vals = sortedKeys.map((k) => dataMap[k] ?? 0.0).toList();
    return RadarChartWidget(labels: sortedKeys, values: vals, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: _RadarChartPainter(labels: labels, values: values, color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color color;

  _RadarChartPainter({required this.labels, required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final paintFill = Paint()
      ..color = color.withAlpha(64)
      ..style = PaintingStyle.fill;

    final paintStroke = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final radius = math.min(cx, cy) - 40;

    final n = labels.length;
    if (n == 0) return;

    // draw concentric rings
    const rings = 5;
    for (int i = 1; i <= rings; i++) {
      final r = radius * (i / rings);
      canvas.drawCircle(center, r, paintLine);
    }

    // axes and label positions
    final points = <Offset>[];
    final labelStyle = TextStyle(color: Colors.white70, fontSize: 12);

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final rawValue = (i < values.length) ? values[i] : 0.0;
      final value = (rawValue.clamp(0.0, 100.0)) / 100.0;
      final px = cx + math.cos(angle) * radius * value;
      final py = cy + math.sin(angle) * radius * value;
      points.add(Offset(px, py));

      final axisX = cx + math.cos(angle) * radius;
      final axisY = cy + math.sin(angle) * radius;
      canvas.drawLine(center, Offset(axisX, axisY), paintLine);

      final outerX = cx + math.cos(angle) * (radius + 18);
      final outerY = cy + math.sin(angle) * (radius + 18);

      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 120);

      final labelOffset = Offset(outerX - tp.width / 2, outerY - tp.height / 2);
      tp.paint(canvas, labelOffset);
    }

    // polygon fill
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}