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
          backgroundColor: Colors.blue[800],
          centerTitle: true,
          title: const Text(
            "CoachUp",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
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

class _LoginTab extends StatefulWidget {
  const _LoginTab();

  @override
  State<_LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<_LoginTab> {
  final TextEditingController _correoCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _correoCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inicio de sesión exitoso")),
      );

      // 👇 Ir al Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Error al iniciar sesión";
      if (e.code == "user-not-found") msg = "Usuario no encontrado";
      if (e.code == "wrong-password") msg = "Contraseña incorrecta";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(child: Image.asset("assets/logo.png", height: 150)),
            const SizedBox(height: 30),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Iniciar", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecuperarContrasenaPage()),
                );
              },
              child: const Text("¿Olvidaste tu contraseña?",
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterTab extends StatefulWidget {
  const _RegisterTab();

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

  Future<void> _registrar() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _contrasenaController.text.trim(),
      );

      final uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      await db.collection("users").doc(uid).set({
        "name": _nombreController.text.trim(),
        "email": _correoController.text.trim(),
        "role": _rol,
      });

      if (_rol == "entrenador") {
        final teamRef = await db.collection("teams").add({
          "name": _nombreEquipoController.text.trim(),
          "coachId": uid,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await teamRef.collection("players").doc(uid).set({
          "playerId": uid,
          "name": _nombreController.text.trim(),
          "email": _correoController.text.trim(),
          "role": "entrenador",
        });

        await db.collection("users").doc(uid).update({
          "teamName": _nombreEquipoController.text.trim(),
          "teamCode": teamRef.id,
        });
      } else if (_rol == "jugador") {
        final teamId = _codigoEquipoController.text.trim();
        await db.collection("teams").doc(teamId).collection("players").doc(uid).set({
          "playerId": uid,
          "name": _nombreController.text.trim(),
          "email": _correoController.text.trim(),
          "role": "jugador",
        });

        await db.collection("users").doc(uid).update({
          "teamCode": teamId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registro exitoso")),
      );

      //  Ir a la pantalla de Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Error al registrarse";
      if (e.code == "email-already-in-use") msg = "Ese correo ya está en uso";
      if (e.code == "weak-password") msg = "La contraseña es demasiado débil";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
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
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("Crear una cuenta", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
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
                  labelText: "Código de equipo (ID)",
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Registrar", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
