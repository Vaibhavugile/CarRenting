
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/vehicle_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({
    super.key,
  });

  @override
  State<AddVehicleScreen> createState() =>
      _AddVehicleScreenState();
}

class _AddVehicleScreenState
    extends State<AddVehicleScreen> {
  // ============================================================
  // FORM KEY
  // ============================================================

  final _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _registrationController =
      TextEditingController();

  final _makeController =
      TextEditingController();

  final _modelController =
      TextEditingController();

  final _variantController =
      TextEditingController();

  final _yearController =
      TextEditingController();

  final _colorController =
      TextEditingController();

  final _currentKmController =
      TextEditingController();

  final _dailyRateController =
      TextEditingController();

  final _weeklyRateController =
      TextEditingController();

  final _monthlyRateController =
      TextEditingController();

  final _securityDepositController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  String _vehicleType = 'car';

  String _fuelType = 'petrol';

  String _transmission = 'manual';

  bool _saving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _registrationController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _currentKmController.dispose();
    _dailyRateController.dispose();
    _weeklyRateController.dispose();
    _monthlyRateController.dispose();
    _securityDepositController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<void> _saveVehicle() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final vehicleId =
          await VehicleService.instance
              .createVehicle(
        registrationNumber:
            _registrationController.text,

        make:
            _makeController.text,

        model:
            _modelController.text,

        variant:
            _variantController.text,

        vehicleType:
            _vehicleType,

        fuelType:
            _fuelType,

        transmission:
            _transmission,

        year:
            int.parse(
          _yearController.text.trim(),
        ),

        color:
            _colorController.text,

        currentKm:
            int.parse(
          _currentKmController.text.trim(),
        ),

        dailyRate:
            double.parse(
          _dailyRateController.text
              .trim(),
        ),

        weeklyRate:
            _parseOptionalDouble(
          _weeklyRateController.text,
        ),

        monthlyRate:
            _parseOptionalDouble(
          _monthlyRateController.text,
        ),

        securityDeposit:
            _parseOptionalDouble(
          _securityDepositController.text,
        ),
      );

      if (!mounted) return;

      _showSuccess();

      await Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(
        vehicleId,
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // OPTIONAL DOUBLE
  // ============================================================

  double _parseOptionalDouble(
    String value,
  ) {
    final trimmed =
        value.trim();

    if (trimmed.isEmpty) {
      return 0;
    }

    return double.parse(trimmed);
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess() {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            AppColors.success,

        margin:
            const EdgeInsets.all(
          AppSpacing.lg,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),
        ),

        content: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
            ),

            SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: Text(
                'Vehicle added successfully.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            AppColors.danger,

        margin:
            const EdgeInsets.all(
          AppSpacing.lg,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.lg,
          ),
        ),

        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: Text(
                message,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Add Vehicle',
        ),

        actions: [
          if (!_saving)
            IconButton(
              tooltip: 'Clear',
              onPressed:
                  _clearForm,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: Column(
            children: [
              Expanded(
                child:
                    SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior
                          .onDrag,

                  padding:
                      const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    140,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      _buildHeader(),

                      const SizedBox(
                        height:
                            AppSpacing.xxl,
                      ),

                      _buildVehicleIdentity(),

                      const SizedBox(
                        height:
                            AppSpacing.xl,
                      ),

                      _buildVehicleSpecifications(),

                      const SizedBox(
                        height:
                            AppSpacing.xl,
                      ),

                      _buildVehicleUsage(),

                      const SizedBox(
                        height:
                            AppSpacing.xl,
                      ),

                      _buildPricing(),

                      const SizedBox(
                        height:
                            AppSpacing.xl,
                      ),

                      _buildSecurityDeposit(),

                      const SizedBox(
                        height:
                            AppSpacing.xl,
                      ),

                      _buildAvailabilityNote(),
                    ],
                  ),
                ),
              ),

              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Add a vehicle',
          style:
              Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                fontWeight:
                    FontWeight.w800,
              ),
        ),

        const SizedBox(
          height: AppSpacing.sm,
        ),

        Text(
          'Add your vehicle details, pricing and rental information.',
          style:
              Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color:
                    AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  // ============================================================
  // VEHICLE IDENTITY
  // ============================================================

  Widget _buildVehicleIdentity() {
    return _sectionCard(
      icon:
          Icons.directions_car_rounded,

      title:
          'Vehicle information',

      subtitle:
          'Basic details of your vehicle',

      child: Column(
        children: [
          _buildRegistrationField(),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildTextField(
                  controller:
                      _makeController,
                  label: 'Make',
                  hint:
                      'e.g. Maruti',
                  icon:
                      Icons.business_rounded,
                  textCapitalization:
                      TextCapitalization
                          .words,
                  validator:
                      _requiredValidator(
                    'Make',
                  ),
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              Expanded(
                child:
                    _buildTextField(
                  controller:
                      _modelController,
                  label: 'Model',
                  hint:
                      'e.g. Swift',
                  icon:
                      Icons.directions_car_outlined,
                  textCapitalization:
                      TextCapitalization
                          .words,
                  validator:
                      _requiredValidator(
                    'Model',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          _buildTextField(
            controller:
                _variantController,
            label: 'Variant',
            hint:
                'e.g. VXI / ZXI / LXI',
            icon:
                Icons.auto_awesome_outlined,
            textCapitalization:
                TextCapitalization
                    .words,
            validator:
                _requiredValidator(
              'Variant',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REGISTRATION
  // ============================================================

  Widget _buildRegistrationField() {
    return _buildTextField(
      controller:
          _registrationController,

      label:
          'Registration number',

      hint:
          'e.g. MH12AB1234',

      icon:
          Icons.confirmation_number_outlined,

      textCapitalization:
          TextCapitalization.characters,

      validator: (value) {
        final text =
            value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Registration number is required';
        }

        if (text.length < 4) {
          return 'Enter a valid registration number';
        }

        return null;
      },
    );
  }

  // ============================================================
  // SPECIFICATIONS
  // ============================================================

  Widget _buildVehicleSpecifications() {
    return _sectionCard(
      icon:
          Icons.tune_rounded,

      title:
          'Specifications',

      subtitle:
          'Vehicle type, fuel and transmission',

      child: Column(
        children: [
          _buildDropdownField(
            label:
                'Vehicle type',

            icon:
                Icons.category_outlined,

            value:
                _vehicleType,

            items: const [
              DropdownMenuItem(
                value: 'car',
                child: Text('Car'),
              ),

              DropdownMenuItem(
                value: 'suv',
                child: Text('SUV'),
              ),

              DropdownMenuItem(
                value: 'sedan',
                child: Text('Sedan'),
              ),

              DropdownMenuItem(
                value: 'hatchback',
                child:
                    Text('Hatchback'),
              ),

              DropdownMenuItem(
                value: 'muv',
                child: Text('MUV'),
              ),

              DropdownMenuItem(
                value: 'luxury',
                child:
                    Text('Luxury'),
              ),

              DropdownMenuItem(
                value: 'bike',
                child: Text('Bike'),
              ),

              DropdownMenuItem(
                value: 'scooter',
                child:
                    Text('Scooter'),
              ),

              DropdownMenuItem(
                value: 'other',
                child:
                    Text('Other'),
              ),
            ],

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _vehicleType =
                    value;
              });
            },
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildDropdownField(
                  label:
                      'Fuel type',

                  icon:
                      Icons.local_gas_station_outlined,

                  value:
                      _fuelType,

                  items: const [
                    DropdownMenuItem(
                      value:
                          'petrol',
                      child:
                          Text('Petrol'),
                    ),

                    DropdownMenuItem(
                      value:
                          'diesel',
                      child:
                          Text('Diesel'),
                    ),

                    DropdownMenuItem(
                      value:
                          'cng',
                      child:
                          Text('CNG'),
                    ),

                    DropdownMenuItem(
                      value:
                          'electric',
                      child:
                          Text('Electric'),
                    ),

                    DropdownMenuItem(
                      value:
                          'hybrid',
                      child:
                          Text('Hybrid'),
                    ),
                  ],

                  onChanged:
                      (value) {
                    if (value ==
                        null) {
                      return;
                    }

                    setState(() {
                      _fuelType =
                          value;
                    });
                  },
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              Expanded(
                child:
                    _buildDropdownField(
                  label:
                      'Transmission',

                  icon:
                      Icons.settings_outlined,

                  value:
                      _transmission,

                  items: const [
                    DropdownMenuItem(
                      value:
                          'manual',
                      child:
                          Text('Manual'),
                    ),

                    DropdownMenuItem(
                      value:
                          'automatic',
                      child:
                          Text('Automatic'),
                    ),

                    DropdownMenuItem(
                      value:
                          'amt',
                      child:
                          Text('AMT'),
                    ),
                  ],

                  onChanged:
                      (value) {
                    if (value ==
                        null) {
                      return;
                    }

                    setState(() {
                      _transmission =
                          value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildNumberField(
                  controller:
                      _yearController,

                  label:
                      'Manufacturing year',

                  hint:
                      '2024',

                  icon:
                      Icons.calendar_today_outlined,

                  validator:
                      _yearValidator,
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              Expanded(
                child:
                    _buildTextField(
                  controller:
                      _colorController,

                  label:
                      'Color',

                  hint:
                      'White',

                  icon:
                      Icons.palette_outlined,

                  textCapitalization:
                      TextCapitalization
                          .words,

                  validator:
                      _requiredValidator(
                    'Color',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // USAGE
  // ============================================================

  Widget _buildVehicleUsage() {
    return _sectionCard(
      icon:
          Icons.speed_rounded,

      title:
          'Vehicle usage',

      subtitle:
          'Current odometer reading',

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _buildNumberField(
            controller:
                _currentKmController,

            label:
                'Current KM',

            hint:
                'e.g. 24500',

            icon:
                Icons.speed_outlined,

            suffix:
                'KM',

            validator:
                _kmValidator,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              AppSpacing.md,
            ),

            decoration:
                BoxDecoration(
              color:
                  AppColors.primary
                      .withValues(
                alpha: 0.05,
              ),

              borderRadius:
                  BorderRadius.circular(
                AppRadius.md,
              ),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 19,
                  color:
                      AppColors.primary,
                ),

                const SizedBox(
                  width:
                      AppSpacing.sm,
                ),

                Expanded(
                  child: Text(
                    'Enter the actual odometer reading. This will be used for future rental returns and KM tracking.',
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICING
  // ============================================================

  Widget _buildPricing() {
    return _sectionCard(
      icon:
          Icons.payments_outlined,

      title:
          'Rental pricing',

      subtitle:
          'Set your rental rates',

      child: Column(
        children: [
          _buildMoneyField(
            controller:
                _dailyRateController,

            label:
                'Daily rate',

            hint:
                'e.g. 1800',

            validator:
                _dailyRateValidator,
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildMoneyField(
                  controller:
                      _weeklyRateController,

                  label:
                      'Weekly rate',

                  hint:
                      'Optional',

                  validator:
                      _optionalMoneyValidator,
                ),
              ),

              const SizedBox(
                width:
                    AppSpacing.md,
              ),

              Expanded(
                child:
                    _buildMoneyField(
                  controller:
                      _monthlyRateController,

                  label:
                      'Monthly rate',

                  hint:
                      'Optional',

                  validator:
                      _optionalMoneyValidator,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              AppSpacing.md,
            ),

            decoration:
                BoxDecoration(
              color:
                  AppColors.success
                      .withValues(
                alpha: 0.06,
              ),

              borderRadius:
                  BorderRadius.circular(
                AppRadius.md,
              ),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 19,
                  color:
                      AppColors.success,
                ),

                const SizedBox(
                  width:
                      AppSpacing.sm,
                ),

                Expanded(
                  child: Text(
                    'You can change these rates later from vehicle settings.',
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECURITY DEPOSIT
  // ============================================================

  Widget _buildSecurityDeposit() {
    return _sectionCard(
      icon:
          Icons.security_rounded,

      title:
          'Security deposit',

      subtitle:
          'Amount collected before rental',

      child:
          _buildMoneyField(
        controller:
            _securityDepositController,

        label:
            'Security deposit',

        hint:
            'e.g. 5000',

        validator:
            _optionalMoneyValidator,
      ),
    );
  }

  // ============================================================
  // AVAILABILITY NOTE
  // ============================================================

  Widget _buildAvailabilityNote() {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        border: Border.all(
          color:
              AppColors.border,
        ),

        boxShadow:
            AppShadows.card,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
                BoxDecoration(
              color:
                  AppColors.success
                      .withValues(
                alpha: 0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                AppRadius.md,
              ),
            ),

            child: const Icon(
              Icons.check_circle_outline_rounded,
              color:
                  AppColors.success,
            ),
          ),

          const SizedBox(
            width: AppSpacing.md,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Ready to rent',

                  style:
                      Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w700,
                      ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'New vehicles are automatically added as Available.',
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                            AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),

        border: Border.all(
          color:
              AppColors.border,
        ),

        boxShadow:
            AppShadows.card,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width: 44,
                height: 44,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.md,
                  ),
                ),

                child: Icon(
                  icon,
                  color:
                      AppColors.primary,
                  size: 22,
                ),
              ),

              const SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style:
                          Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                            fontWeight:
                                FontWeight.w800,
                          ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,

                      style:
                          Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color:
                                AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.xl,
          ),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController
        controller,

    required String label,

    required String hint,

    required IconData icon,

    String? Function(String?)?
        validator,

    TextInputType keyboardType =
        TextInputType.text,

    TextCapitalization
        textCapitalization =
        TextCapitalization.none,

    String? suffix,
  }) {
    return TextFormField(
      controller:
          controller,

      validator:
          validator,

      keyboardType:
          keyboardType,

      textCapitalization:
          textCapitalization,

      textInputAction:
          TextInputAction.next,

      style:
          const TextStyle(
        fontWeight:
            FontWeight.w600,
      ),

      decoration:
          _inputDecoration(
        label:
            label,

        hint:
            hint,

        icon:
            icon,

        suffix:
            suffix,
      ),
    );
  }

  // ============================================================
  // NUMBER FIELD
  // ============================================================

  Widget _buildNumberField({
    required TextEditingController
        controller,

    required String label,

    required String hint,

    required IconData icon,

    required String? Function(String?)?
        validator,

    String? suffix,
  }) {
    return TextFormField(
      controller:
          controller,

      validator:
          validator,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: false,
      ),

      textInputAction:
          TextInputAction.next,

      style:
          const TextStyle(
        fontWeight:
            FontWeight.w600,
      ),

      decoration:
          _inputDecoration(
        label:
            label,

        hint:
            hint,

        icon:
            icon,

        suffix:
            suffix,
      ),
    );
  }

  // ============================================================
  // MONEY FIELD
  // ============================================================

  Widget _buildMoneyField({
    required TextEditingController
        controller,

    required String label,

    required String hint,

    required String? Function(String?)?
        validator,
  }) {
    return TextFormField(
      controller:
          controller,

      validator:
          validator,

      keyboardType:
          const TextInputType.numberWithOptions(
        decimal: true,
      ),

      textInputAction:
          TextInputAction.next,

      style:
          const TextStyle(
        fontWeight:
            FontWeight.w700,
      ),

      decoration:
          _inputDecoration(
        label:
            label,

        hint:
            hint,

        icon:
            Icons.currency_rupee_rounded,

        prefix:
            '₹ ',
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<
            DropdownMenuItem<String>>
        items,
    required ValueChanged<String?>
        onChanged,
  }) {
    return DropdownButtonFormField<
        String>(
      initialValue:
          value,

      items:
          items,

      onChanged:
          onChanged,

      style:
          const TextStyle(
        color:
            AppColors.textPrimary,
        fontWeight:
            FontWeight.w600,
      ),

      decoration:
          _inputDecoration(
        label:
            label,

        hint:
            label,

        icon:
            icon,
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,

    required String hint,

    required IconData icon,

    String? prefix,

    String? suffix,
  }) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      prefixText:
          prefix,

      suffixText:
          suffix,

      prefixIcon:
          Icon(
        icon,
        size: 21,
      ),

      filled:
          true,

      fillColor:
          AppColors.surface,

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal:
            AppSpacing.lg,

        vertical:
            AppSpacing.lg,
      ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.border,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.border,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.primary,
          width: 1.5,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.danger,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),

        borderSide:
            const BorderSide(
          color:
              AppColors.danger,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM SAVE BAR
  // ============================================================

  Widget _buildBottomBar() {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        boxShadow:
            AppShadows.floating,
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          width:
              double.infinity,

          height: 56,

          child:
              ElevatedButton(
            onPressed:
                _saving
                    ? null
                    : _saveVehicle,

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primary,

              foregroundColor:
                  Colors.white,

              disabledBackgroundColor:
                  AppColors.primary
                      .withValues(
                alpha: 0.55,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.lg,
                ),
              ),

              elevation:
                  0,
            ),

            child:
                _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2.2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [
                          Icon(
                            Icons
                                .add_circle_outline_rounded,
                            size: 21,
                          ),

                          SizedBox(
                            width:
                                AppSpacing.sm,
                          ),

                          Text(
                            'Add Vehicle',
                            style:
                                TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void _clearForm() {
    if (_saving) {
      return;
    }

    _registrationController.clear();
    _makeController.clear();
    _modelController.clear();
    _variantController.clear();
    _yearController.clear();
    _colorController.clear();
    _currentKmController.clear();
    _dailyRateController.clear();
    _weeklyRateController.clear();
    _monthlyRateController.clear();
    _securityDepositController.clear();

    setState(() {
      _vehicleType =
          'car';

      _fuelType =
          'petrol';

      _transmission =
          'manual';
    });

    _formKey.currentState
        ?.reset();

    FocusScope.of(context)
        .unfocus();
  }

  // ============================================================
  // VALIDATORS
  // ============================================================

  String? Function(String?)
      _requiredValidator(
    String field,
  ) {
    return (value) {
      if (value == null ||
          value.trim().isEmpty) {
        return '$field is required';
      }

      return null;
    };
  }

  String? _yearValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Year is required';
    }

    final year =
        int.tryParse(
      value.trim(),
    );

    if (year == null) {
      return 'Enter a valid year';
    }

    final currentYear =
        DateTime.now().year;

    if (year < 1900 ||
        year > currentYear + 1) {
      return 'Enter a valid year';
    }

    return null;
  }

  String? _kmValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Current KM is required';
    }

    final km =
        int.tryParse(
      value.trim(),
    );

    if (km == null) {
      return 'Enter a valid KM value';
    }

    if (km < 0) {
      return 'KM cannot be negative';
    }

    return null;
  }

  String? _dailyRateValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Daily rate is required';
    }

    final amount =
        double.tryParse(
      value.trim(),
    );

    if (amount == null) {
      return 'Enter a valid amount';
    }

    if (amount <= 0) {
      return 'Daily rate must be greater than ₹0';
    }

    return null;
  }

  String? _optionalMoneyValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    final amount =
        double.tryParse(
      value.trim(),
    );

    if (amount == null) {
      return 'Enter a valid amount';
    }

    if (amount < 0) {
      return 'Amount cannot be negative';
    }

    return null;
  }
}

