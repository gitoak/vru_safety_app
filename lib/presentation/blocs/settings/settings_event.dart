import 'package:equatable/equatable.dart';

/// Enumeration of VRU (Vulnerable Road User) categories.
enum VruCategory { 
  blind, 
  visuallyImpaired,
}

/// Base class for all settings-related events.
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to set the selected VRU (Vulnerable Road User) category.
class SetVruCategory extends SettingsEvent {
  /// The VRU category to set.
  final VruCategory category;
  
  const SetVruCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Event to set the emergency contact string.
class SetEmergencyContact extends SettingsEvent {
  /// The emergency contact value.
  final String contact;
  
  const SetEmergencyContact(this.contact);

  @override
  List<Object?> get props => [contact];
}

/// Event to set arbitrary API data (such as tokens or config).
class SetApiData extends SettingsEvent {
  /// The API data value.
  final String data;
  
  const SetApiData(this.data);

  @override
  List<Object?> get props => [data];
}

/// Event to load all settings from persistent storage.
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Event to reset onboarding status for the user.
class ResetOnboarding extends SettingsEvent {
  const ResetOnboarding();
}
