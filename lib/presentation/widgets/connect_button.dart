import 'package:flutter/material.dart';

class ConnectButton extends StatefulWidget {
  final String state;
  final VoidCallback onTap;

  const ConnectButton({super.key, required this.state, required this.onTap});

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors and icons based on requested logic
    Color buttonColor;
    IconData icon;
    List<BoxShadow> shadows = [];

    if (widget.state == 'connected') {
      buttonColor = Colors.green;
      icon = Icons.power_settings_new;
      // Luminance/Glow Effect
      shadows = [
        BoxShadow(
          color: Colors.green.withAlpha(150),
          blurRadius: 30,
          spreadRadius: 8,
        ),
        BoxShadow(
          color: Colors.green.withAlpha(80),
          blurRadius: 50,
          spreadRadius: 15,
        ),
      ];
    } else if (_isConnecting) {
      buttonColor = Colors.blue;
      icon = Icons.sync_rounded;
      shadows = [
        BoxShadow(
          color: Colors.blue.withAlpha(100),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
    } else if (widget.state == 'error') {
      buttonColor = Colors.redAccent;
      icon = Icons.priority_high_rounded;
    } else {
      // Disconnected
      buttonColor = Colors.grey.shade400;
      icon = Icons.power_settings_new;
      shadows = [
        BoxShadow(
          color: Colors.black.withAlpha(20),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withAlpha(10)
                  : Colors.white,
          boxShadow: shadows,
          border: Border.all(color: buttonColor.withAlpha(80), width: 4),
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
      ),
    );
  }
}
