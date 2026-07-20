import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  Widget _buildPermissionRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.redLighter,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.greyDarker, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                AppStrings.permissionTitle,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.permissionSubtitle,
                style: TextStyle(color: AppColors.greyDarker, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionRow(
                      Icons.location_on,
                      AppStrings.locationPermission,
                      'Required to track your delivery run and report location status to customers.',
                    ),
                    _buildPermissionRow(
                      Icons.notifications,
                      AppStrings.notificationPermission,
                      'Required to receive real-time consignment assignments and updates.',
                    ),
                    _buildPermissionRow(
                      Icons.camera_alt,
                      AppStrings.cameraPermission,
                      'Required to take photo proof for successful delivery and barcode scans.',
                    ),
                    _buildPermissionRow(
                      Icons.folder,
                      AppStrings.storagePermission,
                      'Required to store offline log data and cached image assets.',
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Simply proceed to home (Mocking permissions approve)
                  context.go('/home');
                },
                child: const Text(AppStrings.continueBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
