import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recuperarContrasena_page.dart';
import 'dashboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: true,
          title: const Text(
            "TeamPulse",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Iniciar Sesión"),
              Tab(text: "Registrarse"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LoginTab(),
            _RegisterTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------- LOGIN ----------------
class _LoginTab extends StatefulWidget {
  const _LoginTab({Key? key}) : super(key: key);

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final email = _correoCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa correo y contraseña')));
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error al iniciar sesión')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(child: Image.asset("assets/logo.png", height: 150)),
                const SizedBox(height: 18),
                TextField(
                  controller: _correoCtrl,
                  decoration: InputDecoration(
                    labelText: "Correo",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Iniciar", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecuperarContrasenaPage()));
                  },
                  child: Text(
                    "¿Olvidaste tu contraseña?",
                    style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- REGISTRO ----------------
class _RegisterTab extends StatefulWidget {
  const _RegisterTab({Key? key}) : super(key: key);

  @override
  State<_RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<_RegisterTab> {
  String? _rol;
  bool _loading = false;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _codigoEquipoController = TextEditingController();
  final TextEditingController _nombreEquipoController = TextEditingController();

  // 🔹 Generar código de equipo corto
  String generarCodigoEquipo() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final now = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(now + i) % chars.length]).join();
  }

  Future<void> _registrar() async {
    if (_nombreController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty ||
        _contrasenaController.text.trim().isEmpty ||
        _rol == null ||
        (_rol == "jugador" && _codigoEquipoController.text.trim().isEmpty) ||
        (_rol == "entrenador" && _nombreEquipoController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, completa todos los campos obligatorios."), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _contrasenaController.text.trim(),
      );

      final uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      // Crear usuario
      await db.collection("users").doc(uid).set({
        "name": _nombreController.text.trim(),
        "email": _correoController.text.trim(),
        "role": _rol,
      }, SetOptions(merge: true));

      if (_rol == "entrenador") {
        final teamCode = generarCodigoEquipo();

        final teamRef = await db.collection("teams").add({
          "name": _nombreEquipoController.text.trim(),
          "coachId": uid,
          "ownerId": uid,
          "teamCode": teamCode,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await teamRef.collection("players").doc(uid).set({
          "playerId": uid,
          "teamId": teamRef.id,
          "name": _nombreController.text.trim(),
          "email": _correoController.text.trim(),
          "role": "entrenador",
        });

        await db.collection("users").doc(uid).set({
          "teamId": teamRef.id,
          "teamName": _nombreEquipoController.text.trim(),
          "teamCode": teamCode,
        }, SetOptions(merge: true));
      } else if (_rol == "jugador") {
        final teamSnap = await db.collection("teams").where("teamCode", isEqualTo: _codigoEquipoController.text.trim()).limit(1).get();

        if (teamSnap.docs.isEmpty) {
          throw Exception("El código de equipo no existe");
        }

        final teamDoc = teamSnap.docs.first;

        await teamDoc.reference.collection("players").doc(uid).set({
          "playerId": uid,
          "teamId": teamDoc.id,
          "name": _nombreController.text.trim(),
          "email": _correoController.text.trim(),
          "role": "jugador",
        });

        await db.collection("users").doc(uid).set({
          "teamId": teamDoc.id,
          "teamName": teamDoc["name"],
          "teamCode": teamDoc["teamCode"],
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registro exitoso")));

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardPage()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _codigoEquipoController.dispose();
    _nombreEquipoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text("Crear una cuenta", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: "Nombre",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _correoController,
                  decoration: InputDecoration(
                    labelText: "Correo",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _contrasenaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: InputDecoration(
                    labelText: "Rol",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: "jugador", child: Text("Jugador")),
                    DropdownMenuItem(value: "entrenador", child: Text("Entrenador")),
                  ],
                  onChanged: (value) => setState(() => _rol = value),
                ),
                if (_rol == "jugador") ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codigoEquipoController,
                    decoration: InputDecoration(
                      labelText: "Código de equipo",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                if (_rol == "entrenador") ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nombreEquipoController,
                    decoration: InputDecoration(
                      labelText: "Nombre del equipo",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _registrar,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Registrar", style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
