// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muzakri/core/config/language_config.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_event.dart';
import 'package:muzakri/features/auth/presentation/bloc/auth_state.dart';
import 'package:muzakri/features/localization/presentation/bloc/localization_bloc.dart';
import 'package:muzakri/features/theme/presentation/cubit/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User information
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final user = state.maybeWhen(
                authenticated: (user) => user,
                orElse: () => null,
              );
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user?.displayName ?? 'Not signed in'),
                  subtitle: Text(user?.email ?? 'Not signed in'),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Theme Mode
          Card(
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                return ExpansionTile(
                  title: const Text('Theme'),
                  children: [
                    // Theme Mode Selection
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                      groupValue: state.mode,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<ThemeCubit>().setMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: state.mode,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<ThemeCubit>().setMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: state.mode,
                      onChanged: (value) {
                        if (value != null) {
                          context.read<ThemeCubit>().setMode(value);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Language
          Card(
            child: BlocBuilder<LocalizationBloc, LocalizationState>(
              builder: (context, state) {
                return ListTile(
                  title: const Text('Language'),
                  subtitle: Text(
                    state.locale.languageCode ==
                            LanguageConfig.defaultLanguageCode
                        ? 'Arabic'
                        : 'English',
                  ),
                  trailing: DropdownButton<Locale>(
                    value: state.locale,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(
                        value: Locale(LanguageConfig.defaultLanguageCode),
                        child: const Text('العربية'),
                      ),
                      const DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                    ],
                    onChanged: (loc) {
                      if (loc != null) {
                        context.read<LocalizationBloc>().add(
                          ChangeLanguage(loc),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Logout
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return ElevatedButton.icon(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const SignOutEvent()),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
