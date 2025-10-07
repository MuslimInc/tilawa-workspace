import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

          // Theme
          Card(
            child: BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, state) {
                final isDark = state.mode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text('Dark Theme'),
                  value: isDark,
                  onChanged: (v) => context.read<ThemeCubit>().toggleDark(v),
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
                    state.locale.languageCode == 'ar' ? 'Arabic' : 'English',
                  ),
                  trailing: DropdownButton<Locale>(
                    value: state.locale,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: Locale('ar'),
                        child: Text('العربية'),
                      ),
                      DropdownMenuItem(
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
