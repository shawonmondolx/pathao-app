import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/domain/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Settings Options
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, color: AppColors.primary),
                  title: const Text(AppStrings.changePassword),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password flow requested')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.translate, color: AppColors.primary),
                  title: const Text(AppStrings.switchLanguage),
                  subtitle: const Text('English (US)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language switcher flow requested')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: AppColors.primary),
                  title: const Text(AppStrings.switchProfile),
                  subtitle: const Text('Hybrid Mode: Delivery / Pickup'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile toggle requested')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_in_talk, color: AppColors.green),
                  title: const Text(AppStrings.emergencyContact),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling Pathao Agent Support Hotline...')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Delete Account
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.statusBad),
              title: const Text(AppStrings.deleteAccount, style: TextStyle(color: AppColors.statusBad)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Account'),
                    content: const Text('Are you sure you want to request account deletion? This action is permanent.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusBad),
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                          Navigator.pop(context);
                          context.go('/login');
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusBad,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text(AppStrings.logout),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              '${AppStrings.version}: 7.1.2',
              style: TextStyle(color: AppColors.greyDarker, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
