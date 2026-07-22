import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/delivery/domain/delivery_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/permissions_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/delivery/presentation/delivery_list_screen.dart';
import '../../features/delivery/presentation/delivery_detail_screen.dart';
import '../../features/delivery/presentation/proof_upload_screen.dart';
import '../../features/delivery/presentation/drto_screen.dart';
import '../../features/pickup/presentation/pickup_list_screen.dart';
import '../../features/pickup/presentation/pickup_detail_screen.dart';
import '../../features/return/presentation/return_list_screen.dart';
import '../../features/return/presentation/return_detail_screen.dart';
import '../../features/earnings/presentation/earnings_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/scanner/presentation/qr_scanner_screen.dart';
import '../../features/delivery/presentation/otp_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) async {
    final secureStorage = SecureStorage();
    final token = await secureStorage.getToken();
    
    final loggingIn = state.matchedLocation == '/login';
    final checkingPermissions = state.matchedLocation == '/permissions';
    
    if (token == null && !loggingIn && !checkingPermissions) {
      return '/login';
    }
    if (token != null && loggingIn) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionsScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/deliveries',
      builder: (context, state) => const DeliveryListScreen(),
    ),
    GoRoute(
      path: '/delivery/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DeliveryDetailScreen(consignmentId: id);
      },
    ),
    GoRoute(
      path: '/delivery/:id/drto',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final extras = state.extra as Map<String, dynamic>?;
        return DrtoScreen(
          consignmentId: id,
          runOrderId: extras?['runOrderId'] ?? 0,
          recipientPhone: extras?['recipientPhone'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/delivery/:id/otp',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final extras = state.extra as Map<String, dynamic>?;
        // Bug fix: detail screen passes 'recipientPhone', not 'phone'
        final recipientPhone = extras?['recipientPhone'] as String? ?? extras?['phone'] as String? ?? '';
        final runOrderId = (extras?['runOrderId'] as int?) ?? 0;
        final collectedAmount = (extras?['collectedAmount'] as double?) ?? 0.0;
        final status = (extras?['status'] as int?) ?? 2;
        final needsQcButton = (extras?['needsQcButton'] as bool?) ?? false;
        final otpTarget = (extras?['otpTarget'] as String?) ?? 'merchant';
        final proceedMethod = (extras?['proceedMethod'] as int?) ?? ProceedMethod.qrScan;
        return OtpScreen(
          consignmentId: id,
          runOrderId: runOrderId,
          recipientPhone: recipientPhone,
          collectedAmount: collectedAmount,
          status: status,
          needsQcButton: needsQcButton,
          otpTarget: otpTarget,
          proceedMethod: proceedMethod,
        );
      },
    ),
    GoRoute(
      path: '/delivery/:id/proof',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProofUploadScreen(consignmentId: id);
      },
    ),
    GoRoute(
      path: '/pickups',
      builder: (context, state) => const PickupListScreen(),
    ),
    GoRoute(
      path: '/pickup/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PickupDetailScreen(storeId: int.parse(id));
      },
    ),
    GoRoute(
      path: '/returns',
      builder: (context, state) => const ReturnListScreen(),
    ),
    GoRoute(
      path: '/return/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ReturnDetailScreen(storeId: int.parse(id));
      },
    ),
    GoRoute(
      path: '/earnings',
      builder: (context, state) => const EarningsScreen(),
    ),
    GoRoute(
      path: '/wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        final expectedConsignmentId = extras?['expectedConsignmentId'] as String?;
        final runOrderId = extras?['runOrderId'] as int?;
        final collectedAmount = extras?['collectedAmount'] as double?;
        final unlockMode = extras?['unlockMode'] as bool? ?? false;
        return QRScannerScreen(
          expectedConsignmentId: expectedConsignmentId,
          runOrderId: runOrderId,
          collectedAmount: collectedAmount,
          unlockMode: unlockMode,
        );
      },
    ),
  ],
);
