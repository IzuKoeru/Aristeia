import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MateriasPage extends StatelessWidget {
  const MateriasPage({super.key});

  Future<void> _mostrarTemasDialog(
    BuildContext context,
    String materia,
    List<Map<String, dynamic>> temas,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        title: Text(
          materia,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: temas
                .map(
                  (tema) => InkWell(
                    onTap: () async {
                      final String nombre =
                          tema['nombre'] ?? tema['titulo'] ?? '';
                      final String? url = tema['url'] as String?;
                      if (url == null || url.isEmpty) return;

                      final confirmed = await _confirmOpenExternal(
                        context,
                        nombre,
                        url,
                      );
                      if (confirmed) {
                        Navigator.of(context).pop(); // close temas dialog
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo abrir el enlace'),
                            ),
                          );
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFFFFD700),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tema['nombre'] ?? tema['titulo'] ?? '',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmOpenExternal(
    BuildContext context,
    String temaNombre,
    String url,
  ) async {
    final cancelar = TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
    );

    final confirmar = ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC9A84B)),
      onPressed: () => Navigator.of(context).pop(true),
      child: const Text('Continuar', style: TextStyle(color: Colors.black)),
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        content: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text:
                    'saldrás de la app para entrar a una página informativa del tema ',
                style: TextStyle(color: Colors.white70),
              ),
              TextSpan(
                text: temaNombre,
                style: const TextStyle(color: Color(0xFFFFD700)),
              ),
              const TextSpan(
                text: ', ¿estás seguro de querer continuar?',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [cancelar, confirmar],
      ),
    );

    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> materias = [
      {
        "nombre": "Matemáticas",
        "descripcion": "Álgebra, Cálculo y Geometría",
        "progreso": 0.85,
        "nota": 92,
        "icono": Icons.calculate,
        "temas": [
          {
            "nombre": "Factorización",
            "url":
                "https://es.khanacademy.org/math/algebra/x2f8bb11595b61c86:quadratics-multiplying-factoring",
          },
          {
            "nombre": "Notación Sigma",
            "url":
                "https://es.khanacademy.org/math/ap-calculus-ab/ab-integration-new/ab-6-1/a/understanding-the-sigma-notation",
          },
          {
            "nombre": "Fractales",
            "url": "https://es.wikipedia.org/wiki/Fractal",
          },
          {
            "nombre": "Ecuaciones",
            "url":
                "https://es.khanacademy.org/math/algebra/x2f8bb11595b61c86:solve-equations-inequalities",
          },
          {
            "nombre": "Trigonometría",
            "url": "https://es.khanacademy.org/math/trigonometry",
          },
        ],
      },
      {
        "nombre": "Física",
        "descripcion": "Mecánica y Termodinámica",
        "progreso": 0.78,
        "nota": 88,
        "icono": Icons.science,
        "temas": [
          {
            "nombre": "Cinemática",
            "url":
                "https://es.khanacademy.org/science/physics/one-dimensional-motion",
          },
          {
            "nombre": "Electromagnetismo",
            "url":
                "https://es.khanacademy.org/science/physics/magnetic-forces-and-magnetic-fields",
          },
          {
            "nombre": "Termodinámica",
            "url": "https://es.khanacademy.org/science/physics/thermodynamics",
          },
          {
            "nombre": "Óptica",
            "url": "https://es.khanacademy.org/science/physics/light-waves",
          },
          {
            "nombre": "Fuerzas y Energía",
            "url":
                "https://es.khanacademy.org/science/physics/forces-newtons-laws",
          },
        ],
      },
      {
        "nombre": "Química",
        "descripcion": "Orgánica e Inorgánica",
        "progreso": 0.72,
        "nota": 85,
        "icono": Icons.biotech,
        "temas": [
          {
            "nombre": "Estructura Atómica",
            "url":
                "https://es.khanacademy.org/science/quimica-pe-pre-u/x411a5b810486c7d2:estructura-atomica",
          },
          {
            "nombre": "Reacciones Redox",
            "url":
                "https://es.khanacademy.org/science/chemistry/oxidation-reduction-redox-reactions",
          },
          {
            "nombre": "Enlace Químico",
            "url":
                "https://es.khanacademy.org/science/chemistry/chemical-bonds",
          },
          {
            "nombre": "Estequiometría",
            "url":
                "https://es.khanacademy.org/science/chemistry/chemical-reactions-stoichiome",
          },
          {
            "nombre": "Química Orgánica",
            "url": "https://es.khanacademy.org/science/organic-chemistry",
          },
        ],
      },
      {
        "nombre": "Historia",
        "descripcion": "Universal y Local",
        "progreso": 0.80,
        "nota": 90,
        "icono": Icons.account_balance,
        "temas": [
          {
            "nombre": "Siglo XV",
            "url": "https://es.wikipedia.org/wiki/Siglo_XV",
          },
          {
            "nombre": "Segunda Guerra Mundial",
            "url": "https://es.wikipedia.org/wiki/Segunda_Guerra_Mundial",
          },
          {
            "nombre": "Historia Mundial",
            "url": "https://es.khanacademy.org/humanities/world-history",
          },
          {
            "nombre": "Revolución Industrial",
            "url": "https://es.wikipedia.org/wiki/Revoluci%C3%B3n_Industrial",
          },
          {
            "nombre": "Civilizaciones Antiguas",
            "url":
                "https://es.khanacademy.org/humanities/world-history/world-history-beginnings",
          },
        ],
      },
      {
        "nombre": "Programación",
        "descripcion": "Flutter, Dart y Backend",
        "progreso": 0.95,
        "nota": 98,
        "icono": Icons.code,
        "temas": [
          {"nombre": "Flutter", "url": "https://flutter.dev/"},
          {"nombre": "Dart", "url": "https://dart.dev/"},
          {
            "nombre": "Backend",
            "url": "https://developer.mozilla.org/es/docs/Learn/Server-side",
          },
          {
            "nombre": "Manejo de Estado",
            "url": "https://docs.flutter.dev/data-and-backend/state-mgmt/intro",
          },
          {
            "nombre": "APIs REST",
            "url": "https://aws.amazon.com/es/what-is/restful-api/",
          },
        ],
      },
      {
        "nombre": "Base de Datos",
        "descripcion": "SQL y Modelado",
        "progreso": 0.83,
        "nota": 91,
        "icono": Icons.storage,
        "temas": [
          {
            "nombre": "Modelado ER",
            "url":
                "https://www.lucidchart.com/pages/es/que-es-un-diagrama-entidad-relacion",
          },
          {"nombre": "SQL Avanzado", "url": "https://www.w3schools.com/sql/"},
          {"nombre": "Índices", "url": "https://use-the-index-luke.com/es"},
          {
            "nombre": "Normalización",
            "url":
                "https://learn.microsoft.com/es-es/office/troubleshoot/access/database-normalization-description",
          },
          {
            "nombre": "Consultas JOIN",
            "url": "https://www.w3schools.com/sql/sql_join.asp",
          },
        ],
      },
      {
        "nombre": "Inglés",
        "descripcion": "Reading y Speaking",
        "progreso": 0.76,
        "nota": 87,
        "icono": Icons.language,
        "temas": [
          {
            "nombre": "Reading Comprehension",
            "url": "https://learnenglish.britishcouncil.org/skills/reading",
          },
          {
            "nombre": "Speaking Practice",
            "url": "https://learnenglish.britishcouncil.org/skills/speaking",
          },
          {
            "nombre": "Phrasal Verbs",
            "url":
                "https://dictionary.cambridge.org/es/gramatica/gramatica-britanica/phrasal-verbs-and-multi-word-verbs",
          },
          {
            "nombre": "Grammar",
            "url": "https://learnenglish.britishcouncil.org/grammar",
          },
          {
            "nombre": "Listening",
            "url": "https://learnenglish.britishcouncil.org/skills/listening",
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITULO
            const Text(
              "Mis Materias",

              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Selecciona una materia para iniciar un examen",

              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 30),

            Expanded(
              child: ListView.separated(
                itemCount: materias.length,
                physics: const BouncingScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final materia = materias[index];

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _mostrarTemasDialog(
                        context,
                        materia["nombre"],
                        List<Map<String, dynamic>>.from(materia["temas"] ?? []),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFFFD700,
                                      ).withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      materia["icono"],
                                      color: const Color(0xFFFFD700),
                                      size: 32,
                                    ),
                                  ),

                                  const SizedBox(width: 18),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          materia["nombre"],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          materia["descripcion"],
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Calificación",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "${materia["nota"]}%",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: LinearProgressIndicator(
                                  value: materia["progreso"],
                                  minHeight: 14,
                                  backgroundColor: Colors.white10,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFFD700),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
