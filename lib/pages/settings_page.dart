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

  String _categoryLabel(VruCategory cat) {
    switch (cat) {
      case VruCategory.deaf:
        return 'Deaf';
      case VruCategory.hardOfHearing:
        return 'Hard of Hearing';
      case VruCategory.blind:
        return 'Blind';
      case VruCategory.visuallyImpaired:
        return 'Visually Impaired';
      case VruCategory.intoxicated:
        return 'Intoxicated';
      case VruCategory.child:
        return 'Child';
    }
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
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<VruCategory>(
                      isExpanded: true,
                      value: state.vruCategory,
                      hint: const Text('Select impairment'),
                      underline: const SizedBox(),
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
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Emergency Contact Number', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controller,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    fillColor: Colors.grey[100],
                    filled: true,
                  ),
                  onChanged: (val) {
                    context.read<SettingsBloc>().add(SetEmergencyContact(val));
                  },
                ),
                const SizedBox(height: 32),
                // Add more settings here if needed
              ],
            ),
          ),
        );
      },
    );
  }
}
