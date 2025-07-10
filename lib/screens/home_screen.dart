import 'package:flutter/material.dart';
import 'package:gestao_leitores/models/usuarios.dart';
import 'package:gestao_leitores/screens/leitores_list.dart';
import 'package:gestao_leitores/screens/register_form.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firestore_service.dart';
import '../models/leitor.dart';
import 'leitor_form.dart';
import 'escala_form.dart';
import 'escala_liturgica_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.leitor, this.usuario}) : super(key: key);

  final Leitor? leitor;
  final Usuario? usuario;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService service = FirestoreService();
  final Map<DateTime, List<String>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  void _addEvent(DateTime day) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova nota / evento'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Descrição'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salvar')),
        ],
      ),
    );

    if (ok == true && controller.text.trim().isNotEmpty) {
      setState(() {
        final key = DateTime(day.year, day.month, day.day);
        _events.putIfAbsent(key, () => []).add(controller.text.trim());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Gestão de Leitores'),
            if (widget.usuario != null)
              Text(
                widget.usuario!.nome,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: StreamBuilder<List<Leitor>>(
        stream: service.getLeitores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final leitores = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // ---------- CALENDÁRIO ----------
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                    _selectedDay != null && isSameDay(d, _selectedDay),
                calendarFormat: CalendarFormat.month,
                eventLoader: (day) =>
                    _events[DateTime(day.year, day.month, day.day)] ?? [],
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  _addEvent(selected); // abre diálogo para nova nota
                },
              ),
              const SizedBox(height: 8),

              // ---------- CARD COM TOTAL ----------
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LeitoresPage()),
                  );
                },
                child: Card(
                  color: Colors.teal.shade50,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.groups, color: Colors.teal),
                    title: const Text('Total de leitores cadastrados'),
                    trailing: Text(
                      '${leitores.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.teal.shade700,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomBarButton(
                icon: Icons.person_add,
                label: 'Leitor',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LeitorForm()),
                ),
              ),
              _BottomBarButton(
                icon: Icons.person_add,
                label: 'Utilizador',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                ),
              ),
              _BottomBarButton(
                icon: Icons.event,
                label: 'Nova Escala',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EscalaForm()),
                ),
              ),
              _BottomBarButton(
                icon: Icons.view_list,
                label: 'Ver Escalas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          EscalaLiturgicaView(usuario: widget.usuario)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
