import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC that handles user and app settings, with persistence.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String _vruCategoryKey = 'vru_category';
  static const String _emergencyContactKey = 'emergency_contact';
  static const String _apiDataKey = 'api_data';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _audioAlertsEnabledKey = 'audio_alerts_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';

  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<SetVruCategory>(_onSetVruCategory);
    on<SetEmergencyContact>(_onSetEmergencyContact);
    on<SetApiData>(_onSetApiData);
    on<ResetOnboarding>(_onResetOnboarding);
    
    // Load settings on initialization
    add(const LoadSettings());
  }

  /// Loads settings from [SharedPreferences] and updates state.
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final vruCategoryIndex = prefs.getInt(_vruCategoryKey);
      final emergencyContact = prefs.getString(_emergencyContactKey);
      final apiData = prefs.getString(_apiDataKey);
      final isOnboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
      final notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      final audioAlertsEnabled = prefs.getBool(_audioAlertsEnabledKey) ?? true;
      final vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;

      emit(state.copyWith(
        vruCategory: vruCategoryIndex != null 
          ? VruCategory.values[vruCategoryIndex] 
          : null,
        emergencyContact: emergencyContact,
        apiData: apiData,
        isOnboardingCompleted: isOnboardingCompleted,
        notificationsEnabled: notificationsEnabled,
        audioAlertsEnabled: audioAlertsEnabled,
        vibrationEnabled: vibrationEnabled,
      ));
    } catch (e) {
      // Handle error loading settings
      emit(const SettingsState()); // Reset to default state
    }
  }

  /// Sets the VRU category and persists it.
  Future<void> _onSetVruCategory(
    SetVruCategory event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_vruCategoryKey, event.category.index);
    emit(state.copyWith(vruCategory: event.category));
  }

  /// Sets the emergency contact and persists it.
  Future<void> _onSetEmergencyContact(
    SetEmergencyContact event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emergencyContactKey, event.contact);
    emit(state.copyWith(emergencyContact: event.contact));
  }

  /// Sets the API data and persists it.
  Future<void> _onSetApiData(
    SetApiData event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiDataKey, event.data);
    emit(state.copyWith(apiData: event.data));
  }

  /// Resets onboarding status.
  Future<void> _onResetOnboarding(
    ResetOnboarding event,
    Emitter<SettingsState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, false);
    emit(state.copyWith(isOnboardingCompleted: false));
  }
}
