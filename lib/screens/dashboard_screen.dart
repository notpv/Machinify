import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/machinery_provider.dart';
import '../providers/usage_provider.dart';
import '../providers/movement_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/dashboard_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAnalyticsTab(),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer4<AppProvider, MachineryProvider, UsageProvider, MovementProvider>(
      builder: (context, appProvider, machineryProvider, usageProvider, movementProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              machineryProvider.refresh(),
              usageProvider.refresh(),
              movementProvider.refresh(),
            ]);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key Metrics
                Text(
                  'Key Metrics',
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
                    DashboardCard(
                      title: 'Total Machines',
                      value: '${machineryProvider.totalActiveMachines}',
                      icon: Icons.precision_manufacturing,
                      color: AppTheme.primaryColor,
                    ),
                    DashboardCard(
                      title: 'Usage Logs (30d)',
                      value: '${usageProvider.recentLogs.length}',
                      icon: Icons.assignment,
                      color: AppTheme.successColor,
                    ),
                    DashboardCard(
                      title: 'Pending Movements',
                      value: '${movementProvider.pendingMovements.length}',
                      icon: Icons.local_shipping,
                      color: AppTheme.warningColor,
                    ),
                    DashboardCard(
                      title: 'Total Movements',
                      value: '${movementProvider.movements.length}',
                      icon: Icons.swap_horiz,
                      color: AppTheme.infoColor,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Machine Types Breakdown
                Text(
                  'Machine Types',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: machineryProvider.machineStatsByType.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _getMachineIcon(entry.key),
                                color: _getMachineTypeColor(entry.key),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getMachineTypeColor(entry.key).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.value}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getMachineTypeColor(entry.key),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Fuel Efficiency Overview
                Text(
                  'Fuel Efficiency',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildFuelMetric(
                              'Average',
                              '${usageProvider.fuelEfficiencyStats['average']?.toStringAsFixed(2) ?? '0.00'} L/h',
                              AppTheme.infoColor,
                            ),
                            _buildFuelMetric(
                              'Total Fuel',
                              '${usageProvider.fuelEfficiencyStats['total_fuel']?.toStringAsFixed(0) ?? '0'} L',
                              AppTheme.warningColor,
                            ),
                            _buildFuelMetric(
                              'Total Hours',
                              '${usageProvider.fuelEfficiencyStats['total_hours']?.toStringAsFixed(0) ?? '0'} h',
                              AppTheme.successColor,
                            ),
                          ],
                        ),
                        
                        if (usageProvider.inefficientLogs.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: AppTheme.warningColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${usageProvider.inefficientLogs.length} logs with high fuel consumption',
                                    style: const TextStyle(
                                      color: AppTheme.warningColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Recent Activity Summary
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                
                if (usageProvider.recentLogs.isEmpty && movementProvider.recentMovements.isEmpty)
                  Card(
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
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Recent Usage Logs
                      ...usageProvider.recentLogs.take(3).map((log) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.successColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.assignment,
                              color: AppTheme.successColor,
                            ),
                          ),
                          title: Text('Usage: ${log.machineId}'),
                          subtitle: Text(
                            '${log.hoursRun}h, ${log.dieselConsumed}L by ${log.operatorName}',
                          ),
                          trailing: Text(
                            '${log.date.day}/${log.date.month}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )),

                      // Recent Movements
                      ...movementProvider.recentMovements.take(3).map((movement) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.warningColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.local_shipping,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          title: Text('Movement: ${movement.machineId}'),
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer2<UsageProvider, MovementProvider>(
      builder: (context, usageProvider, movementProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              // Operator Performance
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operator Performance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      ...usageProvider.getOperatorPerformance().entries.take(5).map((entry) {
                        final stats = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${stats['avg_efficiency']?.toStringAsFixed(2)} L/h',
                                    style: TextStyle(
                                      color: (stats['avg_efficiency'] ?? 0) <= 10 
                                          ? AppTheme.successColor 
                                          : AppTheme.warningColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${stats['total_hours']?.toStringAsFixed(0)}h total, ${stats['log_count']?.toStringAsFixed(0)} logs',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Movement Statistics
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Movement Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: movementProvider.movementStats.entries.map((entry) {
                          return Column(
                            children: [
                              Text(
                                '${entry.value}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: _getStatusColor(entry.key),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                entry.key.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(entry.key),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assessment,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Reports Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Detailed reports and exports will be available in the next update.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_transit':
        return AppTheme.infoColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'total':
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  Color _getMachineTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'excavator':
        return AppTheme.primaryColor;
      case 'roller':
        return AppTheme.successColor;
      case 'bulldozer':
        return AppTheme.warningColor;
      case 'crane':
        return AppTheme.errorColor;
      case 'grader':
        return AppTheme.infoColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getMachineIcon(String type) {
    switch (type.toLowerCase()) {
      case 'excavator':
        return Icons.construction;
      case 'roller':
        return Icons.agriculture;
      case 'bulldozer':
        return Icons.terrain;
      case 'crane':
        return Icons.crane;
      case 'grader':
        return Icons.linear_scale;
      default:
        return Icons.precision_manufacturing;
    }
  }
}