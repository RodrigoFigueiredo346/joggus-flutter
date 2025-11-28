import 'package:flutter/material.dart';
import 'package:joggus/services/websocket_service.dart';
import 'package:provider/provider.dart';

class TurnTimerBar extends StatefulWidget {
  final bool isLocal;
  const TurnTimerBar({super.key, this.isLocal = false});

  @override
  State<TurnTimerBar> createState() => _TurnTimerBarState();
}

class _TurnTimerBarState extends State<TurnTimerBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();

    // controla o progresso da barra (20s)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..forward();

    // controla o piscar (1Hz)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.4,
      upperBound: 1.0,
    );

    _progressController.addListener(() {
      final value = _progressController.value;
      // Começa a piscar quando faltar 30% do tempo (aprox 6s)
      if (value > 0.7 && !_blinkController.isAnimating) {
        _blinkController.repeat(reverse: true);
      }
    });

    // quando acabar o tempo, fold automático (apenas se for o jogador local)
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        if (widget.isLocal) {
          debugPrint('[TurnTimerBar] Time expired. Auto-folding.');
          context.read<WebSocketService>().playerAction('fold');
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _blinkController]),
      builder: (context, _) {
        // value vai de 0 a 1. Queremos a barra diminuindo?
        // Se width = 80 * (1 - value), ela diminui.
        final progress = 1.0 - _progressController.value;

        // Cor vai do verde ao vermelho
        final color = Color.lerp(
          Colors.green,
          Colors.red,
          _progressController.value,
        );

        return Opacity(
          opacity: _blinkController.isAnimating ? _blinkController.value : 1.0,
          child: Container(
            width: 80 * progress,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
