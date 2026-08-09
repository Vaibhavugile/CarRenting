import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/booking_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/booking_service.dart';
import 'create_booking_screen.dart';
class CreateBookingScreen extends StatefulWidget {
  final VehicleModel vehicle;

  final DateTime pickupDateTime;
  final DateTime returnDateTime;

  const CreateBookingScreen({
    super.key,
    required this.vehicle,
    required this.pickupDateTime,
    required this.returnDateTime,
  });

  @override
  State<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState
    extends State<CreateBookingScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final _formKey =
      GlobalKey<FormState>();

  final _customerIdController =
      TextEditingController();

  final _customerNameController =
      TextEditingController();

  final _customerPhoneController =
      TextEditingController();

  final _pickupLocationController =
      TextEditingController();

  final _returnLocationController =
      TextEditingController();

  final _securityDepositController =
      TextEditingController();

  final _extraKmChargeController =
      TextEditingController(text: '0');

  final _fuelChargeController =
      TextEditingController(text: '0');

  final _lateReturnChargeController =
      TextEditingController(text: '0');

  final _damageChargeController =
      TextEditingController(text: '0');

  final _otherChargesController =
      TextEditingController(text: '0');

  final _discountController =
      TextEditingController(text: '0');

  final _taxController =
      TextEditingController(text: '0');

  final _paidAmountController =
      TextEditingController(text: '0');

  final _agreementNumberController =
      TextEditingController();

  final _licenseNumberController =
      TextEditingController();

  final _idProofNumberController =
      TextEditingController();

  final _customerNotesController =
      TextEditingController();

  final _internalNotesController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  DateTime? _licenseExpiryDate;

  String? _idProofType;

  bool _termsAccepted = false;

  bool _isSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _securityDepositController.text =
        widget.vehicle.securityDeposit
            .toStringAsFixed(0);

    _agreementNumberController.text =
        _generateAgreementNumber();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _customerIdController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();

    _pickupLocationController.dispose();
    _returnLocationController.dispose();

    _securityDepositController.dispose();

    _extraKmChargeController.dispose();
    _fuelChargeController.dispose();
    _lateReturnChargeController.dispose();
    _damageChargeController.dispose();
    _otherChargesController.dispose();

    _discountController.dispose();
    _taxController.dispose();

    _paidAmountController.dispose();

    _agreementNumberController.dispose();

    _licenseNumberController.dispose();
    _idProofNumberController.dispose();

