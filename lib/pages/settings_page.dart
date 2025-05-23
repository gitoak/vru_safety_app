import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Load initial value from Bloc state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SettingsBloc>().state;
      _controller.text = state.emergencyContact ?? '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _categoryLabel(VruCategory cat) {
    switch (cat) {
      case VruCategory.blind:
        return 'Blind';
      case VruCategory.visuallyImpaired:
        return 'Visually Impaired';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define a minimum size for tap targets
    const minButtonSize = Size(48, 48);
    // Define a style for ElevatedButton to ensure minimum tap target size
    final ButtonStyle minSizeButtonStyle = ElevatedButton.styleFrom(
      minimumSize: minButtonSize,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Ensure padding contributes to size
    );

    return Scaffold( // Added Scaffold
      appBar: AppBar( // Added AppBar
        title: const Text('Settings'), // Added title to AppBar
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (prev, curr) => prev.emergencyContact != curr.emergencyContact,
        listener: (context, state) {
          if (_controller.text != (state.emergencyContact ?? '')) {
            _controller.text = state.emergencyContact ?? '';
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const Text('Impairment Category', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  // Replaced DecoratedBox and DropdownButton with DropdownButtonFormField
                  DropdownButtonFormField<VruCategory>(
                    value: state.vruCategory,
                    hint: const Text('Select impairment'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      // Using default InputDecoration to pick up theme styles
                      // border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), // Already handled by theme
                      // fillColor: Colors.grey[100], // Removed to use theme default
                      // filled: true, // Already handled by theme
                    ),
                    items: VruCategory.values.map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(_categoryLabel(cat)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<SettingsBloc>().add(SetVruCategory(val));
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Emergency Contact Section
                  const Text('Emergency Contact Number', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      labelText: 'Emergency Contact Number', // Added labelText
                      // Removed fillColor and filled to use theme defaults
                      // Removed explicit border to use theme's default OutlineInputBorder
                      // border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      // fillColor: Colors.grey[100],
                      // filled: true,
                    ),
                    onFieldSubmitted: (val) {
                      context.read<SettingsBloc>().add(SetEmergencyContact(val));
                      FocusScope.of(context).unfocus(); // Close the keyboard
                    },
                    onEditingComplete: () {
                      context.read<SettingsBloc>().add(SetEmergencyContact(_controller.text));
                      FocusScope.of(context).unfocus(); // Close the keyboard
                    },
                    onChanged: (val) {
                      // Only update the local state, don't save to storage yet
                    },
                  ),
                  const SizedBox(height: 32),
                  // Permissions Management Button
                  ElevatedButton.icon(
                    style: minSizeButtonStyle, // Apply the style
                    icon: const Icon(Icons.security),
                    label: const Text('Manage Permissions'),
                    onPressed: () {
                      // TODO: Implement permissions management
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Manage Permissions'),
                          content: const Text('Here you can manage app permissions.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // About & Feedback Button
                  ElevatedButton.icon(
                    style: minSizeButtonStyle, // Apply the style
                    icon: const Icon(Icons.info_outline),
                    label: const Text('About & Feedback'),
                    onPressed: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'VRU Safety App',
                        applicationVersion: '1.0.0',
                        applicationIcon: Icon(Icons.security, size: 40),
                        children: [
                          const SizedBox(height: 16),
                          const Text('Feedback: vru-app@example.com'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Add more settings here if needed

                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Developer Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: minSizeButtonStyle, // Apply the style
                    icon: const Icon(Icons.replay_outlined),
                    label: const Text('Reset Onboarding (Dev)'),
                    onPressed: () async {
                      // This button is for development/testing purposes
                      final bloc = context.read<SettingsBloc>();
                      bloc.add(ResetOnboarding()); // Assuming you'll add this event
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Onboarding reset. Restart the app to see changes.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
