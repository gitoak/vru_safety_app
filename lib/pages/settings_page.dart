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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsBloc, SettingsState>(
      listenWhen: (prev, curr) => prev.emergencyContact != curr.emergencyContact,
      listener: (context, state) {
        if (_controller.text != (state.emergencyContact ?? '')) {
          _controller.text = state.emergencyContact ?? '';
        }
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select your VRU category:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...VruCategory.values.map((cat) => RadioListTile<VruCategory>(
                    title: Text(cat.name.replaceAll(RegExp(r'([A-Z])'), ' ' r'$1').replaceAll('_', ' ').capitalize()),
                    value: cat,
                    groupValue: state.vruCategory,
                    onChanged: (val) {
                      if (val != null) {
                        context.read<SettingsBloc>().add(SetVruCategory(val));
                      }
                    },
                  )),
              const SizedBox(height: 24),
              const Text('Emergency Contact Number:', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Enter phone number'),
                onChanged: (val) {
                  context.read<SettingsBloc>().add(SetEmergencyContact(val));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
