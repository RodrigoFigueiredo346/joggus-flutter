import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/websocket_service.dart';
import 'pages/game_selection_page.dart';

void main() {
  runApp(const JoggusApp());
}

class JoggusApp extends StatelessWidget {
  const JoggusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebSocketService()..connect(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Joggus',
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.greenAccent,
            secondary: Colors.amber,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const GameSelectionPage(),
      ),
    );
  }
}