    _customerNotesController.dispose();
    _internalNotesController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        title: const Text(
          'Create Booking',
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: CustomScrollView(
            physics:
                const BouncingScrollPhysics(),

            slivers: [
              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  140,
                ),

                sliver: SliverList(
                  delegate:
                      SliverChildListDelegate(
                    [
                      _buildHeader(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildVehicleCard(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildRentalPeriod(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildCustomerSection(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildPickupSection(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildPricingSection(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildDocumentsSection(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildNotesSection(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildTermsSection(),

                      const SizedBox(
                        height: AppSpacing.lg,
                      ),

                      _buildBookingSummary(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar:
          _buildBottomBar(),
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
          'Create Rental Booking',
          style:
              Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          'Complete the rental details before confirming the booking.',
          style:
              Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color:
                        AppColors.textSecondary,
                    height: 1.4,
                  ),
        ),
      ],
    );
  }

  // ============================================================
  // VEHICLE CARD
  // ============================================================

  Widget _buildVehicleCard() {
    final vehicleName = [
      widget.vehicle.make,
      widget.vehicle.model,
      widget.vehicle.variant,
    ]
        .where(
          (value) =>
              value.trim().isNotEmpty,
        )
        .join(' ');

    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            icon:
                Icons.directions_car_rounded,
            title: 'Selected Vehicle',
            subtitle:
                'Vehicle selected for this rental',
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Container(
                width: 54,
                height: 54,

                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.lg,
                  ),
                ),

                child: const Icon(
                  Icons
                      .directions_car_rounded,
                  color:
                      AppColors.primary,
                  size: 28,
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
                      vehicleName
                              .trim()
                              .isEmpty
                          ? 'Vehicle'
                          : vehicleName,
                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      widget.vehicle
                          .registrationNumber,
                      style:
                          const TextStyle(
                        color:
                            AppColors
                                .textSecondary,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              _statusChip(
                'Selected',
                AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENTAL PERIOD
  // ============================================================

  Widget _buildRentalPeriod() {
    final duration =
        widget.returnDateTime
            .difference(
              widget.pickupDateTime,
            );

    final days =
        duration.inDays;

    final hours =
        duration.inHours % 24;

    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            icon:
                Icons.schedule_rounded,
            title: 'Rental Period',
            subtitle:
                'Confirmed availability period',
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child: _dateTimeTile(
                  icon:
                      Icons.login_rounded,
                  label: 'Pickup',
                  value:
                      _formatDateTime(
                    widget
                        .pickupDateTime,
                  ),
                ),
              ),

              const SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child: _dateTimeTile(
                  icon:
                      Icons.logout_rounded,
                  label: 'Return',
                  value:
                      _formatDateTime(
                    widget
                        .returnDateTime,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(
              AppSpacing.md,
            ),

            decoration:
                BoxDecoration(
              color:
                  AppColors.primary
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
                  Icons
                      .timelapse_rounded,
                  color:
                      AppColors.primary,
                  size: 19,
                ),

                const SizedBox(
                  width: AppSpacing.sm,
                ),

                Expanded(
                  child: Text(
                    _durationText(
                      days,
                      hours,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                    ),
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
  // CUSTOMER
  // ============================================================

  Widget _buildCustomerSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            icon:
                Icons.person_outline_rounded,
            title: 'Customer',
            subtitle:
                'Renter information',
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          _textField(
            controller:
                _customerIdController,
            label: 'Customer ID',
            hint:
                'Enter customer ID',
            icon:
                Icons.badge_outlined,
            requiredField: true,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _textField(
            controller:
                _customerNameController,
            label: 'Customer Name',
            hint:
                'Enter full customer name',
            icon:
                Icons.person_outline_rounded,
            requiredField: true,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _textField(
            controller:
                _customerPhoneController,
            label: 'Phone Number',
            hint:
                'Enter customer phone',
            icon:
                Icons.phone_outlined,
            keyboardType:
                TextInputType.phone,
            requiredField: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PICKUP & RETURN
  // ============================================================

  Widget _buildPickupSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon:
                Icons.route_outlined,
            title: 'Pickup & Return',
            subtitle:
                'Rental location details',
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          _textField(
            controller:
                _pickupLocationController,
            label: 'Pickup Location',
            hint: 'Enter pickup location',
            icon:
                Icons.login_rounded,
            requiredField: true,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _textField(
            controller:
                _returnLocationController,
            label: 'Return Location',
            hint: 'Enter return location',
            icon:
                Icons.logout_rounded,
            requiredField: true,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _infoBox(
            icon:
                Icons.info_outline_rounded,
            message:
                'Vehicle handover details such as starting KM, fuel level, vehicle condition, damage inspection and pickup photos will be recorded when the customer actually collects the vehicle.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICING
  // ============================================================

  Widget _buildPricingSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            icon:
                Icons.payments_outlined,
            title: 'Pricing',
            subtitle:
                'Rental charges and payment',
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _readOnlyMoneyField(
                  label: 'Daily Rate',
                  value:
                      _money(
                    widget.vehicle
                        .dailyRate,
                  ),
                ),
              ),

              const SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child:
                    _readOnlyMoneyField(
                  label: 'Hourly Rate',
                  value:
                      _money(
                    _hourlyRate,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _readOnlyMoneyField(
                  label: 'Rental Amount',
                  value:
                      _money(
                    _baseRentalAmount,
                  ),
                ),
              ),

              const SizedBox(
                width: AppSpacing.md,
              ),

              Expanded(
                child: _textField(
                  controller:
                      _securityDepositController,
                  label:
                      'Security Deposit',
                  hint: '0',
                  icon:
                      Icons.lock_outline_rounded,
                  keyboardType:
                      const TextInputType
                          .numberWithOptions(
                    decimal: true,
                  ),
                  requiredField: true,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          const Divider(),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          _chargeField(
            controller:
                _extraKmChargeController,
            label: 'Extra KM Charge',
          ),

          _chargeField(
            controller:
                _fuelChargeController,
            label: 'Fuel Charge',
          ),

          _chargeField(
            controller:
                _lateReturnChargeController,
            label: 'Late Return Charge',
          ),

          _chargeField(
            controller:
                _damageChargeController,
            label: 'Damage Charge',
          ),

          _chargeField(
            controller:
                _otherChargesController,
            label: 'Other Charges',
          ),

          _chargeField(
            controller:
                _discountController,
            label: 'Discount',
          ),

          _chargeField(
            controller:
                _taxController,
            label: 'Tax',
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _textField(
            controller:
                _paidAmountController,
            label: 'Amount Paid',
            hint: '0',
            icon:
                Icons.account_balance_wallet_outlined,
            keyboardType:
                const TextInputType
                    .numberWithOptions(
              decimal: true,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENTS
  // ============================================================

  Widget _buildDocumentsSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            icon:
                Icons.description_outlined,
            title: 'Agreement & Documents',
            subtitle:
                'Rental agreement and identity details',
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          _textField(
            controller:
                _agreementNumberController,
            label:
                'Agreement Number',
            hint:
                'Enter agreement number',
            icon:
                Icons.assignment_outlined,
            requiredField: true,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _textField(
            controller:
                _licenseNumberController,
            label:
                'Driving Licence Number',
            hint:
                'Optional',
            icon:
                Icons.credit_card_outlined,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _buildLicenseExpiry(),

          const SizedBox(
            height: AppSpacing.md,
          ),

          DropdownButtonFormField<String>(
            initialValue:
                _idProofType,

            decoration:
                _inputDecoration(
              label:
                  'ID Proof Type',
              icon:
                  Icons
                      .contact_page_outlined,
            ),

            items: const [
              DropdownMenuItem(
                value: 'Aadhaar',
                child:
                    Text('Aadhaar'),
              ),
              DropdownMenuItem(
                value: 'PAN',
                child:
                    Text('PAN'),
              ),
              DropdownMenuItem(
                value: 'Passport',
                child:
                    Text('Passport'),
              ),
              DropdownMenuItem(
                value: 'Voter ID',
                child:
                    Text('Voter ID'),
              ),
              DropdownMenuItem(
                value: 'Other',
                child:
                    Text('Other'),
              ),
            ],

            onChanged: (value) {
              setState(() {
                _idProofType =
                    value;
              });
            },
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _textField(
            controller:
                _idProofNumberController,
            label:
                'ID Proof Number',
            hint:
                'Optional',
            icon:
                Icons.numbers_outlined,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _infoBox(
            icon:
                Icons.info_outline_rounded,
            message:
                'Document image upload can be connected to Firebase Storage next. The current booking service accepts document image URLs.',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LICENSE EXPIRY
  // ============================================================

  Widget _buildLicenseExpiry() {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        AppRadius.md,
      ),

      onTap:
          _pickLicenseExpiry,

      child: InputDecorator(
        decoration:
            _inputDecoration(
          label:
              'Licence Expiry Date',
          icon:
              Icons.event_outlined,
        ),

        child: Text(
          _licenseExpiryDate == null
              ? 'Select expiry date'
              : _formatDate(
                  _licenseExpiryDate!,
                ),

          style:
              TextStyle(
            color:
                _licenseExpiryDate ==
                        null
                    ? AppColors
                        .textSecondary
                    : null,

            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotesSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          _sectionTitle(
            icon:
                Icons.notes_rounded,
            title: 'Notes',
            subtitle:
                'Additional booking information',
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          _textField(
            controller:
                _customerNotesController,
            label:
                'Customer Notes',
            hint:
                'Optional notes for the customer',
            icon:
                Icons.notes_outlined,
            maxLines: 4,
          ),

          const SizedBox(
            height: AppSpacing.md,
          ),

          _textField(
            controller:
                _internalNotesController,
            label:
                'Internal Notes',
            hint:
                'Private staff notes',
            icon:
                Icons.lock_outline_rounded,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TERMS
  // ============================================================

  Widget _buildTermsSection() {
    return _sectionCard(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Checkbox(
            value:
                _termsAccepted,

            activeColor:
                AppColors.primary,

            onChanged: (value) {
              setState(() {
                _termsAccepted =
                    value ?? false;
              });
            },
          ),

          const SizedBox(
            width: AppSpacing.sm,
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                top: 11,
              ),

              child: Text(
                'I confirm that the customer has accepted the rental terms and the information entered in this booking is correct.',

                style:
                    Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          height: 1.4,
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildBookingSummary() {
    final total =
        _totalAmount;

    final paid =
        _doubleValue(
      _paidAmountController,
    );

    final double pending =
    total - paid < 0
        ? 0.0
        : total - paid;

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
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color:
                    AppColors.primary,
              ),

              const SizedBox(
                width: AppSpacing.sm,
              ),

              const Expanded(
                child: Text(
                  'Booking Summary',
                  style:
                      TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: AppSpacing.lg,
          ),

          _summaryRow(
            'Rental',
            _money(
              _baseRentalAmount,
            ),
          ),

          _summaryRow(
            'Additional Charges',
            _money(
              _additionalCharges,
            ),
          ),

          _summaryRow(
            'Discount',
            '- ${_money(
              _discount,
            )}',
          ),

          _summaryRow(
            'Tax',
            _money(
              _tax,
            ),
          ),

          const Divider(
            height: 28,
          ),

          _summaryRow(
            'Total',
            _money(
              total,
            ),
            bold: true,
          ),

          const SizedBox(
            height: AppSpacing.sm,
          ),

          _summaryRow(
            'Paid',
            _money(
              paid,
            ),
          ),

          _summaryRow(
            'Pending',
            _money(
              pending,
            ),
            valueColor:
                pending > 0
                    ? AppColors.danger
                    : AppColors.success,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.md,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,

          border: Border(
            top: BorderSide(
              color:
                  AppColors.border,
            ),
          ),

          boxShadow:
              AppShadows.card,
        ),

        child: SizedBox(
          height: 52,

          child: ElevatedButton.icon(
            onPressed:
                _isSaving
                    ? null
                    : _submitBooking,

            icon:
                _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons
                            .check_circle_outline_rounded,
                      ),

            label:
                Text(
              _isSaving
                  ? 'Creating Booking...'
                  : 'Confirm & Create Booking',
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT BOOKING
  // ============================================================

  Future<void> _submitBooking() async {
    if (_isSaving) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (!_termsAccepted) {
      _showError(
        'Please confirm that the rental terms are accepted.',
      );
      return;
    }

    final paidAmount =
        _doubleValue(
      _paidAmountController,
    );

    final total =
        _totalAmount;

    if (paidAmount < 0) {
      _showError(
        'Paid amount cannot be negative.',
      );
      return;
    }

    if (paidAmount > total) {
      _showError(
        'Paid amount cannot be greater than the total amount.',
      );
      return;
    }

    final securityDeposit =
        _doubleValue(
      _securityDepositController,
    );

    if (securityDeposit < 0) {
      _showError(
        'Security deposit cannot be negative.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final duration =
          widget.returnDateTime
              .difference(
                widget.pickupDateTime,
              );

      final rentalDays =
          duration.inDays;

      final rentalHours =
          duration.inHours % 24;

      final booking =
          await BookingService
              .instance
              .createBooking(
        customerId:
            _customerIdController.text
                .trim(),

        customerName:
            _customerNameController
                .text
                .trim(),

        customerPhone:
            _customerPhoneController
                .text
                .trim(),

        vehicleId:
            widget.vehicle.id,

        pickupDateTime:
            widget.pickupDateTime,

        returnDateTime:
            widget.returnDateTime,

        pickupLocation:
            _pickupLocationController
                .text
                .trim(),

        returnLocation:
            _returnLocationController
                .text
                .trim(),

        // BookingService currently requires these pickup-handover
        // fields. The actual handover screen should update them
        // when the customer collects the vehicle.
        // startingKm:
        //     widget.vehicle.currentKm,

        // fuelAtPickup:
        //     FuelLevel.full,

        dailyRate:
            widget.vehicle.dailyRate,

        hourlyRate:
            _hourlyRate,

        rentalDays:
            rentalDays,

        rentalHours:
            rentalHours,

        baseRentalAmount:
            _baseRentalAmount,

        securityDeposit:
            securityDeposit,

        extraKmCharge:
            _extraKmCharge,

        fuelCharge:
            _fuelCharge,

        lateReturnCharge:
            _lateReturnCharge,

        damageCharge:
            _damageCharge,

        otherCharges:
            _otherCharges,

        discount:
            _discount,

        tax:
            _tax,

        totalAmount:
            total,

        paidAmount:
            paidAmount,

        agreementNumber:
            _agreementNumberController
                .text
                .trim(),

        termsAccepted:
            _termsAccepted,

        licenseNumber:
            _optionalText(
          _licenseNumberController,
        ),

        licenseExpiryDate:
            _licenseExpiryDate,

        // Image URLs will be connected
        // when Firebase Storage upload
        // is added.
        licenseImageUrl:
            null,

        idProofType:
            _idProofType,

        idProofNumber:
            _optionalText(
          _idProofNumberController,
        ),

        idProofImageUrl:
            null,

        customerNotes:
            _optionalText(
          _customerNotesController,
        ),

        internalNotes:
            _optionalText(
          _internalNotesController,
        ),
      );

      if (!mounted) {
        return;
      }

      _showSuccess(
        'Booking ${booking.bookingNumber} created successfully.',
      );

      await Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        booking,
      );
    } on BookingConflictException catch (
        exception) {
      if (!mounted) {
        return;
      }

      final conflict =
          exception.firstConflict;

      _showError(
        conflict == null
            ? 'This vehicle is no longer available for the selected period.'
            : 'Vehicle is already booked from '
                '${_formatDateTime(conflict.pickupDateTime)} '
                'to '
                '${_formatDateTime(conflict.returnDateTime)}.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        _cleanErrorMessage(
          error.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickLicenseExpiry() async {
    final today =
        DateTime.now();

    final picked =
        await showDatePicker(
      context: context,

      firstDate:
          DateTime(
        today.year,
        today.month,
        today.day,
      ),

      lastDate:
          DateTime(
        today.year + 20,
        12,
        31,
      ),

      initialDate:
          _licenseExpiryDate ??
              DateTime(
                today.year + 1,
                today.month,
                today.day,
              ),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _licenseExpiryDate =
          picked;
    });
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  double get _hourlyRate {
    if (widget.vehicle.dailyRate <= 0) {
      return 0;
    }

    return widget.vehicle.dailyRate /
        24;
  }

  Duration get _rentalDuration {
    return widget.returnDateTime
        .difference(
      widget.pickupDateTime,
    );
  }

  double get _baseRentalAmount {
    final duration =
        _rentalDuration;

    final totalHours =
        duration.inHours;

    if (totalHours <= 0) {
      return 0;
    }

    final fullDays =
        totalHours ~/ 24;

    final remainingHours =
        totalHours % 24;

    double amount =
        fullDays *
            widget.vehicle.dailyRate;

    if (remainingHours > 0) {
      amount +=
          remainingHours *
              _hourlyRate;
    }

    return amount;
  }

  double get _extraKmCharge =>
      _doubleValue(
        _extraKmChargeController,
      );

  double get _fuelCharge =>
      _doubleValue(
        _fuelChargeController,
      );

  double get _lateReturnCharge =>
      _doubleValue(
        _lateReturnChargeController,
      );

  double get _damageCharge =>
      _doubleValue(
        _damageChargeController,
      );

  double get _otherCharges =>
      _doubleValue(
        _otherChargesController,
      );

  double get _discount =>
      _doubleValue(
        _discountController,
      );

  double get _tax =>
      _doubleValue(
        _taxController,
      );

  double get _additionalCharges {
    return _extraKmCharge +
        _fuelCharge +
        _lateReturnCharge +
        _damageCharge +
        _otherCharges;
  }

  double get _totalAmount {
    final total =
        _baseRentalAmount +
            _additionalCharges +
            _tax -
            _discount;

    return total < 0
        ? 0
        : total;
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  Widget _sectionCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

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

      child: child,
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
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
                BorderRadius.circular(
              AppRadius.md,
            ),
          ),

          child: Icon(
            icon,
            color:
                AppColors.primary,
            size: 21,
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
                    const TextStyle(
                  fontSize: 14,
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
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dateTimeTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.background,

        borderRadius:
            BorderRadius.circular(
          AppRadius.md,
        ),

        border: Border.all(
          color:
              AppColors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color:
                    AppColors.primary,
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                label,
                style:
                    const TextStyle(
                  color:
                      AppColors
                          .textSecondary,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController
        controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,

      keyboardType:
          keyboardType,

      maxLines:
          maxLines,

      decoration:
          _inputDecoration(
        label: label,
        icon: icon,
        hint: hint,
      ),

      validator: requiredField
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return '$label is required.';
              }

              return null;
            }
          : null,
    );
  }

  Widget _readOnlyMoneyField({
    required String label,
    required String value,
  }) {
    return InputDecorator(
      decoration:
          _inputDecoration(
        label: label,
        icon:
            Icons.currency_rupee_rounded,
      ),

      child: Text(
        value,
        style:
            const TextStyle(
          fontSize: 13,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  Widget _chargeField({
    required TextEditingController
        controller,
    required String label,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: AppSpacing.md,
      ),

      child: TextFormField(
        controller:
            controller,

        keyboardType:
            const TextInputType
                .numberWithOptions(
          decimal: true,
        ),

        decoration:
            _inputDecoration(
          label: label,
          icon:
              Icons.currency_rupee_rounded,
        ),

        onChanged: (_) {
          setState(() {});
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon:
          Icon(
        icon,
        size: 20,
      ),

      filled: true,

      fillColor:
          AppColors.background,

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
          width: 1.4,
        ),
      ),
    );
  }

  Widget _statusChip(
    String text,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withValues(
          alpha: 0.08,
        ),

        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),

      child: Text(
        text,
        style:
            TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),

      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  TextStyle(
                color:
                    AppColors
                        .textSecondary,
                fontSize: 12,
                fontWeight:
                    bold
                        ? FontWeight.w800
                        : FontWeight.w500,
              ),
            ),
          ),

          Text(
            value,
            style:
                TextStyle(
              color:
                  valueColor,
              fontSize:
                  bold ? 15 : 12,
              fontWeight:
                  bold
                      ? FontWeight.w900
                      : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),

      decoration:
          BoxDecoration(
        color:
            AppColors.primary
                .withValues(
          alpha: 0.06,
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
            icon,
            size: 18,
            color:
                AppColors.primary,
          ),

          const SizedBox(
            width: AppSpacing.sm,
          ),

          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                color:
                    AppColors
                        .textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UTILITIES
  // ============================================================

  double _doubleValue(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text
              .trim(),
        ) ??
        0;
  }

  String? _optionalText(
    TextEditingController controller,
  ) {
    final value =
        controller.text.trim();

    return value.isEmpty
        ? null
        : value;
  }

  String _money(
    double value,
  ) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String _generateAgreementNumber() {
    final now =
        DateTime.now();

    final date =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final time =
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return 'AGR-$date-$time';
  }

  String _formatDateTime(
    DateTime dateTime,
  ) {
    final hour =
        dateTime.hour % 12 == 0
            ? 12
            : dateTime.hour % 12;

    final minute =
        dateTime.minute
            .toString()
            .padLeft(2, '0');

    final period =
        dateTime.hour >= 12
            ? 'PM'
            : 'AM';

    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '$hour:$minute $period';
  }

  String _formatDate(
    DateTime dateTime,
  ) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  String _durationText(
    int days,
    int hours,
  ) {
    if (days == 0 &&
        hours == 0) {
      return 'Less than one hour';
    }

    if (days == 0) {
      return '$hours hour${hours == 1 ? '' : 's'}';
    }

    if (hours == 0) {
      return '$days day${days == 1 ? '' : 's'}';
    }

    return '$days day${days == 1 ? '' : 's'} • '
        '$hours hour${hours == 1 ? '' : 's'}';
  }

  String _cleanErrorMessage(
    String error,
  ) {
    if (error.startsWith(
      'Exception: ',
    )) {
      return error.substring(
        'Exception: '.length,
      );
    }

    return error;
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            AppColors.danger,

        content: Text(
          message,
        ),
      ),
    );
  }

  void _showSuccess(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,

        backgroundColor:
            AppColors.success,

        content: Text(
          message,
        ),
      ),
    );
  }
}