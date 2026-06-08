import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analisis_page.dart';
import '../main.dart';
import 'progreso_page.dart';
import 'retroalimentacion_page.dart';
import 'dashboard_page.dart';
import '../examenes/examenes_page.dart';
import 'materias_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
} //build

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  int paginaActual = 0;
  bool _drawerAbierto = false;

  String _usuarioNombre = 'Estudiante';
  String _usuarioEmail = 'estudiante@aristeia.edu';
  final Color dorado = const Color(0xFFC9A84B);

  late final AnimationController _drawerController;
  late final Animation<Offset> _buttonOffset;
  late final Animation<Offset> _contentOffset;

  final List<String> paginas = [
    'Dashboard',
    'Materias',
    'Análisis',
    'Retroalimentación',
    'Progreso',
    'Exámenes IA',
  ];

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _buttonOffset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.2, 0)).animate(
          CurvedAnimation(parent: _drawerController, curve: Curves.easeOut),
        );
    _contentOffset =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.12, 0)).animate(
          CurvedAnimation(parent: _drawerController, curve: Curves.easeOut),
        );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> _confirmSignOut() async {
    final cancelar = TextButton(
      onPressed: () => Navigator.of(context).pop(false),
      child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
    );

    final confirmar = ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: dorado),
      onPressed: () => Navigator.of(context).pop(true),
      child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.black)),
    );

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.9),
        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Deseas cerrar sesión?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [cancelar, confirmar],
      ),
    );

    if (result == true) {
      await _signOut();
    }
  }

  Future<void> _cargarUsuario() async {
    try {
      final supabase = Supabase.instance.client;
      final usuarioActual = supabase.auth.currentUser;
      if (usuarioActual == null) return;

      final estudianteRes = await supabase
          .from('estudiantes')
          .select('nombre')
          .eq('id_usuario', usuarioActual.id)
          .maybeSingle();

      final nombre = estudianteRes?['nombre']?.toString().trim();
      final email = usuarioActual.email?.trim();

      if (mounted) {
        setState(() {
          if (nombre != null && nombre.isNotEmpty) {
            _usuarioNombre = nombre;
          }
          if (email != null && email.isNotEmpty) {
            _usuarioEmail = email;
          }
        });
      }
    } catch (error) {
      debugPrint('Error cargando usuario: $error');
    }
  }

  void _toggleDrawer() {
    setState(() {
      _drawerAbierto = !_drawerAbierto;
      if (_drawerAbierto) {
        _drawerController.forward();
      } else {
        _drawerController.reverse();
      }
    });
  }

  void _closeDrawer() {
    if (!_drawerAbierto) return;
    setState(() {
      _drawerAbierto = false;
      _drawerController.reverse();
    });
  }

  void _selectPage(int index) {
    setState(() {
      paginaActual = index;
    });
    _closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double drawerWidth = screenWidth * 0.78;

    return Scaffold(
      body: Stack(
        children: [
          /// FONDO
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fotoolimpo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// OSCURECER
          Container(color: Colors.black.withOpacity(0.85)),

          /// CONTENIDO PRINCIPAL
          SlideTransition(
            position: _contentOffset,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  /// HEADER CON BOTÓN DE MENÚ
                  Container(
                    height: 100,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      border: Border(
                        bottom: BorderSide(color: dorado.withOpacity(0.2)),
                      ),
                    ),
                    child: Row(
                      children: [
                        /// BOTÓN MENÚ HAMBURGUESA
                        SlideTransition(
                          position: _buttonOffset,
                          child: GestureDetector(
                            onTap: _toggleDrawer,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              child: Icon(Icons.menu, color: dorado, size: 28),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        /// LOGO Y TEXTO
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: dorado, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ARISTEIA',
                                  style: TextStyle(
                                    color: dorado,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    paginas[paginaActual],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Excelencia Académica',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),

                        const Spacer(),
                        // Perfil movido dentro del bloque del título (izquierda)
                      ],
                    ),
                  ),

                  /// CONTENIDO DE LA PÁGINA (OCUPA TODO EL ESPACIO DISPONIBLE)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _obtenerPaginaActual(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// OSCURECER CUANDO EL MENÚ ESTÁ ABIERTO
          if (_drawerAbierto)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),

          /// MENÚ DESLIZANTE
          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            left: _drawerAbierto ? 0 : -drawerWidth,
            top: 0,
            bottom: 0,
            width: drawerWidth,
            child: _buildDrawer(drawerWidth),
          ),
        ],
      ),
    );
  }

  /// DRAWER (BARRA LATERAL COLAPSABLE)
  Widget _buildDrawer(double width) {
    return Container(
      width: width,
      color: Colors.black.withOpacity(0.95),
      child: Column( // Cambiado a Column para que no explote con el Spacer
        children: [
          /// HEADER DEL DRAWER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              border: Border(
                bottom: BorderSide(color: dorado.withOpacity(0.2)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: dorado, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ARISTEIA',
                  style: TextStyle(
                    color: dorado,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Excelencia Académica',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: dorado,
                          child: Text(
                            _usuarioNombre.isNotEmpty
                                ? _usuarioNombre.trim()[0].toUpperCase()
                                : 'E',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _usuarioNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _usuarioEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// BOTONES DEL MENÚ
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                botonMenuDrawer(Icons.dashboard, 'Dashboard', 0),
                botonMenuDrawer(Icons.book, 'Materias', 1),
                botonMenuDrawer(Icons.bar_chart, 'Análisis', 2),
                botonMenuDrawer(Icons.chat, 'Retroalimentación', 3),
                botonMenuDrawer(Icons.trending_up, 'Progreso', 4),
                botonMenuDrawer(Icons.quiz, 'Exámenes IA', 5),
              ],
            ),
          ),

          /// BOTÓN CERRAR SESIÓN
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: _confirmSignOut,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, color: Colors.red),
                    const SizedBox(width: 15),
                    const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget botonMenuDrawer(IconData icono, String texto, int index) {
    bool activo = paginaActual == index;

    return GestureDetector(
      onTap: () => _selectPage(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: activo ? dorado : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icono, color: activo ? Colors.black : Colors.white70),
            const SizedBox(width: 15),
            Text(
              texto,
              style: TextStyle(
                color: activo ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _obtenerPaginaActual() {
    switch (paginaActual) {
      case 0:
        return const DashboardPage();
      case 1:
        return const MateriasPage(); // <- CAMBIADO AQUÍ
      case 2:
        return const AnalisisPage();
      case 3:
        return const RetroalimentacionPage();
      case 4:
        return const ProgresoPage();
      case 5:
        return const ExamenesPage();
      default:
        return centro(paginas[paginaActual]);
    }
  }

  Widget estadistica(String numero, String texto, IconData icono) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dorado.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: dorado, size: 28),

          const Spacer(),

          Text(
            numero,
            style: TextStyle(
              color: dorado,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(texto, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget materias() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Materias',
            style: TextStyle(
              color: dorado,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Selecciona una materia para iniciar un examen',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),

          const SizedBox(height: 35),

          Column(
            children: [
              tarjetaMateria('Matemáticas', '85%', Icons.calculate),
              const SizedBox(height: 20),
              tarjetaMateria('Física', '78%', Icons.science),
              const SizedBox(height: 20),
              tarjetaMateria('Química', '72%', Icons.biotech),
              const SizedBox(height: 20),
              tarjetaMateria('Literatura', '90%', Icons.menu_book),
              const SizedBox(height: 20),
              tarjetaMateria('Historia', '80%', Icons.account_balance),
              const SizedBox(height: 20),
              tarjetaMateria('Biología', '75%', Icons.biotech_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget tarjetaMateria(String nombre, String progreso, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dorado.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icono, color: dorado, size: 36),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Curso Académico',
            style: TextStyle(color: Colors.white54, fontSize: 15),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
              Text(
                progreso,
                style: TextStyle(
                  color: dorado,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: double.parse(progreso.replaceAll('%', '')) / 100,
              minHeight: 12,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(dorado),
            ),
          ),
        ],
      ),
    );
  }

  Widget centro(String texto) {
    return Center(
      child: Text(
        texto,
        style: TextStyle(
          color: dorado,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class HoverAnimatedLabel extends StatelessWidget {
  final String label;
  final TextStyle style;

  const HoverAnimatedLabel({
    super.key,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 14;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: fontSize * 1.7,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: style,
          ),
        ),
      ),
    );
  }
}
