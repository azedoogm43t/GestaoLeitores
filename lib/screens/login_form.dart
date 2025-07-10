import 'package:flutter/material.dart';
import 'package:gestao_leitores/screens/home_screen.dart';
import 'package:gestao_leitores/screens/register_form.dart';
import 'package:gestao_leitores/services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _service = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _celularController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _loading = false;

  void _mostrarMensagem(String texto, {bool erro = false}) {
    final color = erro ? Colors.red : Colors.green;
    final snack = SnackBar(
      content: Text(texto, textAlign: TextAlign.center),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final celular = _celularController.text.trim();
      final senha = _senhaController.text.trim();

      final usuario = await _service.login(celular, senha);
      if (usuario != null) {
        _mostrarMensagem('Login realizado com sucesso!');
        // Navegue para a home ou outra tela aqui:
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => HomeScreen(usuario: usuario)));
      } else {
        _mostrarMensagem('Usuário ou senha incorretos', erro: true);
      }
    } catch (e) {
      _mostrarMensagem('Erro ao tentar logar', erro: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _celularController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/leitores.jpg', // corrigido: sem './'
                        height: 150,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _celularController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Celular',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe o celular' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe a senha' : null,
                      ),
                      const SizedBox(height: 24),
                      _loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 13, 128, 42),
                                ),
                                onPressed: _login,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Text('Entrar',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16)),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                // -------- Footer --------
                Column(
                  children: const [
                    Divider(),
                    SizedBox(height: 6),
                    Text(
                      'Desenvolvido por Dênis & Januário',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Contacto: +258 82 489 2424',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
