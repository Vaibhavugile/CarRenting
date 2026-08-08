
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/business_service.dart';
import '../dashboard/dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState
    extends State<BusinessSetupScreen> {
  final _formKey =
      GlobalKey<FormState>();

  // ============================================================
  // BUSINESS CONTROLLERS
  // ============================================================

  final _businessNameController =
      TextEditingController();

  final _legalNameController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _addressController =
      TextEditingController();

  final _cityController =
      TextEditingController();

  final _stateController =
      TextEditingController();

  // ============================================================
  // BRANCH CONTROLLERS
  // ============================================================

  final _branchNameController =
      TextEditingController();

  final _branchCodeController =
      TextEditingController();

  final _branchAddressController =
      TextEditingController();

  final _branchCityController =
      TextEditingController();

  bool _loading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();

    _branchNameController.dispose();
    _branchCodeController.dispose();
    _branchAddressController.dispose();
    _branchCityController.dispose();

    super.dispose();
  }

  // ============================================================
  // CREATE BUSINESS
  // ============================================================

  Future<void> _createBusiness() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      await BusinessService.instance.createBusiness(
        businessName:
            _businessNameController.text.trim(),

        legalName:
            _legalNameController.text.trim(),

        phone:
            _phoneController.text.trim(),

        email:
            _emailController.text.trim(),

        address:
            _addressController.text.trim(),

        city:
            _cityController.text.trim(),

        state:
            _stateController.text.trim(),

        branchName:
            _branchNameController.text.trim(),

        branchCode:
            _branchCodeController.text
                .trim()
                .toUpperCase(),

        branchAddress:
            _branchAddressController.text
                .trim(),

        branchCity:
            _branchCityController.text
                .trim(),
      );

      if (!mounted) return;

      // ----------------------------------------------------------
      // BUSINESS CREATED
      // ----------------------------------------------------------

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor:
              AppColors.success,

          behavior:
              SnackBarBehavior.floating,

          margin:
              const EdgeInsets.all(
            AppSpacing.lg,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              AppRadius.md,
            ),
          ),

          content: const Row(
            children: [
              Icon(
                Icons
                    .check_circle_outline_rounded,
                color: Colors.white,
              ),

              SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child: Text(
                  'Your business has been created successfully.',
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

      // ----------------------------------------------------------
      // MOVE TO DASHBOARD
      // ----------------------------------------------------------

      await Future.delayed(
        const Duration(
          milliseconds: 500,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (
            context,
            animation,
            secondaryAnimation,
          ) {
            return const DashboardScreen();
          },

          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },

          transitionDuration:
              const Duration(
            milliseconds: 400,
          ),
        ),
        (route) => false,
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
          _loading = false;
        });
      }
    }
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
        backgroundColor:
            AppColors.danger,

        behavior:
            SnackBarBehavior.floating,

        margin:
            const EdgeInsets.all(
          AppSpacing.lg,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            AppRadius.md,
          ),
        ),

        content: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 21,
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: Text(
                message.isEmpty
                    ? 'Something went wrong. Please try again.'
                    : message,

                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REQUIRED VALIDATION
  // ============================================================

  String? _required(
    String? value,
    String message,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  // ============================================================
  // PHONE VALIDATION
  // ============================================================

  String? _validatePhone(
    String? value,
  ) {
    final phone =
        value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Business phone is required';
    }

    final digits =
        phone.replaceAll(
      RegExp(r'\D'),
      '',
    );

    if (digits.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }

    return null;
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  String? _validateEmail(
    String? value,
  ) {
    final email =
        value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Business email is required';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid business email';
    }

    return null;
  }

  // ============================================================
  // BRANCH CODE VALIDATION
  // ============================================================

  String? _validateBranchCode(
    String? value,
  ) {
    final code =
        value?.trim() ?? '';

    if (code.isEmpty) {
      return 'Branch code is required';
    }

    if (code.length < 3) {
      return 'Minimum 3 characters';
    }

    if (code.length > 15) {
      return 'Maximum 15 characters';
    }

    if (!RegExp(
      r'^[A-Za-z0-9_-]+$',
    ).hasMatch(code)) {
      return 'Use letters, numbers, _ or - only';
    }

    return null;
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
        automaticallyImplyLeading:
            false,

        title: const Text(
          'Set Up Your Business',
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,

            padding:
                const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.xxxl,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  width: 58,
                  height: 58,

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.primary,

                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.lg,
                    ),

                    boxShadow:
                        AppShadows.card,
                  ),

                  child: const Icon(
                    Icons
                        .directions_car_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                const SizedBox(
                  height:
                      AppSpacing.xxl,
                ),

                Text(
                  'Welcome to Car Rental',

                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineLarge,
                ),

                const SizedBox(
                  height:
                      AppSpacing.sm,
                ),

                Text(
                  'Set up your rental business to start managing vehicles, customers, bookings and payments.',

                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyMedium,
                ),

                const SizedBox(
                  height:
                      AppSpacing.xxxl,
                ),

                // ==================================================
                // BUSINESS INFORMATION
                // ==================================================

                _sectionTitle(
                  context,
                  'Business Information',
                  'Your main rental business details',
                ),

                const SizedBox(
                  height:
                      AppSpacing.lg,
                ),

                _field(
                  label:
                      'Business Name',
                  controller:
                      _businessNameController,
                  hint:
                      'e.g. Rahul Car Rentals',
                  icon:
                      Icons
                          .business_outlined,
                  validator:
                      (value) =>
                          _required(
                    value,
                    'Business name is required',
                  ),
                  textCapitalization:
                      TextCapitalization
                          .words,
                ),

                _field(
                  label:
                      'Legal Business Name',
                  controller:
                      _legalNameController,
                  hint:
                      'Enter legal business name',
                  icon:
                      Icons
                          .description_outlined,
                  validator:
                      (value) =>
                          _required(
                    value,
                    'Legal business name is required',
                  ),
                  textCapitalization:
                      TextCapitalization
                          .words,
                ),

                _field(
                  label:
                      'Business Phone',
                  controller:
                      _phoneController,
                  hint:
                      '10-digit phone number',
                  icon:
                      Icons
                          .phone_outlined,
                  keyboardType:
                      TextInputType.phone,
                  maxLength: 10,
                  validator:
                      _validatePhone,
                ),

                _field(
                  label:
                      'Business Email',
                  controller:
                      _emailController,
                  hint:
                      'business@example.com',
                  icon:
                      Icons
                          .email_outlined,
                  keyboardType:
                      TextInputType
                          .emailAddress,
                  validator:
                      _validateEmail,
                ),

                _field(
                  label:
                      'Business Address',
                  controller:
                      _addressController,
                  hint:
                      'Enter business address',
                  icon:
                      Icons
                          .location_on_outlined,
                  maxLines: 2,
                  validator:
                      (value) =>
                          _required(
                    value,
                    'Business address is required',
                  ),
                ),

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Expanded(
                      child: _field(
                        label: 'City',
                        controller:
                            _cityController,
                        hint: 'Pune',
                        icon:
                            Icons
                                .location_city_outlined,
                        validator:
                            (value) =>
                                _required(
                          value,
                          'City is required',
                        ),
                        textCapitalization:
                            TextCapitalization
                                .words,
                      ),
                    ),

                    const SizedBox(
                      width:
                          AppSpacing.md,
                    ),

                    Expanded(
                      child: _field(
                        label: 'State',
                        controller:
                            _stateController,
                        hint:
                            'Maharashtra',
                        icon:
                            Icons
                                .map_outlined,
                        validator:
                            (value) =>
                                _required(
                          value,
                          'State is required',
                        ),
                        textCapitalization:
                            TextCapitalization
                                .words,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      AppSpacing.xxl,
                ),

                // ==================================================
                // BRANCH INFORMATION
                // ==================================================

                _sectionTitle(
                  context,
                  'Branch Information',
                  'One branch per account for now',
                ),

                const SizedBox(
                  height:
                      AppSpacing.lg,
                ),

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(
                    AppSpacing.lg,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.infoBackground,

                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.lg,
                    ),

                    border: Border.all(
                      color:
                          AppColors.infoBorder,
                    ),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Container(
                        width: 34,
                        height: 34,

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            AppRadius.sm,
                          ),
                        ),

                        child:
                            const Icon(
                          Icons
                              .info_outline_rounded,
                          color:
                              AppColors.info,
                          size: 19,
                        ),
                      ),

                      const SizedBox(
                        width:
                            AppSpacing.md,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              'Branch Code',

                              style:
                                  Theme.of(
                                context,
                              )
                                      .textTheme
                                      .titleSmall,
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              'This code uniquely identifies your rental operation. Use something short like RCR001 or PUNE01.',

                              style:
                                  Theme.of(
                                context,
                              )
                                      .textTheme
                                      .bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                      AppSpacing.lg,
                ),

                _field(
                  label:
                      'Branch Name',
                  controller:
                      _branchNameController,
                  hint:
                      'e.g. Pune Main Branch',
                  icon:
                      Icons
                          .storefront_outlined,
                  validator:
                      (value) =>
                          _required(
                    value,
                    'Branch name is required',
                  ),
                  textCapitalization:
                      TextCapitalization
                          .words,
                ),

                _field(
                  label:
                      'Branch Code',
                  controller:
                      _branchCodeController,
                  hint:
                      'e.g. RCR001',
                  icon:
                      Icons
                          .qr_code_2_rounded,
                  textCapitalization:
                      TextCapitalization
                          .characters,
                  maxLength: 15,
                  validator:
                      _validateBranchCode,
                  onChanged:
                      (value) {
                    final upper =
                        value.toUpperCase();

                    if (upper != value) {
                      _branchCodeController
                          .value =
                          _branchCodeController
                              .value
                              .copyWith(
                        text: upper,
                        selection:
                            TextSelection
                                .collapsed(
                          offset:
                              upper.length,
                        ),
                      );
                    }
                  },
                ),

                _field(
                  label:
                      'Branch Address',
                  controller:
                      _branchAddressController,
                  hint:
                      'Enter branch address',
                  icon:
                      Icons
                          .location_on_outlined,
                  maxLines: 2,
                  validator:
                      (value) =>
                          _required(
                    value,
                    'Branch address is required',
                  ),
                ),

                _field(
                  label:
                      'Branch City',
                  controller:
                      _branchCityController,
                  hint:
                      'Pune',
                  icon:
                      Icons
                          .location_city_outlined,
                  validator:
                      (value) =>
                          _required(
                    value,
                    'Branch city is required',
                  ),
                  textCapitalization:
                      TextCapitalization
                          .words,
                ),

                const SizedBox(
                  height:
                      AppSpacing.xxl,
                ),

                // ==================================================
                // SUMMARY
                // ==================================================

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(
                    AppSpacing.lg,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      AppRadius.lg,
                    ),

                    border: Border.all(
                      color:
                          AppColors.border,
                    ),

                    boxShadow:
                        AppShadows.card,
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,

                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.primary
                                  .withValues(
                            alpha: 0.08,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            AppRadius.md,
                          ),
                        ),

                        child:
                            const Icon(
                          Icons
                              .account_tree_outlined,
                          color:
                              AppColors.primary,
                          size: 21,
                        ),
                      ),

                      const SizedBox(
                        width:
                            AppSpacing.md,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              'Your setup',

                              style:
                                  Theme.of(
                                context,
                              )
                                      .textTheme
                                      .titleSmall,
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              '1 Account  •  1 Business  •  1 Branch',

                              style:
                                  Theme.of(
                                context,
                              )
                                      .textTheme
                                      .bodySmall,
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons
                            .check_circle_rounded,
                        color:
                            AppColors.success,
                        size: 22,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height:
                      AppSpacing.xxl,
                ),

                // ==================================================
                // CREATE BUTTON
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : _createBusiness,

                    child: _loading
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
                              Text(
                                'Create Business',
                              ),

                              SizedBox(
                                width: 8,
                              ),

                              Icon(
                                Icons
                                    .arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(
                  height:
                      AppSpacing.lg,
                ),

                Center(
                  child: Text(
                    'You can update business details later from Settings.',

                    textAlign:
                        TextAlign.center,

                    style:
                        Theme.of(context)
                            .textTheme
                            .bodySmall,
                  ),
                ),

                const SizedBox(
                  height:
                      AppSpacing.xxl,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style:
              Theme.of(context)
                  .textTheme
                  .titleLarge,
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          subtitle,

          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall,
        ),
      ],
    );
  }

  // ============================================================
  // FORM FIELD
  // ============================================================

  Widget _field({
    required String label,
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
    String? Function(String?)?
        validator,
    TextInputType? keyboardType,
    TextCapitalization
        textCapitalization =
        TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
    void Function(String)?
        onChanged,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: AppSpacing.lg,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style:
                Theme.of(context)
                    .textTheme
                    .labelLarge,
          ),

          const SizedBox(
            height:
                AppSpacing.sm,
          ),

          TextFormField(
            controller:
                controller,

            keyboardType:
                keyboardType,

            textCapitalization:
                textCapitalization,

            maxLines:
                maxLines,

            maxLength:
                maxLength,

            onChanged:
                onChanged,

            validator:
                validator,

            decoration:
                InputDecoration(
              hintText:
                  hint,

              prefixIcon:
                  Icon(icon),

              counterText:
                  maxLength != null
                      ? ''
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

