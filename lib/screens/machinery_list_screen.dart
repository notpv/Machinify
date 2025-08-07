import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/machinery_provider.dart';
import '../models/machine.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_text_field.dart';
import 'add_machinery_screen.dart';

class MachineListScreen extends StatefulWidget {
  const MachineListScreen({super.key});

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedSite;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Machines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddMachineryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<MachineryProvider>(
        builder: (context, machineryProvider, child) {
          if (machineryProvider.isLoading && machineryProvider.machines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter machines based on search and filters
          var filteredMachines = machineryProvider.machines;
          
          if (_searchQuery.isNotEmpty) {
            filteredMachines = machineryProvider.searchMachines(_searchQuery);
          }
          
          if (_selectedType != null) {
            filteredMachines = filteredMachines.where((m) => m.type == _selectedType).toList();
          }
          
          if (_selectedSite != null) {
            filteredMachines = filteredMachines.where((m) => m.assignedSiteId == _selectedSite).toList();
          }

          return Column(
            children: [
              // Search and Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  children: [
                    // Search Bar
                    CustomTextField(
                      controller: _searchController,
                      label: 'Search machines...',
                      prefixIcon: Icons.search,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Filter Row
                    Row(
                      children: [
                        // Type Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Type',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Types')),
                              ...machineryProvider.machineStatsByType.keys.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text('$type (${machineryProvider.machineStatsByType[type]})'),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedType = value;
                              });
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Site Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSite,
                            decoration: const InputDecoration(
                              labelText: 'Site',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Sites')),
                              ...machineryProvider.sites.map((site) {
                                return DropdownMenuItem(
                                  value: site.siteId,
                                  child: Text(site.siteName),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSite = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Results Count
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey[100],
                child: Text(
                  '${filteredMachines.length} machine${filteredMachines.length != 1 ? 's' : ''} found',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              
              // Machine List
              Expanded(
                child: filteredMachines.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: machineryProvider.refresh,
                        child: ListView.builder(
                          itemCount: filteredMachines.length,
                          itemBuilder: (context, index) {
                            final machine = filteredMachines[index];
                            return _buildMachineCard(machine);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No machines found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedType = null;
                  _selectedSite = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineCard(Machine machine) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMachineTypeColor(machine.type).withOpacity(0.2),
          child: Icon(
            _getMachineIcon(machine.type),
            color: _getMachineTypeColor(machine.type),
          ),
        ),
        title: Text(
          machine.machineId,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${machine.brand} ${machine.model}'),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    machine.siteName ?? 'Unknown Site',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getMachineTypeColor(machine.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                machine.type,
                style: TextStyle(
                  fontSize: 10,
                  color: _getMachineTypeColor(machine.type),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${machine.purchaseDate.day}/${machine.purchaseDate.month}/${machine.purchaseDate.year}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        onTap: () {
          _showMachineDetails(machine);
        },
      ),
    );
  }

  void _showMachineDetails(Machine machine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _getMachineTypeColor(machine.type).withOpacity(0.2),
                      child: Icon(
                        _getMachineIcon(machine.type),
                        color: _getMachineTypeColor(machine.type),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            machine.machineId,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${machine.brand} ${machine.model}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Details
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow('Type', machine.type),
                      _buildDetailRow('Brand', machine.brand),
                      _buildDetailRow('Model', machine.model),
                      _buildDetailRow('Purchase Date', 
                        '${machine.purchaseDate.day}/${machine.purchaseDate.month}/${machine.purchaseDate.year}'),
                      _buildDetailRow('Assigned Site', machine.siteName ?? 'Unknown'),
                      _buildDetailRow('QR Code', machine.qrCode),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Show QR code
                              },
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Show QR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // TODO: Navigate to usage logging
                              },
                              icon: const Icon(Icons.assignment_add),
                              label: const Text('Log Usage'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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