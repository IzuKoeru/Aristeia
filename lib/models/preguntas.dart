class Pregunta {

  final String pregunta;
  final List<dynamic> opciones;
  final String correcta;

  Pregunta({
    required this.pregunta,
    required this.opciones,
    required this.correcta,
  });

  factory Pregunta.fromJson(
    Map<String, dynamic> json,
  ) {

    return Pregunta(
      pregunta: json["pregunta"],
      opciones: json["opciones"],
      correcta: json["correcta"],
    );
  }
}