import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/movement_provider.dart';
import '../providers/machinery_provider.dart';
import '../models/machine.dart';
import '../models/site.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';

class MovementScreen extends StatefulWidget {
  final String? machineId;

  const MovementScreen({super.key, this.machineId});

  @override
  State<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends State<MovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transporterController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedMachineId;
  String? _selectedFromSiteId;
  String? _selectedToSiteId;
  DateTime _movementDate = DateTime.now();
  bool _isLoading = false;
  Position? _currentPosition;
  Machine? _selectedMachine;
  Site? _fromSite;
  Site? _toSite;

  @override
  void initState() {
    super.initState();
    if (widget.machineId != null) {
      _selectedMachineId = widget.machineId;
      _loadMachineDetails();
    }
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _transporterController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadMachineDetails() async {
    if (_selectedMachineId != null) {
      final machineryProvider = Provider.of<MachineryProvider>(context, listen: false);
      final machine = machineryProvider.getMachineById(_selectedMachineId!);
      if (machine != null) {
        setState(() {
          _selectedMachine = machine;
          _selectedFromSiteId = machine.assignedSiteId;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Handle location error silently
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _movementDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _movementDate = picked;
      });
    }
  }

  Future<void> _saveMovement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMachineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a machine')),
      );
      return;
    }
    if (_selectedFromSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select from site')),
      );
      return;
    }
    if (_selectedToSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select to site')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final movementProvider = Provider.of<MovementProvider>(context, listen: false);
      
      final movement = await movementProvider.createMovement(
        machineId: _selectedMachineId!,
        fromSiteId: _selectedFromSiteId!,
        toSiteId: _selectedToSiteId!,
        movementDate: _movementDate,
        transporterName: _transporterController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty 
            ? null 
            : _remarksController.text.trim(),
        fromLatitude: _currentPosition?.latitude,
        fromLongitude: _currentPosition?.longitude,
        machine: _selectedMachine,
        fromSite: _fromSite,
        toSite: _toSite,
      );

      if (movement != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Movement recorded successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record movement: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Movement'),
        elevation: 0,
      ),
      body: Consumer2<MachineryProvider, MovementProvider>(
        builder: (context, machineryProvider, movementProvider, child) {
          if (machineryProvider.isLoading && machineryProvider.machines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Machine Selection
                  CustomDropdown<String>(
                    label: 'Select Machine *',
                    value: _selectedMachineId,
                    items: machineryProvider.machines.map((machine) {
                      return DropdownMenuItem(
                        value: machine.machineId,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(machine.machineId),
                            Text(
                              '${machine.type} - ${machine.brand} ${machine.model}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'Currently at: ${machine.siteName ?? 'Unknown'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMachineId = value;
                        final machine = machineryProvider.getMachineById(value!);
                        _selectedMachine = machine;
                        _selectedFromSiteId = machine?.assignedSiteId;
                        _fromSite = machineryProvider.getSiteById(_selectedFromSiteId ?? '');
                      });
                    },
                    prefixIcon: Icons.precision_manufacturing,
                  ),

                  const SizedBox(height: 16),

                  // From Site
                  CustomDropdown<String>(
                    label: 'From Site *',
                    value: _selectedFromSiteId,
                    items: machineryProvider.sites.map((site) {
                      return DropdownMenuItem(
                        value: site.siteId,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(site.siteName),
                            if (site.address != null)
                              Text(
                                site.address!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFromSiteId = value;
                        _fromSite = machineryProvider.getSiteById(value ?? '');
                      });
                    },
                    prefixIcon: Icons.location_on,
                    enabled: _selectedMachine == null, // Auto-filled when machine is selected
                  ),

                  const SizedBox(height: 16),

                  // To Site
                  CustomDropdown<String>(
                    label: 'To Site *',
                    value: _selectedToSiteId,
                    items: machineryProvider.sites
                        .where((site) => site.siteId != _selectedFromSiteId)
                        .map((site) {
                      return DropdownMenuItem(
                        value: site.siteId,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(site.siteName),
                            if (site.address != null)
                              Text(
                                site.address!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            // Show distance if available
                            if (_fromSite != null && _fromSite!.distanceTo(site) != null)
                              Text(
                                'Distance: ${_fromSite!.distanceTo(site)!.toStringAsFixed(1)} km',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.infoColor,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedToSiteId = value;
                        _toSite = machineryProvider.getSiteById(value ?? '');
                      });
                    },
                    prefixIcon: Icons.location_on,
                  ),

                  const SizedBox(height: 16),

                  // Movement Date
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Movement Date *',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_movementDate.day}/${_movementDate.month}/${_movementDate.year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transporter Name
                  CustomTextField(
                    controller: _transporterController,
                    label: 'Transporter Name *',
                    prefixIcon: Icons.local_shipping,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter transporter name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Remarks
                  CustomTextField(
                    controller: _remarksController,
                    label: 'Remarks (Optional)',
                    maxLines: 3,
                    prefixIcon: Icons.note,
                    hint: 'Any additional notes about the movement...',
                  ),

                  const SizedBox(height: 16),

                  // Location Info
                  if (_currentPosition != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.successColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Location Captured',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                                Text(
                                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                                  'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMovement,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Record Movement'),
                  ),

                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.infoColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.infoColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Movement Tracking',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Machine assignment will be updated automatically\n'
                          '• GPS location is captured for verification\n'
                          '• Movement status starts as "Pending"\n'
                          '• Notify the transporter about pickup details',
                          style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}