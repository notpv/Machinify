import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/machinery_provider.dart';
import '../utils/constants.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/photo_picker_widget.dart';
import '../services/qr_service.dart';

class AddMachineryScreen extends StatefulWidget {
  const AddMachineryScreen({super.key});

  @override
  State<AddMachineryScreen> createState() => _AddMachineryScreenState();
}

class _AddMachineryScreenState extends State<AddMachineryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _brandController = TextEditingController();
  final _qrService = QrService();

  String? _selectedType;
  String? _selectedSiteId;
  DateTime _purchaseDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _modelController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _saveMachine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select machine type')),
      );
      return;
    }
    if (_selectedSiteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select assigned site')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final machineryProvider = Provider.of<MachineryProvider>(context, listen: false);
      
      // TODO: Upload image to Supabase storage
      String? photoUrl;
      if (_selectedImage != null) {
        // For now, we'll just use a placeholder URL
        photoUrl = 'placeholder_url';
      }

      final machine = await machineryProvider.createMachine(
        type: _selectedType!,
        model: _modelController.text.trim(),
        brand: _brandController.text.trim(),
        purchaseDate: _purchaseDate,
        assignedSiteId: _selectedSiteId!,
        photoUrl: photoUrl,
      );

      if (machine != null && mounted) {
        // Show success message with QR code
        _showSuccessDialog(machine.machineId, machine.qrCode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add machine: ${e.toString()}'),
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

  void _showSuccessDialog(String machineId, String qrCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            SizedBox(width: 8),
            Text('Machine Added Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Machine ID: $machineId'),
            const SizedBox(height: 16),
            const Text('QR Code generated:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _qrService.generateQrCodeWidget(
                qrCode,
                size: 150,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Print this QR code and attach it to the machine',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Machine'),
        elevation: 0,
      ),
      body: Consumer<MachineryProvider>(
        builder: (context, machineryProvider, child) {
          if (machineryProvider.isLoading && machineryProvider.sites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Machine Photo
                  PhotoPickerWidget(
                    selectedImage: _selectedImage,
                    onImagePicked: _pickImage,
                    label: 'Machine Photo',
                  ),

                  const SizedBox(height: 24),

                  // Machine Type
                  CustomDropdown<String>(
                    label: 'Machine Type *',
                    value: _selectedType,
                    items: AppConstants.machineTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getMachineIcon(type), size: 20),
                            const SizedBox(width: 8),
                            Text(type),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                    prefixIcon: Icons.precision_manufacturing,
                  ),

                  const SizedBox(height: 16),

                  // Model
                  CustomTextField(
                    controller: _modelController,
                    label: 'Model *',
                    prefixIcon: Icons.model_training,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter machine model';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Brand
                  CustomTextField(
                    controller: _brandController,
                    label: 'Brand *',
                    prefixIcon: Icons.business,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter machine brand';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Purchase Date
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
                                  'Purchase Date *',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
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

                  // Assigned Site
                  CustomDropdown<String>(
                    label: 'Assigned Site *',
                    value: _selectedSiteId,
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
                        _selectedSiteId = value;
                      });
                    },
                    prefixIcon: Icons.location_on,
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMachine,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Add Machine'),
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
                              'What happens next?',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• A unique Machine ID will be generated\n'
                          '• A QR code will be created for easy scanning\n'
                          '• The machine will be assigned to the selected site\n'
                          '• You can start logging usage immediately',
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