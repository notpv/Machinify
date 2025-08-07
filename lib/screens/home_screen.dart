import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/machinery_provider.dart';
import '../providers/usage_provider.dart';
import '../providers/movement_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/connectivity_banner.dart';
import 'add_machinery_screen.dart';
import 'log_usage_screen.dart';
import 'movement_screen.dart';
import 'dashboard_screen.dart';
import 'machinery_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeTab(),
    const MachineListScreen(),
    const DashboardScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final machineryProvider = Provider.of<MachineryProvider>(context, listen: false);
    final usageProvider = Provider.of<UsageProvider>(context, listen: false);
    final movementProvider = Provider.of<MovementProvider>(context, listen: false);

    await Future.wait([
      machineryProvider.initialize(),
      usageProvider.initialize(),
      movementProvider.initialize(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: _screens[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Machines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Machinify'),
        actions: [
          Consumer<AppProvider>(
            builder: (context, appProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: appProvider.isOnline ? appProvider.syncData : null,
                  ),
                  if (appProvider.pendingSyncCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${appProvider.pendingSyncCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              final appProvider = Provider.of<AppProvider>(context, listen: false);
              switch (value) {
                case 'language':
                  appProvider.toggleLanguage();
                  break;
                case 'theme':
                  appProvider.toggleTheme();
                  break;
                case 'logout':
                  _showLogoutDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    Icon(Icons.language),
                    SizedBox(width: 8),
                    Text('Switch Language'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.brightness_6),
                    SizedBox(width: 8),
                    Text('Toggle Theme'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final machineryProvider = Provider.of<MachineryProvider>(context, listen: false);
          final usageProvider = Provider.of<UsageProvider>(context, listen: false);
          final movementProvider = Provider.of<MovementProvider>(context, listen: false);

          await Future.wait([
            machineryProvider.refresh(),
            usageProvider.refresh(),
            movementProvider.refresh(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(
                              appProvider.currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back!',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  appProvider.currentUser?.email ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (appProvider.userRole != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: appProvider.isManager 
                                          ? AppTheme.successColor.withOpacity(0.2)
                                          : AppTheme.infoColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      appProvider.isManager ? 'Manager' : 'Field Engineer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: appProvider.isManager 
                                            ? AppTheme.successColor
                                            : AppTheme.infoColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick Stats
              Consumer3<MachineryProvider, UsageProvider, MovementProvider>(
                builder: (context, machineryProvider, usageProvider, movementProvider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Total Machines',
                          value: '${machineryProvider.totalActiveMachines}',
                          icon: Icons.precision_manufacturing,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardCard(
                          title: 'Recent Logs',
                          value: '${usageProvider.recentLogs.length}',
                          icon: Icons.assignment,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              Consumer<MovementProvider>(
                builder: (context, movementProvider, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: DashboardCard(
                          title: 'Pending Movements',
                          value: '${movementProvider.pendingMovements.length}',
                          icon: Icons.local_shipping,
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardCard(
                          title: 'Total Movements',
                          value: '${movementProvider.movements.length}',
                          icon: Icons.swap_horiz,
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  QuickActionButton(
                    title: 'Add Machine',
                    subtitle: 'Register new machinery',
                    icon: Icons.add_circle,
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddMachineryScreen(),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    title: 'Log Usage',
                    subtitle: 'Record fuel & hours',
                    icon: Icons.assignment_add,
                    color: AppTheme.successColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LogUsageScreen(),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    title: 'Track Movement',
                    subtitle: 'Move between sites',
                    icon: Icons.local_shipping,
                    color: AppTheme.warningColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MovementScreen(),
                        ),
                      );
                    },
                  ),
                  QuickActionButton(
                    title: 'Scan QR Code',
                    subtitle: 'Quick machine access',
                    icon: Icons.qr_code_scanner,
                    color: AppTheme.infoColor,
                    onTap: () {
                      _showQrScannerDialog(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 16),

              Consumer2<UsageProvider, MovementProvider>(
                builder: (context, usageProvider, movementProvider, child) {
                  final recentLogs = usageProvider.recentLogs.take(3).toList();
                  final recentMovements = movementProvider.recentMovements.take(3).toList();

                  if (recentLogs.isEmpty && recentMovements.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent activity',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start by adding a machine or logging usage',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Recent Usage Logs
                      ...recentLogs.map((log) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.successColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.assignment,
                              color: AppTheme.successColor,
                            ),
                          ),
                          title: Text('Usage logged for ${log.machineId}'),
                          subtitle: Text(
                            '${log.hoursRun}h run, ${log.dieselConsumed}L fuel by ${log.operatorName}',
                          ),
                          trailing: Text(
                            '${log.date.day}/${log.date.month}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )),

                      // Recent Movements
                      ...recentMovements.map((movement) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.warningColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.local_shipping,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          title: Text('${movement.machineId} moved'),
                          subtitle: Text(
                            'From ${movement.fromSiteName ?? movement.fromSiteId} to ${movement.toSiteName ?? movement.toSiteId}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(movement.status).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              movement.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(movement.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_transit':
        return AppTheme.infoColor;
      case 'pending':
      default:
        return AppTheme.warningColor;
    }
  }

  void _showQrScannerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Scanner'),
        content: const Text(
          'QR code scanning functionality will be implemented here. '
          'This would open the camera to scan machine QR codes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SupabaseService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}