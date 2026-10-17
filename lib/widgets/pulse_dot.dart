import 'package:flutter/material.dart';

/// Ponto de status com anel pulsante.
///
/// O design.md pede pulso contínuo nos indicadores ao vivo. Fica num
/// [RepaintBoundary] porque o painel roda horas seguidas e não vale repintar
/// a árvore inteira a cada frame por causa de um ponto de 8px.
///
/// Respeita `MediaQuery.disableAnimations`: com movimento reduzido ligado, o
/// ponto fica estático em vez de pulsar.
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    required this.color,
    this.size = 8,
    this.active = true,
  });

  final Color color;
  final double size;

  /// Sem conexão ativa o pulso para — um ponto pulsando sem feed mente.
  final bool active;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncAnimation();
  }

  void _syncAnimation() {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.active && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    );

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                if (t == 0) return const SizedBox.shrink();
                return IgnorePointer(
                  child: Transform.scale(
                    scale: 1 + t * 1.4,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(alpha: 0.75 * (1 - t)),
                      ),
                    ),
                  ),
                );
              },
            ),
            dot,
          ],
        ),
      ),
    );
  }
}
