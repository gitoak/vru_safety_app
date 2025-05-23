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

  void _finishOnboarding() {
    if (_selectedCategory != null) {
      context.read<SettingsBloc>().add(SetVruCategory(_selectedCategory!));
    }
    context.read<SettingsBloc>().add(SetEmergencyContact(_contactController.text));
    if (widget.onFinish != null) widget.onFinish!();
  }

  String _getCategoryLabel(VruCategory cat) {
    switch (cat) {
      case VruCategory.blind:
        return 'Blind';
      case VruCategory.visuallyImpaired:
        return 'Visually Impaired (e.g., low vision)';
    }
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        key: const ValueKey('intro'), // For AnimatedSwitcher
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to VRU Safety',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'This app helps you navigate more safely. Let\'s get you set up.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        key: const ValueKey('category'), // For AnimatedSwitcher
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tell Us About Yourself',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...VruCategory.values.map((cat) => RadioListTile<VruCategory>(
                title: Text(_getCategoryLabel(cat)),
                value: cat,
                groupValue: _selectedCategory,
                onChanged: (VruCategory? value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    context.read<SettingsBloc>().add(SetVruCategory(value));
                  }
                },
              )),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _selectedCategory != null ? _nextStep : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildContact() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Emergency Contact',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Please enter the phone number of an emergency contact.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact Phone Number', // Added labelText
              hintText: 'Enter phone number',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissions() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Location Permissions',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'This app requires access to your location to provide safety alerts and navigation assistance.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Grant Permissions (Placeholder)'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinish() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "You're All Set!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Thank you for setting up the VRU Safety App.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _finishOnboarding,
            style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48)),
            child: const Text('Finish Setup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_step) {
      case 0:
        currentPage = _buildIntro();
        break;
      case 1:
        currentPage = _buildCategory();
        break;
      case 2:
        currentPage = _buildContact();
        break;
      case 3:
        currentPage = _buildPermissions();
        break;
      case 4:
        currentPage = _buildFinish();
        break;
      default:
        currentPage = _buildIntro();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Setup - Step ${_step + 1} of 5'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: currentPage,
      ),
    );
  }
}
