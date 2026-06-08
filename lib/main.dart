import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentaciones/menu_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final supabase = Supabase.instance.client;
  final currentUser = supabase.auth.currentUser;
  runApp(AristeiaApp(initialUser: currentUser != null));
}

class AristeiaApp extends StatelessWidget {
  final bool initialUser;

  const AristeiaApp({super.key, this.initialUser = false});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(brightness: Brightness.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aristeia',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).copyWith(
          headlineLarge: GoogleFonts.lato(
            textStyle: baseTheme.textTheme.headlineLarge,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.lato(
            textStyle: baseTheme.textTheme.headlineMedium,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: GoogleFonts.lato(
            textStyle: baseTheme.textTheme.headlineSmall,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.lato(
            textStyle: baseTheme.textTheme.titleLarge,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: GoogleFonts.lato(
            textStyle: baseTheme.textTheme.titleMedium,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: GoogleFonts.lato(
            textStyle: baseTheme.textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
          labelLarge: GoogleFonts.lato(
            textStyle: baseTheme.textTheme.labelLarge,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: GoogleFonts.poppins(
            textStyle: baseTheme.textTheme.labelMedium,
          ),
          bodyLarge: GoogleFonts.poppins(
            textStyle: baseTheme.textTheme.bodyLarge,
          ),
          bodyMedium: GoogleFonts.poppins(
            textStyle: baseTheme.textTheme.bodyMedium,
          ),
          bodySmall: GoogleFonts.poppins(
            textStyle: baseTheme.textTheme.bodySmall,
          ),
        ),
      ),
      home: initialUser ? const MenuPage() : const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Controladores actualizados
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmarPasswordController =
      TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _semestreController = TextEditingController();
  final TextEditingController _grupoController = TextEditingController();

  final supabase = Supabase.instance.client;

  bool esLogin = true;
  final Color dorado = const Color(0xFFC9A84B);

  final Map<String, String> frase = {
    "texto": "La excelencia no es un acto, sino un hábito.",
    "autor": "Aristóteles",
  };

  // 2. Función de autenticación
  Future<void> _manejarAutenticacion() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nombre = _nombreController.text.trim();
    final matricula = _matriculaController.text.trim();
    final semestre = _semestreController.text.trim();
    final grupo = _grupoController.text.trim().toUpperCase();

    if (email.isEmpty || password.isEmpty) {
      _mostrarSnackBar(
        "Por favor llena los campos obligatorios",
        esError: true,
      );
      return;
    }

    try {
      if (esLogin) {
        // --- LOGIN ---
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;
        _mostrarSnackBar("¡Éxito! Iniciando sesión...");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MenuPage()),
        );
      } else {
        // --- REGISTRO DE ESTUDIANTE ---
        if (nombre.isEmpty ||
            matricula.isEmpty ||
            semestre.isEmpty ||
            grupo.isEmpty) {
          _mostrarSnackBar(
            "Por favor llena todos tus datos (Nombre, Matrícula, Semestre y Grupo)",
            esError: true,
          );
          return;
        }

        if (!RegExp(r'^[1-6]$').hasMatch(semestre)) {
          _mostrarSnackBar(
            "El semestre debe ser un número entre 1 y 6",
            esError: true,
          );
          return;
        }

        if (!RegExp(r'^[ABC]$').hasMatch(grupo)) {
          _mostrarSnackBar("El grupo debe ser A, B o C", esError: true);
          return;
        }

        if (_passwordController.text != _confirmarPasswordController.text) {
          _mostrarSnackBar("Las contraseñas no coinciden", esError: true);
          return;
        }

        // Crear usuario en Auth
        final AuthResponse res = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'nombre': nombre},
        );

        final usuarioNuevo = res.user;

        // INSERTAR TODOS LOS DATOS EN LA TABLA 'estudiantes' (OPCIÓN B)
        if (usuarioNuevo != null) {
          await supabase.from('estudiantes').insert({
            'id_usuario': usuarioNuevo.id,
            'nombre': nombre,
            'matricula': matricula,
            'semestre': semestre,
            'grupo': grupo,
          });

          _mostrarSnackBar("¡Cuenta creada con éxito!");

          if (res.session != null && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MenuPage()),
            );
          } else {
            setState(() => esLogin = true);
            _mostrarSnackBar("Verifica tu email e inicia sesión.");
          }
        }
      }
    } on AuthException catch (e) {
      _mostrarSnackBar(e.message, esError: true);
    } catch (e) {
      _mostrarSnackBar("Error inesperado: $e", esError: true);
    }
  }

  void _mostrarSnackBar(String msj, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msj),
        backgroundColor: esError ? Colors.red : dorado,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final double containerWidth = isPortrait
        ? MediaQuery.of(context).size.width - 40
        : 1000.0;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fotoolimpo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.6)),

          Center(
            child: SingleChildScrollView(
              child: Container(
                width: containerWidth,
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: dorado.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: dorado.withOpacity(0.2), blurRadius: 30),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Builder(
                    builder: (context) {
                      final isPortrait =
                          MediaQuery.of(context).orientation ==
                          Orientation.portrait;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isPortrait)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  border: Border(
                                    right: BorderSide(
                                      color: dorado.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '"',
                                      style: TextStyle(
                                        fontSize: 90,
                                        color: dorado.withOpacity(0.5),
                                      ),
                                    ),
                                    Text(
                                      frase["texto"]!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      "— ${frase["autor"]}",
                                      style: TextStyle(
                                        color: dorado,
                                        letterSpacing: 2,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 40,
                                horizontal: 50,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: dorado,
                                        width: 2,
                                      ),
                                    ),
                                    child: const ClipOval(
                                      child: Icon(
                                        Icons.account_balance,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    "ARISTEIA",
                                    style: TextStyle(
                                      color: dorado,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 6,
                                    ),
                                  ),
                                  const Text(
                                    "Supérate · Perfecciónate · Trasciende",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(height: 35),

                                  Row(
                                    children: [
                                      tabSelector(
                                        "INICIAR SESIÓN",
                                        esLogin,
                                        () => setState(() => esLogin = true),
                                      ),
                                      tabSelector(
                                        "REGISTRARSE",
                                        !esLogin,
                                        () => setState(() => esLogin = false),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  if (esLogin) ...[
                                    campoTexto(
                                      "Correo institucional",
                                      Icons.email_outlined,
                                      _emailController,
                                    ),
                                    const SizedBox(height: 15),
                                    campoTexto(
                                      "Contraseña",
                                      Icons.lock_outline,
                                      _passwordController,
                                      oculto: true,
                                    ),
                                  ] else ...[
                                    campoTexto(
                                      "Nombre completo",
                                      Icons.person_outline,
                                      _nombreController,
                                    ),
                                    const SizedBox(height: 15),
                                    campoTexto(
                                      "Matrícula",
                                      Icons.badge_outlined,
                                      _matriculaController,
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: campoTexto(
                                            "Semestre",
                                            Icons.school_outlined,
                                            _semestreController,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[1-6]'),
                                              ),
                                              LengthLimitingTextInputFormatter(
                                                1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: campoTexto(
                                            "Grupo",
                                            Icons.group_outlined,
                                            _grupoController,
                                            textCapitalization:
                                                TextCapitalization.characters,
                                            inputFormatters: [
                                              TextInputFormatter.withFunction(
                                                (oldValue, newValue) =>
                                                    TextEditingValue(
                                                      text: newValue.text
                                                          .toUpperCase(),
                                                      selection:
                                                          newValue.selection,
                                                    ),
                                              ),
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r'[A-C]'),
                                              ),
                                              LengthLimitingTextInputFormatter(
                                                1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    campoTexto(
                                      "Correo institucional",
                                      Icons.email_outlined,
                                      _emailController,
                                    ),
                                    const SizedBox(height: 15),
                                    campoTexto(
                                      "Contraseña",
                                      Icons.lock_outline,
                                      _passwordController,
                                      oculto: true,
                                    ),
                                    const SizedBox(height: 15),
                                    campoTexto(
                                      "Confirmar contraseña",
                                      Icons.lock_outline,
                                      _confirmarPasswordController,
                                      oculto: true,
                                    ),
                                  ],

                                  const SizedBox(height: 30),

                                  botonDorado(
                                    esLogin ? "Ingresar" : "Crear Cuenta",
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tabSelector(String texto, bool seleccionado, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              texto,
              style: TextStyle(
                color: seleccionado ? dorado : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              color: seleccionado ? dorado : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget campoTexto(
    String texto,
    IconData icono,
    TextEditingController controller, {
    bool oculto = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: oculto,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: texto,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icono, color: dorado, size: 20),
        filled: true,
        fillColor: Colors.black.withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dorado.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: dorado, width: 2),
        ),
      ),
    );
  }

  Widget botonDorado(String texto) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: dorado,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 5,
        ),
        onPressed: _manejarAutenticacion,
        child: Text(
          texto.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
