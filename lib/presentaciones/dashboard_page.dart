import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // VARIABLES DE ESTADO VINCULADAS A SUPABASE
  bool _cargando = true;
  int _examenesRealizados = 0;
  double _promedioGeneral = 0.0;
  String _periodo = '';
  int _materiasDominadas = 0;

  // Mapa donde agruparemos los promedios reales por cada materia: {'Álgebra': 75.0, ...}
  Map<String, double> _rendimientoPorMateria = {};
  Map<String, int> _examenesPorMateria = {};

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
      final rawPeriodo = progresoRes?['periodo'];
      final periodo = _formatearPeriodo(rawPeriodo);

      final List<dynamic> resultados = await supabase
          .from('resultados')
          .select('porcentaje, id_examen')
          .eq('id_estudiante', idEstudiante);

      if (resultados.isEmpty) {
        setState(() {
          _examenesRealizados = 0;
          _promedioGeneral = avanceProgreso;
          _periodo = periodo;
          _materiasDominadas = 0;
          _rendimientoPorMateria = {};
          _examenesPorMateria = {};
          _cargando = false;
        });
        return;
      }

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

      final Map<String, List<double>> notasPorMateria = {};
      final Map<String, int> examenesPorMateria = {};
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
        examenesPorMateria[materiaNombre] =
            (examenesPorMateria[materiaNombre] ?? 0) + 1;
      }

      final Map<String, double> promediosCalculados = {};
      int materiasDominadas = 0;

      for (var row in materias) {
        if (row['nombre'] is! String) continue;
        final nombre = row['nombre'] as String;
        final lista = notasPorMateria[nombre] ?? [];
        final promedioMateria = lista.isEmpty
            ? 0.0
            : lista.reduce((a, b) => a + b) / lista.length;
        final promedioPorcentaje = promedioMateria.clamp(0.0, 100.0);
        promediosCalculados[nombre] = promedioPorcentaje;
        if (promedioPorcentaje >= 100) {
          materiasDominadas++;
        }
      }

      final promedioGeneralResultados = promediosCalculados.isEmpty
          ? 0.0
          : promediosCalculados.values.reduce((a, b) => a + b) /
                promediosCalculados.length;

      setState(() {
        _examenesRealizados = resultados.length;
        _promedioGeneral = avanceProgreso > 0
            ? avanceProgreso
            : promedioGeneralResultados;
        _periodo = periodo;
        _materiasDominadas = materiasDominadas;
        _rendimientoPorMateria = promediosCalculados;
        _examenesPorMateria = examenesPorMateria;
        _cargando = false;
      });
    } catch (error) {
      debugPrint("Error cargando base de datos en Progreso: $error");
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
      // Asumimos que el valor numérico representa minutos de progreso
      final horas = periodoNumerico / 60.0;
      return '${horas.toStringAsFixed(1)}h';
    }

    try {
      final fecha = DateTime.parse(periodoTexto);
      final diferencia = DateTime.now().difference(fecha).inMinutes / 60.0;
      if (diferencia < 0) {
        return 'Sin periodo';
      }
      return '${diferencia.toStringAsFixed(1)}h';
    } catch (_) {
      return periodoTexto;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tu Progreso',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Monitorea tus estadísticas y evolución de aprendizaje',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 30),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statCard(
                  titulo: "Exámenes Realizados",
                  valor: "$_examenesRealizados",
                ),
                const SizedBox(height: 12),
                statCard(
                  titulo: "Promedio General",
                  valor: "${_promedioGeneral.toStringAsFixed(1)}%",
                ),
                const SizedBox(height: 12),
                statCard(
                  titulo: "Periodo",
                  valor: _periodo.isEmpty ? 'Sin periodo' : _periodo,
                ),
                const SizedBox(height: 12),
                statCard(
                  titulo: "Materias Dominadas",
                  valor: "$_materiasDominadas",
                ),
              ],
            ),

            const SizedBox(height: 40),

            // =======================================================
            // NUEVA SECCIÓN: EVALUACIÓN DE RENDIMIENTO POR MATERIA
            // =======================================================
            const Text(
              'Evaluación de Rendimiento',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (_rendimientoPorMateria.isEmpty)
              const Text(
                'Aún no hay exámenes completados en la base de datos para generar la tabla.',
                style: TextStyle(color: Colors.white38, fontSize: 15),
              )
            else
              tablaRendimiento(),
          ],
        ),
      ),
    );
  }

  // COMPONENTE DE LA FILA INTERACTIVA (CURSOR/TOOLTIP Y REDONDEO DE 20 EN 20)
  Widget tablaRendimiento() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tabla de Rendimiento por Materia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  'Materia',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '0 - 100',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          ..._rendimientoPorMateria.entries.map((entry) {
            final examenes = _examenesPorMateria[entry.key] ?? 0;
            return filaRendimientoMateria(entry.key, entry.value, examenes);
          }),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 142),
            child: Row(
              children: const [
                Expanded(
                  child: Center(
                    child: Text(
                      '0',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '20',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '40',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '60',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '80',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '100',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget filaRendimientoMateria(
    String materia,
    double promedioReal,
    int examenes,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              materia,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Tooltip(
              message: examenes == 0
                  ? 'Sin exámenes en esta materia'
                  : '$examenes examen(es) • Promedio ${promedioReal.toStringAsFixed(1)}%',
              textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Row(
                    children: List.generate(6, (index) {
                      return Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: index == 5
                                    ? Colors.transparent
                                    : Colors.white12,
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  FractionallySizedBox(
                    widthFactor: (promedioReal / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
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

  // TU FORMATO ORIGINAL DE TARJETAS STATCARD EXACTO
  Widget statCard({required String titulo, required String valor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
