import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../auth/domain/auth_provider.dart';
import '../domain/dashboard_provider.dart';
import '../domain/attendance_provider.dart';
import '../../delivery/presentation/delivery_list_screen.dart';
import '../../pickup/presentation/pickup_list_screen.dart';
import '../../return/presentation/return_list_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../profile/domain/user_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _tabs = [
    const _DashboardTab(),
    const DeliveryListScreen(),
    const PickupListScreen(),
    const ReturnListScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Determine if the current tab should have an AppBar
    // Delivery (index 1) handles its own full-screen UI.
    final bool showAppBar = _currentTabIndex != 1;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const _NavigationDrawer(),
      appBar: showAppBar
          ? AppBar(
              title: Text(
                _currentTabIndex == 0
                    ? 'Summary'
                    : _currentTabIndex == 2
                        ? AppStrings.pickupTab
                        : _currentTabIndex == 3
                            ? AppStrings.returnTab
                            : AppStrings.settings,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.black),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu, color: AppColors.black),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              elevation: 0.5,
              backgroundColor: AppColors.white,
              centerTitle: true,
            )
          : null,
      body: _tabs[_currentTabIndex],
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceProvider);
    final shiftStarted = attendance.isShiftActive;
    final isLoading = attendance.isLoading;
    final dashState = ref.watch(dashboardProvider);

    return Container(
      color: const Color(0xFFF2F4F7),
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).loadStats();
          await ref.read(attendanceProvider.notifier).loadAttendance();
        },
        child: dashState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading stats: $err')),
          data: (stats) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Shift Banner Card
                  Card(
                    elevation: 0.5,
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFFE2E4E8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            shiftStarted ? AppStrings.shiftEndedPrompt : AppStrings.shiftStartedMsg,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greyDarkest,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: shiftStarted
                                    ? const Color(0xFFFF6B6B)
                                    : AppColors.green,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                elevation: 0,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      String? error;
                                      if (shiftStarted) {
                                        error = await ref.read(attendanceProvider.notifier).endShift();
                                      } else {
                                        error = await ref.read(attendanceProvider.notifier).startShift();
                                      }
                                      if (error != null && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(error),
                                            backgroundColor: AppColors.statusBad,
                                            duration: const Duration(seconds: 4),
                                          ),
                                        );
                                      } else if (error == null && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(shiftStarted ? 'Shift ended successfully!' : 'Shift started successfully!'),
                                            backgroundColor: AppColors.statusGood,
                                          ),
                                        );
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      shiftStarted ? 'END SHIFT' : 'START SHIFT',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
      
                  // Date Selection Card
                  Card(
                    elevation: 0.5,
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFFE2E4E8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.greyDarker),
                          SizedBox(width: 12),
                          Text(
                            'Date',
                            style: TextStyle(fontSize: 14, color: AppColors.greyDarker),
                          ),
                          Spacer(),
                          Text(
                            DateFormat('dd MMM yyyy').format(DateTime.now()),
                            style: TextStyle(fontSize: 15, color: AppColors.greyDarkest, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.greyDarker),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
      
                  // Cash Collection Card
                  Card(
                    elevation: 0.5,
                    color: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFFE2E4E8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Column(
                          children: [
                            const Text(
                              'CASH COLLECTION',
                              style: TextStyle(
                                color: AppColors.greenDarker,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${stats.cashCollected.toInt()} / ${stats.cashCollectableTotal.toInt()}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                color: AppColors.greyDarkest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
      
                  // Grid Layout (2-columns)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildGridCardWithDetails(
                        'DELIVERY TARGET',
                        '${stats.deliveryCompleted} / ${stats.deliveryTotal}',
                        context,
                      ),
                      _buildGridCard('PENDING', '${stats.pending}'),
                      _buildGridCard('PRICE CHANGE', '${stats.priceChange}'),
                      _buildGridCard('RETURN', '${stats.returned}'),
                      _buildGridCard('PARTIAL DELIVERY', '${stats.partialDelivery}'),
                      _buildGridCard('ON HOLD', '${stats.onHold}'),
                      _buildGridCard('DELIVERED', '${stats.delivered}'),
                      _buildGridCard('DRTO', '${stats.drto}'),
                      _buildGridCard('EXCHANGE', '${stats.exchange}'),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridCard(String label, String value) {
    return Card(
      elevation: 0.5,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFE2E4E8)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFC06A14), // Dark orange/brown color from screenshot
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.greyDarkest,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCardWithDetails(String label, String value, BuildContext context) {
    return Card(
      elevation: 0.5,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFE2E4E8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC06A14),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.greyDarkest,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              // Programmatically click target - trigger tab transition in parent
              // We'll just push the deliveries route for the demo
              context.push('/deliveries');
            },
            child: const Text(
              'SEE DETAILS',
              style: TextStyle(
                color: Color(0xFFDD3444),
                fontWeight: FontWeight.bold,
                fontSize: 11,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationDrawer extends ConsumerWidget {
  const _NavigationDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);

    return Drawer(
      child: Column(
        children: [
          // Profile section at top
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            color: const Color(0xFFF8F9FA),
            child: Column(
              children: [
                userAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (user) {
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: user.imageUrl != null 
                              ? NetworkImage(user.imageUrl!) 
                              : const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=256'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.greyDarkest),
                              ),
                              Text(
                                user.phone,
                                style: const TextStyle(color: AppColors.greyDarker, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              // Rating button/chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E4E8)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${user.rating}★ ',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.greyDarkest),
                                    ),
                                    Text(
                                      '${user.reviewCount} Reviews >',
                                      style: const TextStyle(fontSize: 11, color: AppColors.greyDarker),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 16),
                // Switch profile button
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDD3444)),
                      foregroundColor: const Color(0xFFDD3444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Switched profile mode')),
                      );
                    },
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text(
                      'Switch to Pickup',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E4E8)),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.assignment_outlined, 'Summary', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.payments_outlined, 'Earnings', () {
                  Navigator.pop(context);
                  context.push('/earnings');
                }),
                _buildDrawerItem(Icons.notifications_none, 'Notifications', () {
                  Navigator.pop(context);
                  context.push('/notifications');
                }),
                _buildDrawerItem(Icons.star_outline, 'Review', () {
                  Navigator.pop(context);
                  context.push('/profile');
                }),
                _buildDrawerItem(Icons.settings_outlined, 'Settings', () {
                  Navigator.pop(context);
                  context.push('/settings');
                }),
                _buildDrawerItem(Icons.translate, 'Switch Language: BN', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language switched to Bangla')),
                  );
                }),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFE2E4E8)),
          // Logout & Support
          _buildDrawerItem(
            Icons.power_settings_new,
            'Logout',
            () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            iconColor: AppColors.black,
          ),
          const Divider(height: 1, color: Color(0xFFE2E4E8)),
          
          // Emergency Support Footer
          ListTile(
            leading: const Icon(Icons.phone_in_talk, color: Color(0xFFDD3444)),
            title: const Text(
              'Emergency Contact',
              style: TextStyle(color: Color(0xFFDD3444), fontWeight: FontWeight.bold),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling Support Hotlines...')),
              );
            },
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Version 7.1.2',
              style: TextStyle(color: AppColors.greyDark, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.greyDarkest),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.greyDarkest, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
