import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/preguntas.dart';
import '../services/ai_services.dart';
//BD import
import 'package:supabase_flutter/supabase_flutter.dart';

class ExamenesPage extends StatefulWidget {
  const ExamenesPage({super.key});

  @override
  State<ExamenesPage> createState() =>
      _ExamenesPageState();
}

class _ExamenesPageState
    extends State<ExamenesPage> {

        final supabase = Supabase.instance.client; 

    Future<void> _guardarExamenEnBD() async {
    // 1. Validar que el estudiante respondió todas las preguntas antes de terminar
    if (respuestasSeleccionadas.length < preguntas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor responde todas las preguntas antes de terminar.')),
      );
      return;
    }

    setState(() => cargando = true);

    try {
      // 2. Calcular calificación comparando la respuesta elegida con la correcta de la IA
      int correctas = 0;
      for (int i = 0; i < preguntas.length; i++) {
        if (respuestasSeleccionadas[i] == preguntas[i].correcta) { 
          correctas++;
        }
      }
      
      double porcentaje = (correctas / preguntas.length) * 100;
      double calificacion = (correctas / preguntas.length) * 10; // Nota escala 0 a 10

      // 3. Obtener el id_materia basado en el Dropdown
      final materiaRes = await supabase
          .from('materias')
          .select('id_materia')
          .eq('nombre', materia)
          .single();

      final int idMateria = materiaRes['id_materia'];

      // 4. Insertar el examen principal en la tabla 'examenes'
      final examenRes = await supabase.from('examenes').insert({
        'id_materia': idMateria,
        'titulo': 'Examen de $materia generado por IA ($dificultad)',
        'fecha': DateTime.now().toIso8601String(), 
        'tipo': 'IA',
        'tiempo_limite': 60, 
      }).select().single();

      final int idExamen = examenRes['id_examen'];

      // 5. Insertar las preguntas vinculadas a este examen en la tabla 'preguntas'
      for (var p in preguntas) {
        await supabase.from('preguntas').insert({
          'id_examen': idExamen,
          'enunciado': p.pregunta,
          'tipo': 'teorica', 
          'dificultad': dificultad, // Asegúrate si tu variable se llama dificultad o difficulty
          'respuesta_correcta': p.correcta,
        });
      }

      // 6. Obtener el usuario actual y su ID de estudiante real
      final usuarioActual = supabase.auth.currentUser;
      
      if (usuarioActual == null) {
        throw Exception('No hay una sesión activa.');
      }

      // Buscamos usando maybeSingle para que no rompa la app si no se encuentra en la tabla pública
      final estudianteData = await supabase
          .from('estudiantes')
          .select('id_estudiante')
          .eq('id_usuario', usuarioActual.id)
          .maybeSingle();

      int idEstudianteReal;

      // ¡NUEVA MEJORA AUTO-REPARABLE! Si la cuenta no tenía registro en la tabla, lo repara aquí mismo:
      if (estudianteData == null) {
        final nombreUsuario = usuarioActual.userMetadata?['nombre'] ?? 'Estudiante ';
        final nuevoEstudiante = await supabase
            .from('estudiantes')
            .insert({
              'id_usuario': usuarioActual.id,
              'nombre': nombreUsuario,
            })
            .select('id_estudiante')
            .single();
        
        idEstudianteReal = nuevoEstudiante['id_estudiante'];
      } else {
        idEstudianteReal = estudianteData['id_estudiante'];
      }

      // Ahora sí, insertamos en resultados con el ID numérico correcto libre de errores
      await supabase.from('resultados').insert({
        'id_estudiante': idEstudianteReal,
        'id_examen': idExamen,
        'calificacion': calificacion,
        'porcentaje': porcentaje,
        'fecha_presentacion': DateTime.now().toIso8601String(),
      });

      // 8. Actualizar o insertar el progreso del estudiante
      final List<dynamic> resultadosTodos = await supabase
          .from('resultados')
          .select('porcentaje')
          .eq('id_estudiante', idEstudianteReal);

      final double promedioGeneralProgreso = resultadosTodos.isEmpty
          ? porcentaje
          : resultadosTodos
              .map((row) => double.tryParse(row['porcentaje']?.toString() ?? '') ?? 0.0)
              .reduce((a, b) => a + b) /
              resultadosTodos.length;

      final String periodoActual = DateTime.now().toIso8601String();

      final progresoExistente = await supabase
          .from('progreso')
          .select('id_progreso')
          .eq('id_estudiante', idEstudianteReal)
          .maybeSingle();

      if (progresoExistente == null) {
        await supabase.from('progreso').insert({
          'id_estudiante': idEstudianteReal,
          'periodo': periodoActual,
          'avance': promedioGeneralProgreso,
          'observaciones': null,
        });
      } else {
        await supabase.from('progreso').update({
          'periodo': periodoActual,
          'avance': promedioGeneralProgreso,
          'observaciones': null,
        }).eq('id_progreso', progresoExistente['id_progreso']);
      }

      // 9. Mostrar diálogo de éxito y limpiar la pantalla
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false, 
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111111),
            title: const Text('¡Examen Terminado!', style: TextStyle(color: Color(0xFFC9A84B))),
            content: Text(
              'Tuviste $correctas correctas de ${preguntas.length}.\nCalificación final: ${calificacion.toStringAsFixed(1)}/10',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  setState(() {
                    preguntas = []; 
                    respuestasSeleccionadas = {}; 
                    resultadoIA = "";
                  });
                },
                child: const Text('Aceptar', style: TextStyle(color: Color(0xFFC9A84B))),
              )
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al guardar: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hubo un error: $e')),
        );
      }
    } finally {
      setState(() => cargando = false);
    }
  }

  String materia = "Matemáticas";
  String dificultad = "Medio";

  String resultadoIA = "";

  bool cargando = false;

  List<Pregunta> preguntas = [];

  Map<int, String> respuestasSeleccionadas = {};

  final Color dorado =
      const Color(0xFFC9A84B);

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const SizedBox(height: 20),

          Row(
            children: [

              Container(
                padding:
                    const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color:
                      dorado.withOpacity(0.15),

                  borderRadius:
                      BorderRadius.circular(18),

                  border: Border.all(
                    color:
                        dorado.withOpacity(0.3),
                  ),
                ),

                child: Icon(
                  Icons.quiz,
                  color: dorado,
                  size: 30,
                ),
              ),

              const SizedBox(width: 20),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    'Exámenes IA',

                    style: TextStyle(
                      color: dorado,
                      fontSize: 32,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Genera exámenes personalizados',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 40),

          Container(
            padding:
                const EdgeInsets.all(30),

            decoration: BoxDecoration(
              color:
                  Colors.white.withOpacity(0.04),

              borderRadius:
                  BorderRadius.circular(25),

              border: Border.all(
                color:
                    dorado.withOpacity(0.15),
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(
                  'Materia',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                DropdownButton(
                  value: materia,
                  isExpanded: true,
                  underline: Container(),

                  dropdownColor:
                      const Color(0xFF111111),

                  style: const TextStyle(
                    color: Colors.white,
                  ),

                  items: const [

                    DropdownMenuItem(
                      value: "Matemáticas",
                      child: Text("Matemáticas"),
                    ),

                    DropdownMenuItem(
                      value: "Física",
                      child: Text("Física"),
                    ),

                    DropdownMenuItem(
                      value: "Química",
                      child: Text("Química"),
                    ),

                    DropdownMenuItem(
                      value: "Literatura",
                      child: Text("Literatura"),
                    ),

                    DropdownMenuItem(
                      value: "Historia",
                      child: Text("Historia"),
                    ),

                    DropdownMenuItem(
                      value: "Biología",
                      child: Text("Biología"),
                    ),
                  ],

                  onChanged: (value) {
                    setState(() {
                      materia = value!;
                    });
                  },
                ),

                const SizedBox(height: 25),

                const Text(
                  'Dificultad',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    dificultadButton(
                      "Fácil",
                      Icons.sentiment_satisfied,
                    ),

                    const SizedBox(width: 10),

                    dificultadButton(
                      "Medio",
                      Icons.bolt,
                    ),

                    const SizedBox(width: 10),

                    dificultadButton(
                      "Difícil",
                      Icons.local_fire_department,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 60,

                  child: ElevatedButton(

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: dorado,
                    ),

                    onPressed: () async {

                      setState(() {
                        cargando = true;
                        resultadoIA = "";
                        preguntas = [];
                      });

                      try {

                        final resultado = await AIService.generarExamen(materia, dificultad);

                        if (resultado.startsWith("Error")) {
                          setState(() {
                            resultadoIA = "La IA está sobrecargada en este momento, intenta de nuevo más tarde.";
                            cargando = false;
                          });
                          return;
                        }

                        // --- NUEVA LIMPIEZA A PRUEBA DE BALAS ---
                        String limpio = resultado;
                        
                        // Buscamos dónde empieza y termina el arreglo de preguntas
                        int startIndex = limpio.indexOf('[');
                        int endIndex = limpio.lastIndexOf(']');

                        if (startIndex != -1 && endIndex != -1) {
                          // Extraemos estrictamente lo que está entre los corchetes
                          limpio = limpio.substring(startIndex, endIndex + 1);
                        } else {
                          throw const FormatException("La IA no devolvió un formato válido.");
                        }

                        final List data =
                            jsonDecode(
                                limpio);

                        final preguntasIA =
                            data.map(
                          (e) =>
                              Pregunta.fromJson(
                                  e),
                        ).toList();

                        setState(() {

                          resultadoIA =
                              resultado;

                          preguntas =
                              preguntasIA;

                          cargando = false;
                        });

                        debugPrint(
                          preguntas[0]
                              .pregunta,
                        );

                      } catch (e) {

                        setState(() {

                          resultadoIA =
                              "Error procesando examen 😭";

                          cargando = false;
                        });

                        debugPrint(
                          "ERROR IA: $e",
                        );
                      }
                    },

                    child: const Text(
                      "Generar examen IA",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          if (cargando)
            const Center(
              child:
                  CircularProgressIndicator(),
            ),

          if (resultadoIA.isNotEmpty &&
              preguntas.isEmpty)
            Container(
              margin:
                  const EdgeInsets.only(
                top: 20,
              ),

              padding:
                  const EdgeInsets.all(
                20,
              ),

              decoration: BoxDecoration(
                color: Colors.white
                    .withOpacity(0.05),

                borderRadius:
                    BorderRadius.circular(
                        15),
              ),

              child: Text(
                resultadoIA,

                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),

          if (preguntas.isNotEmpty)
            Column(
              children: preguntas.asMap().entries.map((entry) {
                int indexPregunta = entry.key;
                Pregunta p = entry.value;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${indexPregunta + 1}. ${p.pregunta}", 
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      
                      ...p.opciones.map((o) {
                        bool isSelected = respuestasSeleccionadas[indexPregunta] == o.toString();

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              respuestasSeleccionadas[indexPregunta] = o.toString();
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isSelected ? dorado.withOpacity(0.8) : Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? dorado : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              o.toString(),
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ),
          
          // Botón Terminar Examen
          if (preguntas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dorado,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _guardarExamenEnBD,
                  child: const Text(
                    "Terminar Examen",
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            
        ],
      ),
    );
  }

  Widget dificultadButton(
      String text,
      IconData icon) {

    final selected =
        dificultad == text;

    return Expanded(
      child: GestureDetector(

        onTap: () {
          setState(() {
            dificultad = text;
          });
        },

        child: Container(
          padding:
              const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: selected
                ? dorado
                : Colors.white
                    .withOpacity(0.05),

            borderRadius:
                BorderRadius.circular(
                    10),
          ),

          child: Column(
            children: [

              Icon(
                icon,

                color: selected
                    ? Colors.black
                    : Colors.white,
              ),

              const SizedBox(height: 5),

              Text(
                text,

                style: TextStyle(
                  color: selected
                      ? Colors.black
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}