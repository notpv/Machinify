import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/usage_provider.dart';
import '../providers/machinery_provider.dart';
import '../models/machine.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/photo_picker_widget.dart';

class LogUsageScreen extends StatefulWidget {
  final String? machineId;

  const LogUsageScreen({super.key, this.machineId});

  @override
  State<LogUsageScreen> createState() => _LogUsageScreenState();
}

class _LogUsageScreenState extends State<LogUsageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  final _fuelController = TextEditingController();
  final _operatorController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedMachineId;
  DateTime _selectedDate = DateTime.now();
  File? _fuelBillImage;
  bool _isLoading = false;
  Machine? _selectedMachine;

  @override
  void initState() {
    super.initState();
    if (widget.machineId != null) {
      _selectedMachineId = widget.machineId;
      _loadMachineDetails();
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _fuelController.dispose();
    _operatorController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadMachineDetails() async {
    if (_selectedMachineId != null) {
      final machineryProvider = Provider.of<MachineryProvider>(context, listen: false);
      final machine = machineryProvider.getMachineById(_selectedMachineId!);
      setState(() {
        _selectedMachine = machine;
      });
    }
  }

  Future<void> _pickFuelBillImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _fuelBillImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveUsageLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMachineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a machine')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final usageProvider = Provider.of<UsageProvider>(context, listen: false);
      
      final hoursRun = double.parse(_hoursController.text);
      final dieselConsumed = double.parse(_fuelController.text);
      
      // Validate fuel efficiency
      final fuelEfficiency = dieselConsumed / hoursRun;
      if (fuelEfficiency > AppConstants.maxFuelEfficiency) {
        final shouldContinue = await _showFuelEfficiencyWarning(fuelEfficiency);
        if (!shouldContinue) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // TODO: Upload fuel bill image to Supabase storage
      String? fuelBillUrl;
      if (_fuelBillImage != null) {
        fuelBillUrl = 'placeholder_fuel_bill_url';
      }

      final usageLog = await usageProvider.createUsageLog(
        machineId: _selectedMachineId!,
        date: _selectedDate,
        hoursRun: hoursRun,
        dieselConsumed: dieselConsumed,
        operatorName: _operatorController.text.trim(),
        fuelBillUrl: fuelBillUrl,
        remarks: _remarksController.text.trim().isEmpty 
            ? null 
            : _remarksController.text.trim(),
        machine: _selectedMachine,
      );

      if (usageLog != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usage log saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save usage log: ${e.toString()}'),
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

  Future<bool> _showFuelEfficiencyWarning(double efficiency) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warningColor),
            SizedBox(width: 8),
            Text('High Fuel Consumption'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The fuel efficiency is ${efficiency.toStringAsFixed(2)} L/hour, '
              'which is higher than the recommended maximum of ${AppConstants.maxFuelEfficiency} L/hour.',
            ),
            const SizedBox(height: 16),
            const Text(
              'This could indicate:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('• Machine maintenance issues'),
            const Text('• Incorrect fuel measurement'),
            const Text('• Heavy workload conditions'),
            const SizedBox(height: 16),
            const Text('Do you want to continue with this entry?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Review Entry'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Usage'),
        elevation: 0,
      ),
      body: Consumer2<MachineryProvider, UsageProvider>(
        builder: (context, machineryProvider, usageProvider, child) {
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
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMachineId = value;
                        _selectedMachine = machineryProvider.getMachineById(value!);
                      });
                    },
                    prefixIcon: Icons.precision_manufacturing,
                  ),

                  const SizedBox(height: 16),

                  // Date Selection
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
                                  'Usage Date *',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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

                  // Hours Run
                  CustomTextField(
                    controller: _hoursController,
                    label: 'Hours Run *',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.access_time,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter hours run';
                      }
                      final hours = double.tryParse(value);
                      if (hours == null || hours <= 0) {
                        return 'Please enter a valid number of hours';
                      }
                      if (hours > 24) {
                        return 'Hours cannot exceed 24 per day';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Diesel Consumed
                  CustomTextField(
                    controller: _fuelController,
                    label: 'Diesel Consumed (Liters) *',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.local_gas_station,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter diesel consumed';
                      }
                      final fuel = double.tryParse(value);
                      if (fuel == null || fuel <= 0) {
                        return 'Please enter a valid amount of fuel';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Show real-time fuel efficiency calculation
                      _updateFuelEfficiencyDisplay();
                    },
                  ),

                  const SizedBox(height: 8),

                  // Fuel Efficiency Display
                  _buildFuelEfficiencyDisplay(),

                  const SizedBox(height: 16),

                  // Operator Name
                  CustomTextField(
                    controller: _operatorController,
                    label: 'Operator Name *',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter operator name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Fuel Bill Photo
                  PhotoPickerWidget(
                    selectedImage: _fuelBillImage,
                    onImagePicked: _pickFuelBillImage,
                    label: 'Fuel Bill Photo (Optional)',
                    height: 150,
                  ),

                  const SizedBox(height: 16),

                  // Remarks
                  CustomTextField(
                    controller: _remarksController,
                    label: 'Remarks (Optional)',
                    maxLines: 3,
                    prefixIcon: Icons.note,
                    hint: 'Any additional notes about the usage...',
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveUsageLog,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Usage Log'),
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
                              'Usage Logging Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Record usage daily for accurate tracking\n'
                          '• Take a photo of fuel bills for verification\n'
                          '• Normal fuel efficiency: ${AppConstants.minFuelEfficiency}-${AppConstants.maxFuelEfficiency} L/hour\n'
                          '• Include any maintenance or operational notes',
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

  Widget _buildFuelEfficiencyDisplay() {
    final hoursText = _hoursController.text;
    final fuelText = _fuelController.text;
    
    if (hoursText.isEmpty || fuelText.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final hours = double.tryParse(hoursText);
    final fuel = double.tryParse(fuelText);
    
    if (hours == null || fuel == null || hours <= 0) {
      return const SizedBox.shrink();
    }
    
    final efficiency = fuel / hours;
    final isEfficient = efficiency <= AppConstants.maxFuelEfficiency;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEfficient 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEfficient 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEfficient ? Icons.check_circle : Icons.warning,
            color: isEfficient ? AppTheme.successColor : AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuel Efficiency: ${efficiency.toStringAsFixed(2)} L/hour',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isEfficient ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                ),
                Text(
                  isEfficient 
                      ? 'Within normal range'
                      : 'Higher than recommended (${AppConstants.maxFuelEfficiency} L/hour)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEfficient ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateFuelEfficiencyDisplay() {
    setState(() {
      // This will trigger a rebuild and update the fuel efficiency display
    });
  }
}