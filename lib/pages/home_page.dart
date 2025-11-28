import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import 'lobby_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ws = Provider.of<WebSocketService>(context, listen: false);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'JOGGUS POKER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width:MediaQuery.of(context).size.width * 0.4 > 300 ? MediaQuery.of(context).size.width * 0.4 : MediaQuery.of(context).size.width * 0.8  ,
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, ),
                  decoration: InputDecoration(
                    labelText: 'Seu nome',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.amber, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width:MediaQuery.of(context).size.width * 0.4 > 300 ? MediaQuery.of(context).size.width * 0.4 : MediaQuery.of(context).size.width * 0.8  ,
                child: TextField(
                  controller: _roomController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ID da sala (opcional)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.greenAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.amber, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;

                      ws.send('create_room', {'player_name': name});

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LobbyPage(
                            playerName: name,
                            isCreator: true,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text(
                      'Criar Sala',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final roomId = _roomController.text.trim();
                      if (name.isEmpty || roomId.isEmpty) return;

                      ws.send('join_room', {
                        'room_id': roomId,
                        'player_name': name,
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LobbyPage(
                            playerName: name,
                            isCreator: false,
                            roomId: roomId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    child: const Text(
                      'Entrar na Sala',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
