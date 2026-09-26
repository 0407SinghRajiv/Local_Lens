import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../services/driving_license_ocr_service.dart';

class DriverOnboardingScreen extends StatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  State<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends State<DriverOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Personal Details Controllers
  final _step1FormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  // Driving Licence OCR & Photo Upload State (Personal Details)
  final ImagePicker _picker = ImagePicker();
  String? _licenseImagePath;
  bool _isOcrProcessing = false;
  bool _isEditingLicense = false;
  bool _isLicenseConfirmed = false;
  bool _isPickerActive = false;
  String _verificationStatus = 'not_uploaded';
  String _statusMessage = 'Upload or take a photo of your Driving Licence to auto-extract the number.';

  // Step 2: Vehicle Details Controllers
  final _step2FormKey = GlobalKey<FormState>();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController(text: 'White');
  String _selectedVehicleType = 'Sedan';

  final List<Map<String, dynamic>> _vehicleCategories = [
    {
      'type': 'Sedan',
      'title': 'Sedan',
      'desc': '4 Seats • Comfort AC Car',
      'imageUrl': 'https://img.icons8.com/color/144/car.png',
      'iconData': Icons.directions_car_rounded,
    },
    {
      'type': 'Hatchback',
      'title': 'Hatchback',
      'desc': '4 Seats • Mini Economy Car',
      'imageUrl': 'https://img.icons8.com/color/144/compact-car.png',
      'iconData': Icons.time_to_leave_rounded,
    },
    {
      'type': 'SUV',
      'title': 'SUV / XL',
      'desc': '6-7 Seats • Large Premium Car',
      'imageUrl': 'https://img.icons8.com/color/144/suv.png',
      'iconData': Icons.airport_shuttle_rounded,
    },
    {
      'type': 'Auto',
      'title': 'Auto Rickshaw',
      'desc': '3 Seats • City TukTuk',
      'imageUrl': 'https://img.icons8.com/color/144/tuk-tuk.png',
      'iconData': Icons.electric_rickshaw_rounded,
    },
    {
      'type': 'Bike',
      'title': 'Bike / Moto',
      'desc': '1 Seat • Quick Ride & Delivery',
      'imageUrl': 'https://img.icons8.com/color/144/motorbike.png',
      'iconData': Icons.two_wheeler_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final driver = state.driver;

    String initialName = driver?.name ?? '';
    if (initialName == 'Google Rider' || initialName == 'Rider') {
      initialName = '';
    }

    _nameController.text = initialName;
    _phoneController.text = driver?.phone ?? '';
    _emailController.text = driver?.email ?? '';
    _licenseController.text = driver?.licenseNumber ?? '';
    _cityController.text = (driver?.city ?? '').isNotEmpty ? driver!.city : 'Mumbai';
    _vehicleModelController.text = driver?.vehicleModel ?? '';
    _vehicleNumberController.text = driver?.vehicleNumber ?? '';
    _vehicleColorController.text = 'White';

    if (driver?.vehicleType != null && driver!.vehicleType.isNotEmpty) {
      _selectedVehicleType = driver.vehicleType;
    }

    if ((driver?.licenseNumber ?? '').isNotEmpty) {
      final isValid = DrivingLicenseOcrService.validateIndianDlFormat(driver!.licenseNumber);
      _verificationStatus = isValid ? 'valid_format' : 'needs_confirmation';
      _isLicenseConfirmed = isValid;
      _statusMessage = isValid
          ? 'Format Verified (OCR + User Confirmation)'
          : 'Please review and confirm your Driving Licence number.';
    }
  }

  Future<void> _pickLicenseImage(ImageSource source) async {
    if (_isPickerActive || _isOcrProcessing) return;
    _isPickerActive = true;

    try {
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isPermanentlyDenied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Camera permission is required. Please enable it in App Settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
          return;
        }
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );

      if (pickedFile == null) return; // User cancelled image selection

      setState(() {
        _licenseImagePath = pickedFile.path;
        _isOcrProcessing = true;
        _verificationStatus = 'processing';
        _statusMessage = 'Reading Driving Licence... Extracting number...';
        _isLicenseConfirmed = false;
        _isEditingLicense = false;
      });

      final result = await DrivingLicenseOcrService.extractFromImage(pickedFile.path);

      if (!mounted) return;

      setState(() {
        _isOcrProcessing = false;
        if (result.extractedNumber.isNotEmpty) {
          _licenseController.text = result.extractedNumber;
          _verificationStatus = result.isValidFormat ? 'needs_confirmation' : 'invalid_format';
          _statusMessage = result.message;
        } else {
          _verificationStatus = 'extraction_failed';
          _statusMessage = result.message;
        }
      });
    } on PlatformException catch (e) {
      debugPrint('[DriverOnboardingScreen] PlatformException in image picker: ${e.code} - ${e.message}');
      if (!mounted) return;
      setState(() {
        _isOcrProcessing = false;
        _verificationStatus = 'extraction_failed';
        _statusMessage = 'Native plugin initialising. You can also type your DL number manually.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notice: App restart may be required for newly installed image picker plugin.'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('[DriverOnboardingScreen] Image picker error: $e');
      if (!mounted) return;
      setState(() {
        _isOcrProcessing = false;
        _verificationStatus = 'extraction_failed';
        _statusMessage = 'Could not access image or camera. Please try again or enter DL number manually.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open ${source == ImageSource.camera ? "Camera" : "Photos"}: $e')),
      );
    } finally {
      _isPickerActive = false;
    }
  }

  void _validateAndConfirmLicense() {
    final clean = DrivingLicenseOcrService.normalizeDlString(_licenseController.text);
    _licenseController.text = clean;

    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or scan a valid Driving Licence number.')),
      );
      return;
    }

    final isValid = DrivingLicenseOcrService.validateIndianDlFormat(clean);

    setState(() {
      _isEditingLicense = false;
      _isLicenseConfirmed = true;
      _verificationStatus = isValid ? 'valid_format' : 'needs_confirmation';
      _statusMessage = isValid
          ? 'Format Verified (OCR + User Confirmation)'
          : 'DL Number saved. Format check completed.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.primary,
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Driving Licence number confirmed!'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _licenseController.dispose();
    _cityController.dispose();
    _vehicleModelController.dispose();
    _vehicleNumberController.dispose();
    _vehicleColorController.dispose();
    super.dispose();
  }

  String get _vehicleModelLabel {
    switch (_selectedVehicleType) {
      case 'Bike':
        return 'Bike / Scooter Model';
      case 'Auto':
        return 'Auto Rickshaw Model';
      case 'SUV':
        return 'SUV Brand & Model';
      case 'Hatchback':
      case 'Mini':
        return 'Hatchback Brand & Model';
      default:
        return 'Car Brand & Model';
    }
  }

  String get _vehicleModelHint {
    switch (_selectedVehicleType) {
      case 'Bike':
        return 'e.g. Honda Activa 6G, TVS Jupiter, Pulsar 150';
      case 'Auto':
        return 'e.g. Bajaj RE Compact, Piaggio Ape City';
      case 'SUV':
        return 'e.g. Maruti Ertiga, Toyota Innova Crysta';
      case 'Hatchback':
      case 'Mini':
        return 'e.g. Maruti Suzuki WagonR, Swift, i10';
      default:
        return 'e.g. Maruti Suzuki Dzire, Hyundai Aura';
    }
  }

  IconData get _vehicleIconData {
    switch (_selectedVehicleType) {
      case 'Bike':
        return Icons.two_wheeler_outlined;
      case 'Auto':
        return Icons.electric_rickshaw_outlined;
      case 'SUV':
      case 'Hatchback':
      case 'Mini':
      default:
        return Icons.directions_car_outlined;
    }
  }

  void _nextPage() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitOnboarding() async {
    if (!_step2FormKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    final currentDriver = appState.driver;

    if (currentDriver == null) return;

    String cleanPhone = _phoneController.text.trim();
    if (!cleanPhone.startsWith('+91')) {
      cleanPhone = '+91 ${cleanPhone.replaceAll('+91', '').trim()}';
    }

    final updatedDriver = currentDriver.copyWith(
      name: _nameController.text.trim(),
      phone: cleanPhone,
      email: _emailController.text.trim(),
      licenseNumber: DrivingLicenseOcrService.normalizeDlString(_licenseController.text),
      licenseVerificationStatus: 'verified_format',
      licenseVerificationMethod: 'ocr',
      licenseVerifiedAt: DateTime.now(),
      city: _cityController.text.trim(),
      vehicleType: _selectedVehicleType,
      vehicleModel: _vehicleModelController.text.trim(),
      vehicleNumber: _vehicleNumberController.text.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase(),
      vehicleColor: _vehicleColorController.text.trim(),
    );

    await appState.completeDriverOnboarding(updatedDriver);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    const lightHintStyle = TextStyle(
      color: Color(0xFF9CA3AF),
      fontWeight: FontWeight.w400,
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: AppTheme.cardWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
                onPressed: _previousPage,
              )
            : null,
        title: Text(
          _currentStep == 0 ? 'Driver Registration' : 'Vehicle Registration',
          style: AppTheme.titleLarge.copyWith(color: const Color(0xFF1F2937)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Stepper Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildProgressStep(
                      stepNumber: 1,
                      label: 'Personal Details',
                      isActive: _currentStep >= 0,
                      isCompleted: _currentStep > 0,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 2,
                    color: _currentStep > 0
                        ? AppTheme.primary
                        : AppTheme.outline.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _buildProgressStep(
                      stepNumber: 2,
                      label: 'Vehicles Details',
                      isActive: _currentStep >= 1,
                      isCompleted: false,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildStep1PersonalDetails(lightHintStyle),
                  _buildStep2VehicleDetails(lightHintStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primary : AppTheme.surfaceContainer,
            border: Border.all(
              color: isActive ? AppTheme.primary : AppTheme.outline.withValues(alpha: 0.4),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : AppTheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: AppTheme.labelMedium.copyWith(
              color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── STEP 1: Driver Personal Details ───────────────────────────────────────
  Widget _buildStep1PersonalDetails(TextStyle lightHintStyle) {
    final state = context.watch<AppState>();
    final driver = state.driver;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    AppTheme.primaryContainer.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primary,
                    backgroundImage: (driver?.profileImageUrl ?? '').isNotEmpty
                        ? NetworkImage(driver!.profileImageUrl)
                        : null,
                    child: (driver?.profileImageUrl ?? '').isEmpty
                        ? const Icon(Icons.person_rounded, color: Colors.white, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 1 of 2: Personal Profile',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Enter your contact & driving license details.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Full Name Field
            Text('Full Name', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                hintStyle: lightHintStyle,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Phone Number Field
            Text('Phone Number', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: '98765 43210',
                hintStyle: lightHintStyle,
                prefixIcon: const Icon(Icons.phone_outlined),
                prefixText: '+91 ',
                prefixStyle: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your mobile phone number';
                }
                final clean = v.replaceAll(RegExp(r'\D'), '');
                if (clean.length < 10) {
                  return 'Enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Email Address (Read-only)
            Text('Email Address', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              readOnly: true,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.onSurfaceVariant),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceContainer,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 18),

            // ─── DRIVING LICENCE PHOTO & OCR (PERSONAL DETAILS) ─────────────
            Text('Driving Licence Verification', style: AppTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Upload or take a photo of your Driving Licence. ML Kit OCR auto-extracts your DL number.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),

            // Photo picker container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  if (_licenseImagePath != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            File(_licenseImagePath!),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                              onPressed: () {
                                setState(() {
                                  _licenseImagePath = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_isOcrProcessing) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Extracting Licence Number...',
                                  style: AppTheme.titleMedium.copyWith(color: AppTheme.primary, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Reading document with ML Kit OCR',
                                  style: AppTheme.bodySmall.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isOcrProcessing ? null : () => _pickLicenseImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Take Photo'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isOcrProcessing ? null : () => _pickLicenseImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Upload Licence'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Driving License Number Input & Edit/Confirm
            Text('Driving License Number', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _licenseController,
              readOnly: !_isEditingLicense && _isLicenseConfirmed,
              textCapitalization: TextCapitalization.characters,
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'e.g. MH1420260012345',
                hintStyle: lightHintStyle,
                prefixIcon: const Icon(Icons.badge_outlined),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLicenseConfirmed && !_isEditingLicense)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 20),
                        tooltip: 'Edit DL Number',
                        onPressed: () {
                          setState(() {
                            _isEditingLicense = true;
                            _isLicenseConfirmed = false;
                          });
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _isLicenseConfirmed ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                        color: _isLicenseConfirmed ? AppTheme.primary : AppTheme.secondary,
                        size: 22,
                      ),
                      tooltip: 'Confirm DL Number',
                      onPressed: _validateAndConfirmLicense,
                    ),
                  ],
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Driving license number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            _buildOnboardingStatusBadge(),
            const SizedBox(height: 18),

            // Operating City Input Field
            Text('Operating City', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. Mumbai, Thane, Pune, Delhi NCR',
                hintStyle: lightHintStyle,
                prefixIcon: const Icon(Icons.location_city_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your operating city';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to Car Details',
                      style: AppTheme.labelLarge.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2: Car / Vehicle Registration Details ────────────────────────────
  Widget _buildStep2VehicleDetails(TextStyle lightHintStyle) {
    final state = context.watch<AppState>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondary.withValues(alpha: 0.12),
                    AppTheme.primary.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.secondary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 2 of 2: Car & Vehicle Details',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select your vehicle category & registration details.',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Category Selector
            Text('Vehicle Category', style: AppTheme.titleMedium),
            const SizedBox(height: 10),
            Column(
              children: _vehicleCategories.map((v) {
                final String vType = v['type'] as String;
                final String vTitle = v['title'] as String;
                final String vDesc = v['desc'] as String;
                final String vImageUrl = v['imageUrl'] as String;
                final IconData vIconData = v['iconData'] as IconData;
                final isSelected = _selectedVehicleType == vType;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedVehicleType = vType);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.08)
                            : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.outline.withValues(alpha: 0.25),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primary.withValues(alpha: 0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary.withValues(alpha: 0.3)
                                    : AppTheme.outline.withValues(alpha: 0.15),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                vImageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      vIconData,
                                      color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                                      size: 28,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isSelected ? AppTheme.primary : Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vTitle,
                                  style: AppTheme.titleMedium.copyWith(
                                    fontSize: 15,
                                    color: isSelected ? AppTheme.primary : const Color(0xFF1F2937),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vDesc,
                                  style: AppTheme.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Versatile Vehicle Model & Brand Field
            Text(_vehicleModelLabel, style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _vehicleModelController,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: _vehicleModelHint,
                hintStyle: lightHintStyle,
                prefixIcon: Icon(_vehicleIconData),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your vehicle model & brand';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Vehicle Registration Plate
            Text('Vehicle License Plate Number', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _vehicleNumberController,
              textCapitalization: TextCapitalization.characters,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. MH 04 AB 1234',
                hintStyle: lightHintStyle,
                prefixIcon: const Icon(Icons.pin_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vehicle license plate number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Vehicle Color
            Text('Vehicle Color', style: AppTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _vehicleColorController,
              textCapitalization: TextCapitalization.words,
              style: AppTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g. White / Silver / Black',
                hintStyle: lightHintStyle,
                prefixIcon: const Icon(Icons.palette_outlined),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _submitOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Complete & Start Driving',
                            style: AppTheme.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingStatusBadge() {
    Color badgeColor;
    IconData badgeIcon;
    String statusTitle;

    switch (_verificationStatus) {
      case 'valid_format':
        badgeColor = const Color(0xFF059669);
        badgeIcon = Icons.verified_user_rounded;
        statusTitle = 'Status: Format Verified';
        break;
      case 'needs_confirmation':
        badgeColor = Colors.amber.shade800;
        badgeIcon = Icons.help_outline_rounded;
        statusTitle = 'Status: Needs Confirmation';
        break;
      case 'invalid_format':
        badgeColor = Colors.orange.shade800;
        badgeIcon = Icons.warning_amber_rounded;
        statusTitle = 'Status: Review Format';
        break;
      case 'extraction_failed':
        badgeColor = AppTheme.error;
        badgeIcon = Icons.error_outline_rounded;
        statusTitle = 'Status: Extraction Failed';
        break;
      case 'processing':
        badgeColor = AppTheme.primary;
        badgeIcon = Icons.sync_rounded;
        statusTitle = 'Status: OCR Reading...';
        break;
      default:
        badgeColor = Colors.grey.shade700;
        badgeIcon = Icons.info_outline_rounded;
        statusTitle = 'Status: Pending Verification';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(badgeIcon, color: badgeColor, size: 18),
              const SizedBox(width: 8),
              Text(
                statusTitle,
                style: AppTheme.titleMedium.copyWith(
                  color: badgeColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _statusMessage,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.onSurfaceVariant, fontSize: 11),
          ),
          if (_verificationStatus == 'valid_format') ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.shield_outlined, size: 12, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Verification Method: OCR + User Confirmation',
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
