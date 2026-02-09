import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  final double size;

  const LoadingWidget({super.key, this.size = 50.0});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -widget.size * 0.5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );

    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: child,
          );
        },
        child: RotationTransition(
          turns: _rotationController,
          child: Image.asset(
            'assets/images/ball.png',
            width: widget.size,
            height: widget.size,
          ),
        ),
      ),
    );
  }
}