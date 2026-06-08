import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgresoPage extends StatefulWidget {
  const ProgresoPage({super.key});

  @override
  State<ProgresoPage> createState() => _ProgresoPageState();
}

class _ProgresoPageState extends State<ProgresoPage> {
  bool _cargando = true;
  int _examenesRealizados = 0;
  double _promedioGeneral = 0.0;
  String _periodo = 'Sin periodo';
  int _materiasDominadas = 0;

  List<String> _materiasDisponibles = [];
  String _materiaSeleccionada = '';
  DateTime? _fechaInicioUso;
  final List<String> _filtrosTiempo = [
    '1 Mes',
    '3 Meses',
    '6 Meses',
    '1 Año',
    'Actual',
  ];
  String _filtroSeleccionado = 'Actual';

  final Map<String, List<ExamScore>> _calificacionesPorMateria = {};
  final Map<String, int> _materiaIds = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosProgreso();
  }

  Future<void> _cargarDatosProgreso() async {
    setState(() => _cargando = true);

    try {
      final supabase = Supabase.instance.client;
      final usuarioActual = supabase.auth.currentUser;

      if (usuarioActual == null) {
        setState(() => _cargando = false);
        return;
      }

      final estudianteRes = await supabase
          .from('estudiantes')
          .select('id_estudiante')
          .eq('id_usuario', usuarioActual.id)
          .maybeSingle();

      final idEstudiante = estudianteRes?['id_estudiante'];
      if (idEstudiante == null) {
        setState(() => _cargando = false);
        return;
      }

      final progresoRes = await supabase
          .from('progreso')
          .select('periodo, avance')
          .eq('id_estudiante', idEstudiante)
          .maybeSingle();

      final avanceProgreso =
          double.tryParse(progresoRes?['avance']?.toString() ?? '') ?? 0.0;
      _periodo = _formatearPeriodo(progresoRes?['periodo']);

      final List<dynamic> resultados = await supabase
          .from('resultados')
          .select('porcentaje, id_examen, fecha_presentacion')
          .eq('id_estudiante', idEstudiante);

      final examenIds = resultados
          .map((row) => row['id_examen'])
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

      _materiasDisponibles = nombresPorMateria.values.toSet().toList()..sort();
      _materiaSeleccionada = _materiasDisponibles.isEmpty
          ? ''
          : _materiasDisponibles.first;

      _materiaIds.clear();
      for (var row in materias) {
        if (row['id_materia'] is int && row['nombre'] is String) {
          _materiaIds[row['nombre'] as String] = row['id_materia'] as int;
        }
      }

      _calificacionesPorMateria.clear();
      final Map<String, List<double>> notasPorMateria = {};
      DateTime? inicioUso;

      for (var fila in resultados) {
        final examenId = fila['id_examen'];
        final porcentaje =
            double.tryParse(fila['porcentaje']?.toString() ?? '') ?? 0.0;
        if (examenId is! int) continue;

        final materiaId = examenParaMateria[examenId];
        if (materiaId == null) continue;

        final materiaNombre =
            nombresPorMateria[materiaId] ?? 'Materia desconocida';
        notasPorMateria.putIfAbsent(materiaNombre, () => []).add(porcentaje);

        final fechaTexto = fila['fecha_presentacion']?.toString();
        final fecha = fechaTexto != null ? DateTime.tryParse(fechaTexto) : null;
        if (fecha == null) continue;

        inicioUso = inicioUso == null || fecha.isBefore(inicioUso)
            ? fecha
            : inicioUso;
        _calificacionesPorMateria
            .putIfAbsent(materiaNombre, () => [])
            .add(ExamScore(fecha: fecha, porcentaje: porcentaje));
      }
      _fechaInicioUso = inicioUso;

      int materiasDominadas = 0;
      for (var materia in _materiasDisponibles) {
        final notaLista = notasPorMateria[materia] ?? [];
        final promedioMateria = notaLista.isEmpty
            ? 0.0
            : notaLista.reduce((a, b) => a + b) / notaLista.length;
        if (promedioMateria >= 100) {
          materiasDominadas++;
        }
      }

      final promedioGeneralResultados = notasPorMateria.isEmpty
          ? 0.0
          : notasPorMateria.values
                    .map(
                      (lista) => lista.reduce((a, b) => a + b) / lista.length,
                    )
                    .reduce((a, b) => a + b) /
                notasPorMateria.length;

      setState(() {
        _examenesRealizados = resultados.length;
        _promedioGeneral = avanceProgreso > 0
            ? avanceProgreso
            : promedioGeneralResultados;
        _materiasDominadas = materiasDominadas;
        _cargando = false;
      });
    } catch (error) {
      debugPrint('Error cargando datos de progreso: $error');
      setState(() => _cargando = false);
    }
  }

  String _formatearPeriodo(dynamic rawPeriodo) {
    final periodoTexto = rawPeriodo?.toString() ?? '';
    if (periodoTexto.isEmpty) {
      return 'Sin periodo';
    }

    final periodoNumerico = double.tryParse(periodoTexto);
    if (periodoNumerico != null) {
      final horas = periodoNumerico / 60.0;
      return '${horas.toStringAsFixed(1)}h';
    }

    try {
      final fecha = DateTime.parse(periodoTexto);
      final diferencia = DateTime.now().difference(fecha).inMinutes / 60.0;
      if (diferencia < 0) return 'Sin periodo';
      return '${diferencia.toStringAsFixed(1)}h';
    } catch (_) {
      return periodoTexto;
    }
  }

  List<ExamScore> _filtrarPuntos(String materia) {
    final puntos = List<ExamScore>.from(
      _calificacionesPorMateria[materia] ?? [],
    );
    puntos.sort((a, b) => a.fecha.compareTo(b.fecha));

    if (_filtroSeleccionado == 'Actual') return puntos;

    final ahora = DateTime.now();
    late final DateTime limite;
    switch (_filtroSeleccionado) {
      case '1 Mes':
        limite = ahora.subtract(const Duration(days: 30));
        break;
      case '3 Meses':
        limite = ahora.subtract(const Duration(days: 90));
        break;
      case '6 Meses':
        limite = ahora.subtract(const Duration(days: 180));
        break;
      case '1 Año':
        limite = ahora.subtract(const Duration(days: 365));
        break;
      default:
        limite = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return puntos.where((p) => p.fecha.isAfter(limite)).toList();
  }

  bool _filtroDisponible(String filtro) {
    if (filtro == 'Actual') return true;
    if (_fechaInicioUso == null) return false;

    final diasUso = DateTime.now().difference(_fechaInicioUso!).inDays;
    switch (filtro) {
      case '1 Mes':
        return diasUso >= 30;
      case '3 Meses':
        return diasUso >= 90;
      case '6 Meses':
        return diasUso >= 180;
      case '1 Año':
        return diasUso >= 365;
      default:
        return true;
    }
  }

  void _seleccionarFiltro(String filtro) {
    setState(() => _filtroSeleccionado = filtro);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    final selectedMateria = _materiaSeleccionada;
    final chartPoints = selectedMateria.isEmpty
        ? <ExamScore>[]
        : _filtrarPuntos(selectedMateria);
    final filtroNoDisponible =
        selectedMateria.isNotEmpty && !_filtroDisponible(_filtroSeleccionado);

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 60;
    final cardWidth = availableWidth < 260 ? availableWidth : 260.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seguimiento de Progreso',
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Visualiza tu evolución académica a lo largo del tiempo',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: statCard(
                    titulo: 'Exámenes completados',
                    valor: '$_examenesRealizados',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: statCard(
                    titulo: 'Promedio general',
                    valor: '${_promedioGeneral.toStringAsFixed(1)}%',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: statCard(
                    titulo: 'Periodo',
                    valor: _periodo,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: statCard(
                    titulo: 'Materias dominadas',
                    valor: '$_materiasDominadas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 520),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evolución de',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Calificaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _filtrosTiempo.map((texto) {
                          final activo = texto == _filtroSeleccionado;
                          final disponible = _filtroDisponible(texto);
                          return InkWell(
                            onTap: () => _seleccionarFiltro(texto),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: activo
                                    ? Colors.amber
                                    : disponible
                                        ? const Color(0xFF222222)
                                        : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                texto,
                                style: TextStyle(
                                  color: activo
                                      ? Colors.black
                                      : disponible
                                          ? Colors.white
                                          : Colors.white38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Materia:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _materiasDisponibles.isEmpty
                                    ? const Text(
                                        'No hay materias disponibles',
                                        style: TextStyle(color: Colors.white54),
                                      )
                                    : DropdownButton<String>(
                                        value: selectedMateria.isEmpty
                                            ? null
                                            : selectedMateria,
                                        dropdownColor: const Color(0xFF111111),
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        iconEnabledColor: Colors.amber,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        items: _materiasDisponibles
                                            .map(
                                              (materia) => DropdownMenuItem(
                                                value: materia,
                                                child: Text(materia),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _materiaSeleccionada = value;
                                            });
                                          }
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 360,
                    child: selectedMateria.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay materia seleccionada.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : filtroNoDisponible
                        ? const Center(
                            child: Text(
                              'Aún no haz alcanzado este tiempo de uso para este filtro.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : chartPoints.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay datos de calificaciones en el periodo seleccionado.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : CustomPaint(
                            painter: LineChartPainter(
                              materiaSeries: {selectedMateria: chartPoints},
                            ),
                            child: Container(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statCard({
    required String titulo,
    required String valor,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ExamScore {
  final DateTime fecha;
  final double porcentaje;

  ExamScore({required this.fecha, required this.porcentaje});
}

class LineChartPainter extends CustomPainter {
  final Map<String, List<ExamScore>> materiaSeries;
  final List<Color> _lineColors = [
    Colors.amber,
    Colors.cyan,
    Colors.pink,
    Colors.orange,
  ];

  LineChartPainter({required this.materiaSeries});

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF0F0F0F);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5;

    final labelStyle = TextStyle(color: Colors.white54, fontSize: 12);
    final chartInset = 40.0;
    final chartWidth = size.width - chartInset - 20;
    final chartHeight = size.height - 40;
    final chartOffset = Offset(chartInset, 20);

    for (var i = 0; i <= 5; i++) {
      final y = chartOffset.dy + chartHeight - (chartHeight / 5 * i);
      canvas.drawLine(
        Offset(chartOffset.dx, y),
        Offset(chartOffset.dx + chartWidth, y),
        gridPaint,
      );
      final textPainter = TextPainter(
        text: TextSpan(text: '${i * 20}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          chartOffset.dx - textPainter.width - 8,
          y - textPainter.height / 2,
        ),
      );
    }

    canvas.drawLine(
      Offset(chartOffset.dx, chartOffset.dy),
      Offset(chartOffset.dx, chartOffset.dy + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartOffset.dx, chartOffset.dy + chartHeight),
      Offset(chartOffset.dx + chartWidth, chartOffset.dy + chartHeight),
      axisPaint,
    );

    final allPoints = materiaSeries.values.expand((e) => e).toList();
    if (allPoints.isEmpty) return;

    final minDate = allPoints
        .map((e) => e.fecha)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = allPoints
        .map((e) => e.fecha)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final totalMillis = maxDate.difference(minDate).inMilliseconds.toDouble();
    final dateRange = totalMillis > 0 ? totalMillis : 1.0;

    var colorIndex = 0;
    materiaSeries.forEach((materia, points) {
      if (points.isEmpty) return;
      final sortedPoints = List<ExamScore>.from(points)
        ..sort((a, b) => a.fecha.compareTo(b.fecha));
      final path = Path();
      for (var i = 0; i < sortedPoints.length; i++) {
        final point = sortedPoints[i];
        final xPercent =
            point.fecha.difference(minDate).inMilliseconds / dateRange;
        final yPercent = point.porcentaje.clamp(0.0, 100.0) / 100.0;
        final dx = chartOffset.dx + (xPercent * chartWidth);
        final dy = chartOffset.dy + chartHeight - (yPercent * chartHeight);
        if (i == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
        canvas.drawCircle(
          Offset(dx, dy),
          4,
          Paint()..color = _lineColors[colorIndex % _lineColors.length],
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = _lineColors[colorIndex % _lineColors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );

      final materiaText = TextPainter(
        text: TextSpan(
          text: materia,
          style: TextStyle(
            color: _lineColors[colorIndex % _lineColors.length],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 120);
      materiaText.paint(
        canvas,
        Offset(
          chartOffset.dx + chartWidth - materiaText.width - 4,
          chartOffset.dy + 8.0 + (colorIndex * 18),
        ),
      );

      colorIndex++;
    });

    final minLabel = TextPainter(
      text: TextSpan(text: 'Inicio', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    minLabel.paint(
      canvas,
      Offset(chartOffset.dx, chartOffset.dy + chartHeight + 8),
    );

    final maxLabel = TextPainter(
      text: TextSpan(text: 'Actual', style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    maxLabel.paint(
      canvas,
      Offset(
        chartOffset.dx + chartWidth - maxLabel.width,
        chartOffset.dy + chartHeight + 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.materiaSeries != materiaSeries;
  }
}
