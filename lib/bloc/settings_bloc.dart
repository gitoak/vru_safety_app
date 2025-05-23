import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_state.dart';

abstract class SettingsEvent {}

class SetVruCategory extends SettingsEvent {
  final VruCategory category;
  SetVruCategory(this.category);
}

class SetEmergencyContact extends SettingsEvent {
  final String contact;
  SetEmergencyContact(this.contact);
}

class SetApiData extends SettingsEvent {
  final String data;
  SetApiData(this.data);
}

class LoadSettings extends SettingsEvent {}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<SetVruCategory>(_onSetVruCategory);
    on<SetEmergencyContact>(_onSetEmergencyContact);
    on<SetApiData>(_onSetApiData);
    add(LoadSettings());
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final vruIndex = prefs.getInt('vruCategory');
    final contact = prefs.getString('emergencyContact');
    final apiData = prefs.getString('apiData');
    emit(state.copyWith(
      vruCategory: vruIndex != null ? VruCategory.values[vruIndex] : null,
      emergencyContact: contact,
      apiData: apiData,
    ));
  }

  Future<void> _onSetVruCategory(SetVruCategory event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vruCategory', event.category.index);
    emit(state.copyWith(vruCategory: event.category));
  }

  Future<void> _onSetEmergencyContact(SetEmergencyContact event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergencyContact', event.contact);
    emit(state.copyWith(emergencyContact: event.contact));
  }

  Future<void> _onSetApiData(SetApiData event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiData', event.data);
    emit(state.copyWith(apiData: event.data));
  }
}
