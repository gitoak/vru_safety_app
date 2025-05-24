import 'package:equatable/equatable.dart';
import 'settings_event.dart';

/// State class for managing user and app settings.
class SettingsState extends Equatable {
  final VruCategory? vruCategory;
  final String? emergencyContact;
  final String? apiData;
  final bool isOnboardingCompleted;
  final bool notificationsEnabled;
  final bool audioAlertsEnabled;
  final bool vibrationEnabled;

  const SettingsState({
    this.vruCategory,
    this.emergencyContact,
    this.apiData,
    this.isOnboardingCompleted = false,
    this.notificationsEnabled = true,
    this.audioAlertsEnabled = true,
    this.vibrationEnabled = true,
  });

  SettingsState copyWith({
    VruCategory? vruCategory,
    String? emergencyContact,
    String? apiData,
    bool? isOnboardingCompleted,
    bool? notificationsEnabled,
    bool? audioAlertsEnabled,
    bool? vibrationEnabled,
  }) {
    return SettingsState(
      vruCategory: vruCategory ?? this.vruCategory,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      apiData: apiData ?? this.apiData,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      audioAlertsEnabled: audioAlertsEnabled ?? this.audioAlertsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  List<Object?> get props => [
    vruCategory,
    emergencyContact,
    apiData,
    isOnboardingCompleted,
    notificationsEnabled,
    audioAlertsEnabled,
    vibrationEnabled,
  ];
}
