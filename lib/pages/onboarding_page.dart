import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_state.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback? onFinish;
  const OnboardingPage({super.key, this.onFinish});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;
  late TextEditingController _contactController;
  VruCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final state = context.read<SettingsBloc>().state;
    _contactController = TextEditingController(text: state.emergencyContact ?? '');
    _selectedCategory = state.vruCategory;
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _step++;
    });
  }

  void _finishOnboarding() { // Removed async, as SharedPreferences calls are removed
    if (_selectedCategory != null) {
      context.read<SettingsBloc>().add(SetVruCategory(_selectedCategory!));
    }
    context.read<SettingsBloc>().add(SetEmergencyContact(_contactController.text));
    // SharedPreferences update and navigation/state change are handled by the onFinish callback in main.dart
    if (widget.onFinish != null) widget.onFinish!();
    // Navigator.of(context).pop(); // Removed: Not suitable for this page's presentation
  }

  String _getCategoryLabel(VruCategory cat) {
    switch (cat) {
      case VruCategory.blind:
        return 'Blind';
      case VruCategory.visuallyImpaired:
        return 'Visually Impaired';
      // Removed redundant default case as all enum values are handled
    }
  }

  Widget _buildIntro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Welcome to VRU Safety App!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('This app helps you stay safe as a vulnerable road user.'),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _nextStep,
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _buildCategory() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your impairment category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<VruCategory>(
          value: _selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: VruCategory.values.map((cat) => DropdownMenuItem(
            value: cat,
            child: Text(_getCategoryLabel(cat)), // Use the helper function here
          )).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: _selectedCategory != null ? _nextStep : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContact() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Set your emergency contact number', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Enter phone number',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Back'),
            ),
            ElevatedButton(
              onPressed: () => _nextStep(),
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Permissions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('To function properly, the app needs access to your location.'),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            // Request location permission
            // (You can use Geolocator.requestPermission() here if needed)
            _nextStep();
          },
          child: const Text('Grant Location Permission'),
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildFinish() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Setup Complete!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('You can change your settings at any time.'),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _finishOnboarding,
          child: const Text('Finish'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_step) {
      case 0:
        content = _buildIntro();
        break;
      case 1:
        content = _buildCategory();
        break;
      case 2:
        content = _buildContact();
        break;
      case 3:
        content = _buildPermissions();
        break;
      default:
        content = _buildFinish();
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
