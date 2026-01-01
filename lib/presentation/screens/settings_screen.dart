import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Theme"),
            subtitle: const Text("System Default"),
            trailing: const Icon(Icons.brightness_6),
            onTap: () {
              // ToDo
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Auto-Refresh Servers"),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text("Kill Switch"),
            subtitle: const Text("Block internet when VPN drops (Android 8+)"),
            value: false,
            onChanged: (val) {},
          ),
          const Divider(),

          ListTile(title: const Text("Version"), subtitle: const Text("1.0.0")),
        ],
      ),
    );
  }
}
