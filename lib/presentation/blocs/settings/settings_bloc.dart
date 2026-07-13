import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// --- Events ---

/// Classe base abstrata para todos os eventos de configurações do aplicativo.
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Evento disparado para carregar as configurações iniciais padrões.
class LoadSettingsEvent extends SettingsEvent {}

/// Evento disparado ao alterar o idioma selecionado.
class ChangeLanguageEvent extends SettingsEvent {
  final String languageCode;

  const ChangeLanguageEvent(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

/// Evento disparado ao alterar o fuso horário (timezone) selecionado.
class ChangeTimezoneEvent extends SettingsEvent {
  final String timezone;

  const ChangeTimezoneEvent(this.timezone);

  @override
  List<Object?> get props => [timezone];
}

// --- States ---

/// Estado que encapsula as configurações de internacionalização e fuso horário.
class SettingsState extends Equatable {
  final Locale locale;
  final String timezone;

  const SettingsState({
    required this.locale,
    required this.timezone,
  });

  /// Retorna um novo [SettingsState] copiando os valores e substituindo os informados.
  SettingsState copyWith({
    Locale? locale,
    String? timezone,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  List<Object?> get props => [locale, timezone];
}

// --- BLoC ---

/// Gerenciador de estado BLoC responsável pelo idioma (i18n) e fuso horário (timezone).
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc()
      : super(const SettingsState(
          locale: Locale('pt'),
          timezone: 'GMT-3 (America/Sao_Paulo)',
        )) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<ChangeLanguageEvent>(_onChangeLanguage);
    on<ChangeTimezoneEvent>(_onChangeTimezone);
  }

  /// Carrega as configurações padrões de idioma e timezone (GMT São Paulo).
  void _onLoadSettings(LoadSettingsEvent event, Emitter<SettingsState> emit) {
    // Configurações já iniciadas no estado inicial.
    emit(state);
  }

  /// Altera o código de idioma atual e notifica os observadores.
  void _onChangeLanguage(ChangeLanguageEvent event, Emitter<SettingsState> emit) {
    emit(state.copyWith(locale: Locale(event.languageCode)));
  }

  /// Altera o fuso horário atual e notifica os observadores.
  void _onChangeTimezone(ChangeTimezoneEvent event, Emitter<SettingsState> emit) {
    emit(state.copyWith(timezone: event.timezone));
  }
}
