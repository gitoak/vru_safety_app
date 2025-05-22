import 'package:equatable/equatable.dart';

enum VruCategory {
  deaf,
  hardOfHearing,
  blind,
  visuallyImpaired,
  intoxicated,
  child,
}

class SettingsState extends Equatable {
  final VruCategory? vruCategory;
  final String? emergencyContact;
  final String? apiData; // For data set by API, not shown in UI

  const SettingsState({
    this.vruCategory,
    this.emergencyContact,
    this.apiData,
  });

  SettingsState copyWith({
    VruCategory? vruCategory,
    String? emergencyContact,
    String? apiData,
  }) {
    return SettingsState(
      vruCategory: vruCategory ?? this.vruCategory,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      apiData: apiData ?? this.apiData,
    );
  }

  @override
  List<Object?> get props => [vruCategory, emergencyContact, apiData];
}
