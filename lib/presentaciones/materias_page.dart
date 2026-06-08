import 'package:flutter/material.dart';

class MateriasPage extends StatelessWidget {
  const MateriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> materias = [
      {
        "nombre": "Matemáticas",
        "descripcion": "Álgebra, Cálculo y Geometría",
        "progreso": 0.85,
        "nota": 92,
        "icono": Icons.calculate,
      },
      {
        "nombre": "Física",
        "descripcion": "Mecánica y Termodinámica",
        "progreso": 0.78,
        "nota": 88,
        "icono": Icons.science,
      },
      {
        "nombre": "Química",
        "descripcion": "Orgánica e Inorgánica",
        "progreso": 0.72,
        "nota": 85,
        "icono": Icons.biotech,
      },
      {
        "nombre": "Historia",
        "descripcion": "Universal y Local",
        "progreso": 0.80,
        "nota": 90,
        "icono": Icons.account_balance,
      },
      {
        "nombre": "Programación",
        "descripcion": "Flutter, Dart y Backend",
        "progreso": 0.95,
        "nota": 98,
        "icono": Icons.code,
      },
      {
        "nombre": "Base de Datos",
        "descripcion": "SQL y Modelado",
        "progreso": 0.83,
        "nota": 91,
        "icono": Icons.storage,
      },
      {
        "nombre": "Inglés",
        "descripcion": "Reading y Speaking",
        "progreso": 0.76,
        "nota": 87,
        "icono": Icons.language,
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

                  return Container(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFFFD700),
                              ),
                            ),
                          ),
                        ],
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
