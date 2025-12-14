import 'package:flutter/material.dart';
import 'home_page.dart';

class GameSelectionPage extends StatelessWidget {
  const GameSelectionPage({super.key});

  final List<Map<String, dynamic>> games = const [
    {'name': 'Poker', 'icon': Icons.casino, 'enabled': true},
    {'name': 'Truco', 'icon': Icons.style, 'enabled': false},
    {'name': 'Pife', 'icon': Icons.view_carousel, 'enabled': false},
    {'name': 'Jogo do 9', 'icon': Icons.filter_9, 'enabled': false},
    {'name': 'Canastra', 'icon': Icons.layers, 'enabled': false},
    {'name': 'Bisca', 'icon': Icons.content_copy, 'enabled': false},
    {'name': 'Ludo', 'icon': Icons.grid_view, 'enabled': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Escolha o Jogo'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 5,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return _buildGameCard(context, game);
          },
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, Map<String, dynamic> game) {
    final isEnabled = game['enabled'] as bool;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isEnabled) {
            if (game['name'] == 'Poker') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Em desenvolvimento'),
                backgroundColor: Colors.amber,
                duration: Duration(seconds: 1),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF1E1E1E)
                : const Color(0xFF1E1E1E).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEnabled
                  ? Colors.greenAccent
                  : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                game['icon'],
                size: 48,
                color: isEnabled ? Colors.greenAccent : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                game['name'],
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.grey,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isEnabled) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Em breve',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
