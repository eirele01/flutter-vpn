import 'package:flutter/material.dart';

class ConnectButton extends StatefulWidget {
  final String state;
  final VoidCallback onTap;

  const ConnectButton({super.key, required this.state, required this.onTap});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool get _isConnecting =>
      widget.state == 'connecting' ||
      widget.state == 'wait_connection' ||
      widget.state == 'authenticating' ||
      widget.state == 'get_config' ||
      widget.state == 'tcp_connect';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (_isConnecting) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ConnectButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isConnecting) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color buttonColor;
    IconData icon;

    if (widget.state == 'connected') {
      buttonColor = const Color(0xFF7ED9A7); // Pastel Green
      icon = Icons.power_settings_new;
    } else if (_isConnecting) {
      buttonColor = const Color(0xFF8ECDF4); // Pastel Blue
      icon = Icons.sync_rounded;
    } else if (widget.state == 'error') {
      buttonColor = primaryColor;
      icon = Icons.priority_high_rounded;
    } else {
      buttonColor = isDark ? Colors.white24 : Colors.grey.shade400;
      icon = Icons.power_settings_new;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowFactor =
              (widget.state == 'connected' || _isConnecting)
                  ? _glowAnimation.value
                  : 1.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                if (widget.state == 'connected') ...[
                  BoxShadow(
                    color: buttonColor.withAlpha((80 * glowFactor).toInt()),
                    blurRadius: 40 * glowFactor,
                    spreadRadius: 10 * glowFactor,
                  ),
                  BoxShadow(
                    color: buttonColor.withAlpha((40 * glowFactor).toInt()),
                    blurRadius: 60 * glowFactor,
                    spreadRadius: 20 * glowFactor,
                  ),
                ],
                if (_isConnecting)
                  BoxShadow(
                    color: buttonColor.withAlpha((60 * glowFactor).toInt()),
                    blurRadius: 30 * glowFactor,
                    spreadRadius: 5 * glowFactor,
                  ),
                if (widget.state == 'disconnected')
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
              ],
              border: Border.all(
                color: buttonColor.withAlpha(isDark ? 100 : 50),
                width: 4,
              ),
            ),
            child: Center(
              child:
                  _isConnecting
                      ? RotationTransition(
                        turns: _rotationController,
                        child: Icon(icon, size: 80, color: buttonColor),
                      )
                      : Icon(icon, size: 80, color: buttonColor),
            ),
          );
        },
      ),
    );
  }
}
