import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {

  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static Future<String> generarExamen(
    String materia,
    String dificultad,
  ) async {

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
    ); 

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": """
Genera un examen de la materia "$materia" con nivel de dificultad "$dificultad".
El examen debe constar de 5 preguntas de opción múltiple.

Devuelve EXCLUSIVAMENTE una estructura JSON válida, sin texto introductorio, sin explicaciones y sin bloques de código Markdown (no incluyas caracteres como ```json o ```). El resultado final debe iniciar directamente con [ y terminar con ].

Cada objeto de pregunta dentro del arreglo debe seguir ESTE FORMATO EXACTO:
{
  "pregunta": "Aquí va el enunciado de la pregunta",
  "opciones": ["Opción 1", "Opción 2", "Opción 3", "Opción 4"],
  "correcta": "Aquí va el texto idéntico de la opción que sea correcta"
}

IMPORTANTE: El campo "correcta" DEBE ser una cadena de texto (String) cuyo contenido sea exactamente idéntico a una de las opciones del arreglo "opciones". No uses índices numéricos.
"""
              }
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "Error: ${response.body}";
    }
  }
  static Future<String> generarRetroalimentacion(
  String materia,
  double calificacion,
) async {

  final url = Uri.parse(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
  );

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text": """
Eres un tutor académico experto.

Materia: $materia
Calificación: $calificacion/100

Genera una retroalimentación personalizada.

Incluye:
- Qué hizo bien.
- Qué puede mejorar.
- Recomendaciones de estudio.
- Un mensaje motivador.

Máximo 100 palabras.
"""
            }
          ]
        }
      ]
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["candidates"][0]["content"]["parts"][0]["text"];
  } else {
    return "No fue posible generar la retroalimentación.";
  }
}
}