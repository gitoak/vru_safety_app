import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';
import '../blocs/settings/settings_event.dart';

/// Settings page that allows users to configure app preferences.
/// Includes emergency contact configuration, notification settings,
/// and other user-customizable options.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// Controller for the emergency contact text field.
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

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
    const minButtonSize = Size(48, 48);

    final ButtonStyle minSizeButtonStyle = ElevatedButton.styleFrom(
      minimumSize: minButtonSize,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (prev, curr) =>
            prev.emergencyContact != curr.emergencyContact,
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
                  const Text(
                    'Profile Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Impairment Category',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<VruCategory>(
                    value: state.vruCategory,
                    hint: const Text('Select impairment'),
                    isExpanded: true,
                    decoration: InputDecoration(),
                    items: VruCategory.values
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(_categoryLabel(cat)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<SettingsBloc>().add(SetVruCategory(val));
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Emergency Contact Number',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      labelText: 'Emergency Contact Number',
                    ),
                    onFieldSubmitted: (val) {
                      context.read<SettingsBloc>().add(
                        SetEmergencyContact(val),
                      );
                      FocusScope.of(context).unfocus();
                    },
                    onEditingComplete: () {
                      context.read<SettingsBloc>().add(
                        SetEmergencyContact(_controller.text),
                      );
                      FocusScope.of(context).unfocus();
                    },
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    style: minSizeButtonStyle,
                    icon: const Icon(Icons.security),
                    label: const Text('Manage Permissions'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Manage Permissions'),
                          content: const Text(
                            'Here you can manage app permissions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: minSizeButtonStyle,
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

                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Developer Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: minSizeButtonStyle,
                    icon: const Icon(Icons.replay_outlined),
                    label: const Text('Reset Onboarding (Dev)'),
                    onPressed: () async {
                      final bloc = context.read<SettingsBloc>();
                      bloc.add(ResetOnboarding());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Onboarding reset. Restart the app to see changes.',
                          ),
                        ),
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
