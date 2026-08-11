import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:car_rental/services/booking_service.dart';

import 'package:car_rental/models/booking_model.dart';
import '../../app/theme.dart';
import 'pickup_screen.dart';
import 'return_screen.dart';
import 'package:car_rental/models/payment_model.dart';
class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState
    extends State<BookingDetailsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  late BookingModel _booking;
  bool _isRefreshing = false;
bool _isEditing = false;
bool _isSaving = false;

final _formKey = GlobalKey<FormState>();

late TextEditingController _customerNameController;
late TextEditingController _customerPhoneController;

late TextEditingController _pickupLocationController;
late TextEditingController _returnLocationController;

late TextEditingController _dailyRateController;
late TextEditingController _hourlyRateController;

late TextEditingController _baseRentalController;
late TextEditingController _securityDepositController;

late TextEditingController _extraKmController;
late TextEditingController _fuelChargeController;
late TextEditingController _lateReturnController;
late TextEditingController _damageChargeController;
late TextEditingController _otherChargesController;

late TextEditingController _discountController;
late TextEditingController _taxController;

late TextEditingController _totalAmountController;
late TextEditingController _paidAmountController;

late TextEditingController _agreementNumberController;

late TextEditingController _licenseNumberController;
late TextEditingController _idProofTypeController;
late TextEditingController _idProofNumberController;

late TextEditingController _customerNotesController;
late TextEditingController _internalNotesController;

DateTime? _editPickupDateTime;
DateTime? _editReturnDateTime;

DateTime? _editLicenseExpiryDate;
List<PaymentModel> _payments = [];

bool _isLoadingPayments = false;
bool _editTermsAccepted = false;
  
@override
void initState() {
  super.initState();

  _booking = widget.booking;

  _initializeEditControllers();

  _loadPayments();
}
@override
void dispose() {
  _customerNameController.dispose();
  _customerPhoneController.dispose();

  _pickupLocationController.dispose();
  _returnLocationController.dispose();

  _dailyRateController.dispose();
  _hourlyRateController.dispose();

  _baseRentalController.dispose();
  _securityDepositController.dispose();

  _extraKmController.dispose();
  _fuelChargeController.dispose();
  _lateReturnController.dispose();
  _damageChargeController.dispose();
  _otherChargesController.dispose();

  _discountController.dispose();
  _taxController.dispose();

  _totalAmountController.dispose();
  _paidAmountController.dispose();

  _agreementNumberController.dispose();

  _licenseNumberController.dispose();
  _idProofTypeController.dispose();
  _idProofNumberController.dispose();

  _customerNotesController.dispose();
  _internalNotesController.dispose();

  super.dispose();
}
void _initializeEditControllers() {
  _customerNameController =
      TextEditingController(
    text: _booking.customerName,
  );

  _customerPhoneController =
      TextEditingController(
    text: _booking.customerPhone,
  );

  _pickupLocationController =
      TextEditingController(
    text: _booking.pickupLocation,
  );

  _returnLocationController =
      TextEditingController(
    text: _booking.returnLocation,
  );

  _dailyRateController =
      TextEditingController(
    text: _booking.dailyRate.toString(),
  );

  _hourlyRateController =
      TextEditingController(
    text: _booking.hourlyRate?.toString() ?? '',
  );

  _baseRentalController =
      TextEditingController(
    text: _booking.baseRentalAmount.toString(),
  );

  _securityDepositController =
      TextEditingController(
    text: _booking.securityDeposit.toString(),
  );

  _extraKmController =
      TextEditingController(
    text: _booking.extraKmCharge.toString(),
  );

  _fuelChargeController =
      TextEditingController(
    text: _booking.fuelCharge.toString(),
  );

  _lateReturnController =
      TextEditingController(
    text: _booking.lateReturnCharge.toString(),
  );

  _damageChargeController =
      TextEditingController(
    text: _booking.damageCharge.toString(),
  );

  _otherChargesController =
      TextEditingController(
    text: _booking.otherCharges.toString(),
  );

  _discountController =
      TextEditingController(
    text: _booking.discount.toString(),
  );

  _taxController =
      TextEditingController(
    text: _booking.tax.toString(),
  );

  _totalAmountController =
      TextEditingController(
    text: _booking.totalAmount.toString(),
  );

  _paidAmountController =
      TextEditingController(
    text: _booking.paidAmount.toString(),
  );

  _agreementNumberController =
      TextEditingController(
    text: _booking.agreementNumber,
  );

  _licenseNumberController =
      TextEditingController(
    text: _booking.licenseNumber ?? '',
  );

  _idProofTypeController =
      TextEditingController(
    text: _booking.idProofType ?? '',
  );

  _idProofNumberController =
      TextEditingController(
    text: _booking.idProofNumber ?? '',
  );

  _customerNotesController =
      TextEditingController(
    text: _booking.customerNotes ?? '',
  );

  _internalNotesController =
      TextEditingController(
    text: _booking.internalNotes ?? '',
  );

  _editPickupDateTime =
      _booking.pickupDateTime;

  _editReturnDateTime =
      _booking.returnDateTime;

  _editLicenseExpiryDate =
      _booking.licenseExpiryDate;

  _editTermsAccepted =
      _booking.termsAccepted;
}
  final BookingService _bookingService =
    BookingService.instance;

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshBooking() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Read only this booking document. The document is converted
      // through the same BookingModel used by BookingService.
      final snapshot = await _firestore
          .collection('bookings')
          .doc(_booking.id)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        setState(() {
          _booking = BookingModel.fromFirestore(
            snapshot,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  Future<void> _loadPayments() async {
  if (_isLoadingPayments) return;

  setState(() {
    _isLoadingPayments = true;
  });

  try {
    final payments =
        await BookingService.instance
            .getPayments(
      bookingId: _booking.id,
    );

    if (!mounted) return;

    setState(() {
      _payments = payments;
    });
  } catch (e) {
    if (!mounted) return;

    _showError(
      _cleanError(
        e.toString(),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoadingPayments = false;
      });
    }
  }
}
  void _cancelEditing() {
  _initializeEditControllers();

  setState(() {
    _isEditing = false;
  });
}
Future<void> _saveChanges() async {
  if (_isSaving) return;

  FocusScope.of(context).unfocus();

  if (_editPickupDateTime == null ||
      _editReturnDateTime == null) {
    _showError(
      'Please select pickup and return date/time.',
    );
    return;
  }

  if (!_editReturnDateTime!
      .isAfter(_editPickupDateTime!)) {
    _showError(
      'Return time must be after pickup time.',
    );
    return;
  }

  double number(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim(),
        ) ??
        0.0;
  }

  final dailyRate =
      number(_dailyRateController);

  final hourlyRateText =
      _hourlyRateController.text.trim();

  final hourlyRate =
      hourlyRateText.isEmpty
          ? null
          : double.tryParse(
              hourlyRateText,
            );

  final rentalAmount =
      number(_baseRentalController);

  final securityDeposit =
      number(
        _securityDepositController,
      );

  final extraKm =
      number(_extraKmController);

  final fuel =
      number(_fuelChargeController);

  final lateReturn =
      number(_lateReturnController);

  final damage =
      number(_damageChargeController);

  final other =
      number(_otherChargesController);

  final discount =
      number(_discountController);

  final tax =
      number(_taxController);

  final totalAmount =
      number(_totalAmountController);

  final paidAmount =
      number(_paidAmountController);

  if (totalAmount < 0) {
    _showError(
      'Total amount cannot be negative.',
    );
    return;
  }

  if (paidAmount < 0) {
    _showError(
      'Paid amount cannot be negative.',
    );
    return;
  }

  if (paidAmount > totalAmount) {
    _showError(
      'Paid amount cannot be greater than total amount.',
    );
    return;
  }

  if (dailyRate < 0 ||
      (hourlyRate ?? 0) < 0 ||
      rentalAmount < 0 ||
      securityDeposit < 0 ||
      extraKm < 0 ||
      fuel < 0 ||
      lateReturn < 0 ||
      damage < 0 ||
      other < 0 ||
      discount < 0 ||
      tax < 0) {
    _showError(
      'Amounts cannot be negative.',
    );
    return;
  }

  final duration =
      _editReturnDateTime!
          .difference(
        _editPickupDateTime!,
      );

  final rentalDays =
      duration.inDays;

  final rentalHours =
      duration.inHours % 24;

  setState(() {
    _isSaving = true;
  });

  try {
    final updated =
        await BookingService
            .instance
            .updateBooking(
      bookingId:
          _booking.id,

      customerName:
          _customerNameController.text
              .trim(),

      customerPhone:
          _customerPhoneController.text
              .trim(),

      pickupDateTime:
          _editPickupDateTime!,

      returnDateTime:
          _editReturnDateTime!,

      pickupLocation:
          _pickupLocationController.text
              .trim(),

      returnLocation:
          _returnLocationController.text
              .trim(),

      dailyRate:
          dailyRate,

      hourlyRate:
          hourlyRate,

      rentalDays:
          rentalDays,

      rentalHours:
          rentalHours,

      baseRentalAmount:
          rentalAmount,

      securityDeposit:
          securityDeposit,

      extraKmCharge:
          extraKm,

      fuelCharge:
          fuel,

      lateReturnCharge:
          lateReturn,

      damageCharge:
          damage,

      otherCharges:
          other,

      discount:
          discount,

      tax:
          tax,

      totalAmount:
          totalAmount,

      paidAmount:
          paidAmount,

      agreementNumber:
          _agreementNumberController.text
              .trim(),

      termsAccepted:
          _editTermsAccepted,

      licenseNumber:
          _licenseNumberController.text
                  .trim()
                  .isEmpty
              ? null
              : _licenseNumberController.text
                  .trim(),

      licenseExpiryDate:
          _editLicenseExpiryDate,

      licenseImageUrl:
          _booking.licenseImageUrl,

      idProofType:
          _idProofTypeController.text
                  .trim()
                  .isEmpty
              ? null
              : _idProofTypeController.text
                  .trim(),

      idProofNumber:
          _idProofNumberController.text
                  .trim()
                  .isEmpty
              ? null
              : _idProofNumberController.text
                  .trim(),

      idProofImageUrl:
          _booking.idProofImageUrl,

      customerNotes:
          _customerNotesController.text
                  .trim()
                  .isEmpty
              ? null
              : _customerNotesController.text
                  .trim(),

      internalNotes:
          _internalNotesController.text
                  .trim()
                  .isEmpty
              ? null
              : _internalNotesController.text
                  .trim(),
    );

    if (!mounted) return;

    setState(() {
      _booking = updated;
      _isEditing = false;
    });

    _initializeEditControllers();

    _showSuccess(
      'Booking updated successfully.',
    );
  } on BookingConflictException catch (
      exception) {
    if (!mounted) return;

    final conflict =
        exception.firstConflict;

    _showError(
      conflict == null
          ? 'Vehicle is not available for the selected period.'
          : 'Vehicle is already booked from '
              '${_dateTime(conflict.pickupDateTime)} '
              'to '
              '${_dateTime(conflict.returnDateTime)}.',
    );
  } catch (error) {
    if (!mounted) return;

    _showError(
      _cleanError(
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
Future<void> _showAddPaymentDialog() async {
  final amountController =
      TextEditingController();

  final referenceController =
      TextEditingController();

  final notesController =
      TextEditingController();

  PaymentMode selectedMode =
      PaymentMode.cash;

  DateTime paymentDate =
      DateTime.now();

  bool isSaving = false;

  await showDialog(
    context: context,
    barrierDismissible: !isSaving,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (
          context,
          setDialogState,
        ) {
          return AlertDialog(
            title: const Text(
              'Add Payment',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  _editField(
                    label: 'Amount',
                    controller:
                        amountController,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<
                      PaymentMode>(
                    value: selectedMode,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Payment Mode',
                    ),
                    items: PaymentMode
                        .values
                        .map(
                          (mode) =>
                              DropdownMenuItem(
                            value: mode,
                            child: Text(
                              _paymentModeLabel(
                                mode,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged:
                        isSaving
                            ? null
                            : (value) {
                                if (value ==
                                    null) {
                                  return;
                                }

                                setDialogState(
                                  () {
                                    selectedMode =
                                        value;
                                  },
                                );
                              },
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap:
                        isSaving
                            ? null
                            : () async {
                                final picked =
                                    await showDatePicker(
                                  context:
                                      context,
                                  initialDate:
                                      paymentDate,
                                  firstDate:
                                      DateTime(
                                    2020,
                                  ),
                                  lastDate:
                                      DateTime(
                                    2100,
                                  ),
                                );

                                if (picked ==
                                    null) {
                                  return;
                                }

                                if (!context
                                    .mounted) {
                                  return;
                                }

                                final time =
                                    await showTimePicker(
                                  context:
                                      context,
                                  initialTime:
                                      TimeOfDay
                                          .fromDateTime(
                                    paymentDate,
                                  ),
                                );

                                if (time ==
                                    null) {
                                  return;
                                }

                                setDialogState(
                                  () {
                                    paymentDate =
                                        DateTime(
                                      picked.year,
                                      picked.month,
                                      picked.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  },
                                );
                              },
                    child: InputDecorator(
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Payment Date',
                        suffixIcon: Icon(
                          Icons
                              .calendar_month_rounded,
                          size: 19,
                        ),
                      ),
                      child: Text(
                        DateFormat(
                          'dd MMM yyyy • hh:mm a',
                        ).format(
                          paymentDate,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  _editField(
                    label:
                        'Reference Number',
                    controller:
                        referenceController,
                  ),

                  _editField(
                    label: 'Notes',
                    controller:
                        notesController,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed:
                    isSaving
                        ? null
                        : () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                child: const Text(
                  'Cancel',
                ),
              ),

              ElevatedButton(
                onPressed:
                    isSaving
                        ? null
                        : () async {
                            final amount =
                                double.tryParse(
                              amountController
                                  .text
                                  .trim(),
                            );

                            if (amount ==
                                    null ||
                                amount <= 0) {
                              _showError(
                                'Enter a valid payment amount.',
                              );
                              return;
                            }

                            if (amount >
                                _booking
                                    .pendingAmount) {
                              _showError(
                                'Payment cannot be greater than the pending amount.',
                              );
                              return;
                            }

                            setDialogState(
                              () {
                                isSaving = true;
                              },
                            );

                            try {
                              final payment =
                                  await BookingService
                                      .instance
                                      .addPayment(
                                bookingId:
                                    _booking.id,
                                amount:
                                    amount,
                                mode:
                                    selectedMode,
                                paymentDate:
                                    paymentDate,
                                referenceNumber:
                                    referenceController
                                        .text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : referenceController
                                        .text
                                        .trim(),
                                notes:
                                    notesController
                                        .text
                                        .trim()
                                        .isEmpty
                                    ? null
                                    : notesController
                                        .text
                                        .trim(),
                              );

                              if (!mounted) {
                                return;
                              }

                              Navigator.pop(
                                dialogContext,
                              );

                              await _refreshBooking();

                              if (!mounted) {
                                return;
                              }

                              _showSuccess(
                                'Payment of ${_money(payment.amount)} added successfully.',
                              );
                            } catch (error) {
                              if (!mounted) {
                                return;
                              }

                              setDialogState(
                                () {
                                  isSaving = false;
                                },
                              );

                              _showError(
                                _cleanError(
                                  error.toString(),
                                ),
                              );
                            }
                          },
                child:
                    isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Add Payment',
                          ),
              ),
            ],
          );
        },
      );
    },
  );

  
}
String _paymentModeLabel(
  PaymentMode mode,
) {
  switch (mode) {
    case PaymentMode.cash:
      return 'Cash';

    case PaymentMode.upi:
      return 'UPI';

    case PaymentMode.card:
      return 'Card';

    case PaymentMode.bankTransfer:
      return 'Bank Transfer';

    case PaymentMode.other:
      return 'Other';
  }
}
Future<List<Map<String, dynamic>>> _loadEditLogs() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('bookings')
      .doc(_booking.id)
      .collection('editLogs')
      .orderBy('editedAt', descending: true)
      .get();

  return snapshot.docs
      .map(
        (doc) => {
          'id': doc.id,
          ...doc.data(),
        },
      )
      .toList();
}
Widget _buildEditHistory() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _loadEditLogs(),
    builder: (context, snapshot) {
      if (snapshot.connectionState ==
          ConnectionState.waiting) {
        return _sectionCard(
          title: 'Edit History',
          icon: Icons.history_rounded,
          child: const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12,
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
        );
      }

      if (snapshot.hasError) {
        return _sectionCard(
          title: 'Edit History',
          icon: Icons.history_rounded,
          child: const Text(
            'Unable to load edit history.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }

      final logs =
          snapshot.data ?? [];

      if (logs.isEmpty) {
        return _sectionCard(
          title: 'Edit History',
          icon: Icons.history_rounded,
          child: const Text(
            'No changes have been made to this booking.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }

      return _sectionCard(
        title: 'Edit History',
        icon: Icons.history_rounded,
        child: Column(
          children: [
            for (int i = 0;
                i < logs.length;
                i++) ...[
              _buildEditLogItem(
                logs[i],
              ),

              if (i != logs.length - 1)
                const Divider(
                  height: 24,
                ),
            ],
          ],
        ),
      );
    },
  );
}
Widget _buildPaymentHistory() {
  if (_isLoadingPayments) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  if (_payments.isEmpty) {
    return const Padding(
      padding: EdgeInsets.only(
        top: 8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'No payments recorded yet.',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  return Column(
    children: [
      const SizedBox(height: 10),

      ..._payments.map(
        (payment) =>
            _buildPaymentItem(payment),
      ),
    ],
  );
}
Widget _buildPaymentItem(
  PaymentModel payment,
) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(
      bottom: 8,
    ),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius:
          BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.border,
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                AppColors.primary.withValues(
              alpha: 0.08,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _paymentModeIcon(
              payment.mode,
            ),
            size: 17,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _money(payment.amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '${_paymentModeLabel(payment.mode)} • '
                '${DateFormat('dd MMM yyyy • hh:mm a').format(payment.paymentDate)}',
                style: const TextStyle(
                  fontSize: 9,
                  color:
                      AppColors.textSecondary,
                ),
              ),

              if (payment.referenceNumber !=
                      null &&
                  payment.referenceNumber!
                      .isNotEmpty)
                Text(
                  'Ref: ${payment.referenceNumber}',
                  style: const TextStyle(
                    fontSize: 9,
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
IconData _paymentModeIcon(
  PaymentMode mode,
) {
  switch (mode) {
    case PaymentMode.cash:
      return Icons.payments_outlined;

    case PaymentMode.upi:
      return Icons.qr_code_rounded;

    case PaymentMode.card:
      return Icons.credit_card_rounded;

    case PaymentMode.bankTransfer:
      return Icons.account_balance_rounded;

    case PaymentMode.other:
      return Icons.more_horiz_rounded;
  }
}
Widget _buildEditLogItem(
  Map<String, dynamic> log,
) {
  final editedBy =
      log['editedByName'] ??
      'Unknown user';

  final editedAt =
      _timestampToDateTime(
        log['editedAt'],
      );

  final changes =
      (log['changes'] as List?)
          ?.whereType<Map>()
          .map(
            (item) =>
                Map<String, dynamic>.from(
              item,
            ),
          )
          .toList() ??
      [];

  return Column(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 17,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  editedBy.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  editedAt == null
                      ? 'Unknown time'
                      : DateFormat(
                          'dd MMM yyyy • hh:mm a',
                        ).format(editedAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      if (changes.isNotEmpty) ...[
        const SizedBox(height: 12),

        ...changes.map(
          (change) {
            final field =
                change['field']
                    ?.toString() ??
                'Field';

            final previous =
                change['previous']
                    ?.toString() ??
                '—';

            final updated =
                change['updated']
                    ?.toString() ??
                '—';

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 7,
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      field,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors
                                .textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    flex: 3,
                    child: Text(
                      '$previous  →  $updated',
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ],
  );
}
DateTime? _timestampToDateTime(
  dynamic value,
) {
  if (value == null) {
    return null;
  }

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}

  // ============================================================
  // MAIN ACTION
  //
  // Booking:
  //   Open PickupScreen -> Prepare Pickup -> Pickup Pending
  //
  // Pickup Pending:
  //   Open PickupScreen -> record KM/fuel/checklist -> Pickup
  // ============================================================
void _showError(String message) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(
          seconds: 3,
        ),
      ),
    );
}

void _showSuccess(String message) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(
          seconds: 2,
        ),
      ),
    );
}
  Future<void> _handleMainAction() async {
    switch (_booking.status) {
      case BookingStatus.booking:
      case BookingStatus.pickupPending:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PickupScreen(
              booking: _booking,
            ),
          ),
        );

        // PickupScreen can change the booking status, so refresh
        // the details screen when we return.
        if (mounted) {
          await _refreshBooking();
        }
        return;

      case BookingStatus.pickup:
  await _startRental();
  return;

      case BookingStatus.active:
  await _startReturn();
  return;

      case BookingStatus.returnPending:
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ReturnScreen(
        booking: _booking,
      ),
    ),
  );

  if (mounted) {
    await _refreshBooking();
  }

  return;

      case BookingStatus.returning:
        _showMessage(
          'Complete the return inspection to finish this booking.',
        );
        return;

      case BookingStatus.completed:
        _showMessage(
          'This booking is already completed.',
        );
        return;

      case BookingStatus.cancelled:
        _showMessage(
          'This booking has been cancelled.',
        );
        return;

      case BookingStatus.noShow:
        _showMessage(
          'This booking is marked as no-show.',
        );
        return;
    }
  }
Future<void> _startRental() async {
  try {
    await _bookingService.startRental(
      _booking.id,
    );

    if (!mounted) return;

    await _refreshBooking();

    if (!mounted) return;

    _showMessage(
      'Rental started successfully.',
    );
  } catch (e) {
    if (!mounted) return;

    _showMessage(
      e.toString().replaceFirst(
        'Exception: ',
        '',
      ),
    );
  }
}
Future<void> _startReturn() async {
  try {
    await _bookingService.markReturnPending(
      _booking.id,
    );

    if (!mounted) return;

    await _refreshBooking();

    if (!mounted) return;

    _showMessage(
      'Booking moved to Return Pending.',
    );
  } catch (e) {
    if (!mounted) return;

    _showMessage(
      e.toString().replaceFirst(
        'Exception: ',
        '',
      ),
    );
  }
}
  // ============================================================
  // HELPERS
  // ============================================================

  String _cleanError(String value) {
    return value
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  String _statusLabel(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return 'Booking';

      case BookingStatus.pickupPending:
        return 'Pickup Pending';

      case BookingStatus.pickup:
        return 'Pickup';

      case BookingStatus.active:
        return 'Active';

      case BookingStatus.returnPending:
        return 'Return Pending';

      case BookingStatus.returning:
        return 'Returning';

      case BookingStatus.completed:
        return 'Completed';

      case BookingStatus.cancelled:
        return 'Cancelled';

      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  Color _statusColor(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return AppColors.primary;

      case BookingStatus.pickupPending:
        return AppColors.warning;

      case BookingStatus.pickup:
        return AppColors.primary;

      case BookingStatus.active:
        return AppColors.success;

      case BookingStatus.returnPending:
        return AppColors.warning;

      case BookingStatus.returning:
        return AppColors.primary;

      case BookingStatus.completed:
        return AppColors.success;

      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return AppColors.danger;
    }
  }

  IconData _statusIcon(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return Icons.event_note_rounded;

      case BookingStatus.pickupPending:
        return Icons.schedule_rounded;

      case BookingStatus.pickup:
        return Icons.key_rounded;

      case BookingStatus.active:
        return Icons.directions_car_filled_rounded;

      case BookingStatus.returnPending:
        return Icons.assignment_return_rounded;

      case BookingStatus.returning:
        return Icons.sync_rounded;

      case BookingStatus.completed:
        return Icons.check_circle_rounded;

      case BookingStatus.cancelled:
        return Icons.close_rounded;

      case BookingStatus.noShow:
        return Icons.person_off_rounded;
    }
  }

  String _paymentLabel(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.unpaid:
        return 'Unpaid';

      case PaymentStatus.partiallyPaid:
        return 'Partially Paid';

      case PaymentStatus.paid:
        return 'Paid';

      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  Color _paymentColor(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.unpaid:
        return AppColors.danger;

      case PaymentStatus.partiallyPaid:
        return AppColors.warning;

      case PaymentStatus.paid:
        return AppColors.success;

      case PaymentStatus.refunded:
        return AppColors.primary;
    }
  }

  String _money(double value) {
    return NumberFormat(
      '#,##0.##',
    ).format(value);
  }

  String _dateTime(DateTime value) {
    return DateFormat(
      'dd MMM yyyy • hh:mm a',
    ).format(value);
  }

  String _date(DateTime value) {
    return DateFormat(
      'dd MMM yyyy',
    ).format(value);
  }

  String _fuelLabel(
    FuelLevel? fuel,
  ) {
    if (fuel == null) {
      return 'Not recorded';
    }

    switch (fuel) {
      case FuelLevel.empty:
        return 'Empty';

      case FuelLevel.quarter:
        return '¼ Tank';

      case FuelLevel.half:
        return '½ Tank';

      case FuelLevel.threeQuarter:
        return '¾ Tank';

      case FuelLevel.full:
        return 'Full';
    }
  }

  String _mainActionLabel() {
    switch (_booking.status) {
      case BookingStatus.booking:
        return 'Prepare Pickup';

      case BookingStatus.pickupPending:
        return 'Start Pickup';

      case BookingStatus.pickup:
        return 'Start Rental';

      case BookingStatus.active:
        return 'Start Return';

      case BookingStatus.returnPending:
        return 'Process Return';

      case BookingStatus.returning:
        return 'Complete Return';

      case BookingStatus.completed:
        return 'View Completed';

      case BookingStatus.cancelled:
        return 'Booking Cancelled';

      case BookingStatus.noShow:
        return 'Booking No-Show';
    }
  }

  bool _mainActionEnabled() {
    return _booking.status !=
            BookingStatus.completed &&
        _booking.status !=
            BookingStatus.cancelled &&
        _booking.status !=
            BookingStatus.noShow;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(
            16,
          ),
          content: Text(
            message,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColor(
      _booking.status,
    );

    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar:
          _buildAppBar(
        statusColor,
      ),
      bottomNavigationBar:
          _buildBottomAction(
        statusColor,
      ),
      body:
          RefreshIndicator(
        onRefresh:
            _refreshBooking,
        child:
            ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            130,
          ),
          children: [
            _buildBookingHeader(
              statusColor,
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildRentalPeriod(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildCustomerCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildVehicleCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildLocationCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildStatusTimeline(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildPricingCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            
SizedBox(
  width: double.infinity,
  height: 44,
  child: OutlinedButton.icon(
    onPressed: _showAddPaymentDialog,
    icon: const Icon(
      Icons.add_rounded,
      size: 18,
    ),
    label: const Text(
      'Add Payment',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(
        color: AppColors.primary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),
         const SizedBox(
              height: AppSpacing.lg,
            ),

_buildPaymentHistory(),
         const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildInspectionCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildDocumentsCard(),
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildAgreementCard(),
            if (_booking.customerNotes != null &&
                _booking.customerNotes!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: AppSpacing.lg,
              ),
              _buildNotesCard(
                title:
                    'Customer Notes',
                icon:
                    Icons.chat_bubble_outline_rounded,
                text:
                    _booking.customerNotes!,
              ),
            ],
            if (_booking.internalNotes != null &&
                _booking.internalNotes!
                    .trim()
                    .isNotEmpty) ...[
              const SizedBox(
                height: AppSpacing.lg,
              ),
              _buildNotesCard(
                title:
                    'Internal Notes',
                icon:
                    Icons.notes_rounded,
                text:
                    _booking.internalNotes!,
              ),
            ],
            const SizedBox(
              height: AppSpacing.lg,
            ),
            _buildAuditCard(),
            _buildEditHistory(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    Color statusColor,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor:
          AppColors.background,
      surfaceTintColor:
          Colors.transparent,
      titleSpacing:
          0,
      leading:
          IconButton(
        icon:
            const Icon(
          Icons.arrow_back_rounded,
        ),
        onPressed:
            () =>
                Navigator.of(context)
                    .pop(),
      ),
      title:
          const Text(
        'Booking Details',
        style:
            TextStyle(
          fontSize: 19,
          fontWeight:
              FontWeight.w800,
          color:
              AppColors.textPrimary,
        ),
      ),
     actions: [
  IconButton(
    tooltip:
        _isEditing
            ? 'Cancel'
            : 'Edit Booking',
    onPressed:
        _isSaving
            ? null
            : () {
                if (_isEditing) {
                  _cancelEditing();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
    icon: Icon(
      _isEditing
          ? Icons.close_rounded
          : Icons.edit_rounded,
    ),
  ),

  IconButton(
    tooltip: 'Refresh',
    onPressed:
        _isRefreshing || _isEditing
            ? null
            : _refreshBooking,
    icon:
        _isRefreshing
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.refresh_rounded,
              ),
  ),

  const SizedBox(
    width: AppSpacing.sm,
  ),
],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildBookingHeader(
    Color statusColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOOKING NUMBER',
                      style:
                          TextStyle(
                        fontSize: 9,
                        letterSpacing:
                            0.8,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      _booking.bookingNumber,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                _booking.status,
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          Container(
            height: 1,
            color:
                AppColors.border,
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          Row(
            children: [
              Expanded(
                child:
                    _headerMetric(
                  icon:
                      Icons.directions_car_rounded,
                  label:
                      'Vehicle',
                  value:
                      _booking.vehicleName,
                ),
              ),
              Expanded(
                child:
                    _headerMetric(
                  icon:
                      Icons.payments_rounded,
                  label:
                      'Total',
                  value:
                      '₹${_money(_booking.totalAmount)}',
                ),
              ),
              Expanded(
                child:
                    _headerMetric(
                  icon:
                      Icons
                          .account_balance_wallet_rounded,
                  label:
                      'Pending',
                  value:
                      '₹${_money(_booking.pendingAmount)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color:
              AppColors.textSecondary,
        ),
        const SizedBox(
          width: 7,
        ),
        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  fontSize: 9,
                  color:
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(
    BookingStatus status,
  ) {
    final color =
        _statusColor(
      status,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
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
      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(
              status,
            ),
            size: 14,
            color:
                color,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            _statusLabel(
              status,
            ),
            style:
                TextStyle(
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
              color:
                  color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RENTAL PERIOD
  // ============================================================

  Widget _buildRentalPeriod() {
  if (_isEditing) {
    return _sectionCard(
      title: 'Rental Period',
      icon: Icons.schedule_rounded,
      child: Column(
        children: [
          _editDateTimeField(
            label: 'Pickup Date & Time',
            value: _editPickupDateTime,
            icon: Icons.login_rounded,
            onTap: () async {
              final value =
                  await _pickDateTime(
                _editPickupDateTime ??
                    DateTime.now(),
              );

              if (value != null) {
                setState(() {
                  _editPickupDateTime = value;
                });
              }
            },
          ),

          const SizedBox(height: 4),

          _editDateTimeField(
            label: 'Return Date & Time',
            value: _editReturnDateTime,
            icon: Icons.logout_rounded,
            onTap: () async {
              final value =
                  await _pickDateTime(
                _editReturnDateTime ??
                    (_editPickupDateTime ??
                        DateTime.now())
                    .add(
                      const Duration(days: 1),
                    ),
              );

              if (value != null) {
                setState(() {
                  _editReturnDateTime = value;
                });
              }
            },
          ),

          const SizedBox(height: 8),

          _buildEditDuration(),
        ],
      ),
    );
  }

  return _sectionCard(
    title: 'Rental Period',
    icon: Icons.schedule_rounded,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _dateBlock(
                title: 'PICKUP',
                icon: Icons.login_rounded,
                dateTime:
                    _booking.pickupDateTime,
              ),
            ),
            _durationBadge(),
            Expanded(
              child: _dateBlock(
                title: 'RETURN',
                icon: Icons.logout_rounded,
                dateTime:
                    _booking.returnDateTime,
                alignRight: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
Widget _editDateTimeField({
  required String label,
  required DateTime? value,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius:
        BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value == null
                      ? 'Select date & time'
                      : _dateTime(value),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );
}
Future<DateTime?> _pickDateTime(
  DateTime initialDate,
) async {
  final now = DateTime.now();

  final date = await showDatePicker(
    context: context,
    initialDate:
        initialDate.isBefore(now)
            ? now
            : initialDate,
    firstDate: now,
    lastDate: DateTime(2100),
  );

  if (date == null) {
    return null;
  }

  if (!mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(
      initialDate,
    ),
  );

  if (time == null) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}
Widget _buildEditDuration() {
  final pickup = _editPickupDateTime;
  final returnDate = _editReturnDateTime;

  if (pickup == null || returnDate == null) {
    return const SizedBox.shrink();
  }

  final difference =
      returnDate.difference(pickup);

  if (difference.isNegative ||
      difference.inMinutes == 0) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            AppColors.danger.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.danger,
          ),
          SizedBox(width: 8),
          Text(
            'Return must be after pickup.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  final days = difference.inDays;
  final hours = difference.inHours % 24;

  String duration;

  if (days > 0 && hours > 0) {
    duration = '$days days $hours hours';
  } else if (days > 0) {
    duration = '$days days';
  } else {
    duration = '${difference.inHours} hours';
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color:
          AppColors.primary.withValues(
        alpha: 0.06,
      ),
      borderRadius:
          BorderRadius.circular(12),
      border: Border.all(
        color:
            AppColors.primary.withValues(
          alpha: 0.12,
        ),
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.timelapse_rounded,
          size: 17,
          color: AppColors.primary,
        ),

        const SizedBox(width: 8),

        const Text(
          'Rental Duration',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color:
                AppColors.textSecondary,
          ),
        ),

        const Spacer(),

        Text(
          duration,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color:
                AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
  Widget _dateBlock({
    required String title,
    required IconData icon,
    required DateTime dateTime,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              alignRight
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: [
            if (!alignRight)
              Icon(
                icon,
                size: 15,
                color:
                    AppColors.textSecondary,
              ),
            if (!alignRight)
              const SizedBox(
                width: 5,
              ),
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 9,
                letterSpacing:
                    0.6,
                fontWeight:
                    FontWeight.w800,
                color:
                    AppColors.textSecondary,
              ),
            ),
            if (alignRight)
              const SizedBox(
                width: 5,
              ),
            if (alignRight)
              Icon(
                icon,
                size: 15,
                color:
                    AppColors.textSecondary,
              ),
          ],
        ),
        const SizedBox(
          height: 7,
        ),
        Text(
          _date(dateTime),
          textAlign:
              alignRight
                  ? TextAlign.right
                  : TextAlign.left,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w800,
            color:
                AppColors.textPrimary,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          DateFormat(
            'hh:mm a',
          ).format(
            dateTime,
          ),
          textAlign:
              alignRight
                  ? TextAlign.right
                  : TextAlign.left,
          style:
              const TextStyle(
            fontSize: 10,
            color:
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _durationBadge() {
    final totalHours =
        _booking.rentalDays * 24 +
            _booking.rentalHours;

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          20,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Column(
        children: [
          Text(
            _booking.rentalDays > 0
                ? '${_booking.rentalDays}d'
                : '${totalHours}h',
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(
            height: 1,
          ),
          const Text(
            'duration',
            style:
                TextStyle(
              fontSize: 7,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER
  // ============================================================

  Widget _buildCustomerCard() {
  if (_isEditing) {
    return _sectionCard(
      title: 'Customer',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _editField(
            label: 'Customer Name',
            controller:
                _customerNameController,
          ),

          _editField(
            label: 'Phone Number',
            controller:
                _customerPhoneController,
            keyboardType:
                TextInputType.phone,
          ),
        ],
      ),
    );
  }

  return _sectionCard(
    title: 'Customer',
    icon: Icons.person_outline_rounded,
    child: Row(
      children: [
        _avatar(
          _booking.customerName,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                _booking.customerName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _booking.customerPhone,
                style: const TextStyle(
                  fontSize: 11,
                  color:
                      AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _smallActionIcon(
          icon: Icons.phone_outlined,
          onTap: () => _showMessage(
            'Customer call action can be connected here.',
          ),
        ),
      ],
    ),
  );
}

  Widget _avatar(
    String name,
  ) {
    final initial =
        name.trim().isEmpty
            ? '?'
            : name
                .trim()
                .substring(
                  0,
                  1,
                )
                .toUpperCase();

    return Container(
      width: 46,
      height: 46,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color:
            AppColors.primary
                .withValues(
          alpha: 0.08,
        ),
        shape:
            BoxShape.circle,
      ),
      child:
          Text(
        initial,
        style:
            const TextStyle(
          fontSize: 16,
          fontWeight:
              FontWeight.w900,
          color:
              AppColors.primary,
        ),
      ),
    );
  }

  Widget _smallActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Container(
          width: 38,
          height: 38,
          decoration:
              BoxDecoration(
            color:
                AppColors.background,
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border:
                Border.all(
              color:
                  AppColors.border,
            ),
          ),
          child:
              Icon(
            icon,
            size: 18,
            color:
                AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE
  // ============================================================

  Widget _buildVehicleCard() {
    return _sectionCard(
      title:
          'Vehicle',
      icon:
          Icons.directions_car_rounded,
      child:
          Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.primary
                          .withValues(
                    alpha: 0.07,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    const Icon(
                  Icons
                      .directions_car_filled_rounded,
                  color:
                      AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _booking.vehicleName,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _booking
                          .vehicleRegistrationNumber,
                      style:
                          const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w700,
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
            height: AppSpacing.md,
          ),
          _infoGrid([
            _InfoItem(
              'Vehicle ID',
              _booking.vehicleId,
            ),
            _InfoItem(
              'Branch',
              _booking.branchCode,
            ),
          ]),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATIONS
  // ============================================================

Widget _buildLocationCard() {
  if (_isEditing) {
    return _sectionCard(
      title: 'Locations',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          _editField(
            label: 'Pickup Location',
            controller:
                _pickupLocationController,
            maxLines: 2,
          ),

          _editField(
            label: 'Return Location',
            controller:
                _returnLocationController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  return _sectionCard(
    title: 'Locations',
    icon: Icons.location_on_outlined,
    child: Column(
      children: [
        _locationRow(
          icon:
              Icons.radio_button_checked_rounded,
          title: 'Pickup Location',
          value:
              _booking.pickupLocation,
        ),
        const SizedBox(height: 12),
        _connectorLine(),
        const SizedBox(height: 12),
        _locationRow(
          icon:
              Icons.location_on_rounded,
          title: 'Return Location',
          value:
              _booking.returnLocation,
        ),
      ],
    ),
  );
}
  Widget _editField({
  required String label,
  required TextEditingController controller,
  TextInputType keyboardType =
      TextInputType.text,
  int maxLines = 1,
  String? prefixText,
  bool enabled = true,
}) {
  return Padding(
    padding: const EdgeInsets.only(
      bottom: 12,
    ),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.border,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.border,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    ),
  );
}

  Widget _locationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color:
              AppColors.textSecondary,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                value.isEmpty
                    ? 'Not specified'
                    : value,
                style:
                    const TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _connectorLine() {
    return Row(
      children: [
        const SizedBox(
          width: 8,
        ),
        Container(
          width: 1,
          height: 8,
          color:
              AppColors.border,
        ),
      ],
    );
  }

  // ============================================================
  // STATUS TIMELINE
  // ============================================================

  Widget _buildStatusTimeline() {
    final steps =
        <_TimelineStep>[
      _TimelineStep(
        BookingStatus.booking,
        'Booking',
        'Reservation created',
      ),
      _TimelineStep(
        BookingStatus.pickupPending,
        'Pickup Pending',
        'Waiting for handover',
      ),
      _TimelineStep(
        BookingStatus.pickup,
        'Pickup',
        'Handover recorded',
      ),
      _TimelineStep(
        BookingStatus.active,
        'Active Rental',
        'Vehicle is with customer',
      ),
      _TimelineStep(
        BookingStatus.returnPending,
        'Return Pending',
        'Vehicle return expected',
      ),
      _TimelineStep(
        BookingStatus.returning,
        'Returning',
        'Return inspection in progress',
      ),
      _TimelineStep(
        BookingStatus.completed,
        'Completed',
        'Rental closed',
      ),
    ];

    final currentIndex =
        _timelineIndex(
      _booking.status,
    );

    return _sectionCard(
      title:
          'Booking Timeline',
      icon:
          Icons.route_rounded,
      child:
          Column(
        children:
            List.generate(
          steps.length,
          (index) {
            final step =
                steps[index];

            final completed =
                currentIndex >=
                    index;

            final current =
                _booking.status ==
                    step.status;

            return _timelineRow(
              step:
                  step,
              completed:
                  completed,
              current:
                  current,
              last:
                  index ==
                      steps.length - 1,
            );
          },
        ),
      ),
    );
  }

  int _timelineIndex(
    BookingStatus status,
  ) {
    switch (status) {
      case BookingStatus.booking:
        return 0;

      case BookingStatus.pickupPending:
        return 1;

      case BookingStatus.pickup:
        return 2;

      case BookingStatus.active:
        return 3;

      case BookingStatus.returnPending:
        return 4;

      case BookingStatus.returning:
        return 5;

      case BookingStatus.completed:
        return 6;

      case BookingStatus.cancelled:
      case BookingStatus.noShow:
        return -1;
    }
  }

  Widget _timelineRow({
    required _TimelineStep step,
    required bool completed,
    required bool current,
    required bool last,
  }) {
    final color =
        current
            ? _statusColor(
                step.status,
              )
            : completed
                ? AppColors.success
                : AppColors.border;

    return IntrinsicHeight(
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            child:
                Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration:
                      BoxDecoration(
                    color:
                        completed
                            ? color.withValues(
                                alpha: 0.10,
                              )
                            : AppColors.background,
                    shape:
                        BoxShape.circle,
                    border:
                        Border.all(
                      color:
                          color,
                      width:
                          current ? 2 : 1,
                    ),
                  ),
                  child:
                      Icon(
                    completed
                        ? current
                            ? _statusIcon(
                                step.status,
                              )
                            : Icons.check_rounded
                        : Icons.circle,
                    size:
                        completed
                            ? 13
                            : 5,
                    color:
                        color,
                  ),
                ),
                if (!last)
                  Expanded(
                    child:
                        Container(
                  width: 1,
                  margin:
                      const EdgeInsets.symmetric(
                    vertical: 3,
                  ),
                  color:
                      completed
                          ? AppColors.success
                              .withValues(
                            alpha: 0.35,
                          )
                          : AppColors.border,
                ),
                  ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 18,
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child:
                            Text(
                          step.title,
                          style:
                              TextStyle(
                            fontSize: 12,
                            fontWeight:
                                current
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                            color:
                                completed
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (current)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                color.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child:
                              Text(
                            'CURRENT',
                            style:
                                TextStyle(
                              fontSize: 7,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing:
                                  0.5,
                              color:
                                  color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    step.subtitle,
                    style:
                        const TextStyle(
                      fontSize: 9,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRICING
  // ============================================================

  Widget _buildPricingCard() {
  if (!_isEditing) {
    return _sectionCard(
      title: 'Pricing & Payment',
      icon: Icons.payments_outlined,
      child: _infoGrid([
        _InfoItem(
          'Daily Rate',
          _money(_booking.dailyRate),
        ),
        _InfoItem(
          'Hourly Rate',
          _booking.hourlyRate == null
              ? '—'
              : _money(_booking.hourlyRate!),
        ),
        _InfoItem(
          'Rental Amount',
          _money(_booking.baseRentalAmount),
        ),
        _InfoItem(
          'Security Deposit',
          _money(_booking.securityDeposit),
        ),
        _InfoItem(
          'Extra KM',
          _money(_booking.extraKmCharge),
        ),
        _InfoItem(
          'Fuel Charge',
          _money(_booking.fuelCharge),
        ),
        _InfoItem(
          'Late Return',
          _money(_booking.lateReturnCharge),
        ),
        _InfoItem(
          'Damage',
          _money(_booking.damageCharge),
        ),
        _InfoItem(
          'Other Charges',
          _money(_booking.otherCharges),
        ),
        _InfoItem(
          'Discount',
          _money(_booking.discount),
        ),
        _InfoItem(
          'Tax',
          _money(_booking.tax),
        ),
        _InfoItem(
          'Total Amount',
          _money(_booking.totalAmount),
        ),
        _InfoItem(
          'Amount Paid',
          _money(_booking.paidAmount),
        ),
        _InfoItem(
          'Pending',
          _money(_booking.pendingAmount),
        ),
        _InfoItem(
          'Payment Status',
          _paymentStatusLabel(
            _booking.paymentStatus,
          ),
        ),
        
      ]),
    );
  }

  return _sectionCard(
    title: 'Pricing & Payment',
    icon: Icons.payments_outlined,
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _editField(
                label: 'Daily Rate',
                controller:
                    _dailyRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _editField(
                label: 'Hourly Rate',
                controller:
                    _hourlyRateController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: _editField(
                label: 'Rental Amount',
                controller:
                    _baseRentalController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _editField(
                label: 'Security Deposit',
                controller:
                    _securityDepositController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // ------------------------------------------
        // ADDITIONAL CHARGES
        // ------------------------------------------

        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Theme(
            data:
                Theme.of(context).copyWith(
              dividerColor:
                  Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              childrenPadding:
                  const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                8,
              ),
              leading: const Icon(
                Icons.tune_rounded,
                size: 19,
              ),
              title: const Text(
                'Additional Charges',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Optional charges, discount & tax',
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
              children: [
                _editField(
                  label: 'Extra KM Charge',
                  controller:
                      _extraKmController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                _editField(
                  label: 'Fuel Charge',
                  controller:
                      _fuelChargeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                _editField(
                  label: 'Late Return Charge',
                  controller:
                      _lateReturnController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                _editField(
                  label: 'Damage Charge',
                  controller:
                      _damageChargeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                _editField(
                  label: 'Other Charges',
                  controller:
                      _otherChargesController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                _editField(
                  label: 'Discount',
                  controller:
                      _discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),

                _editField(
                  label: 'Tax',
                  controller:
                      _taxController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ------------------------------------------
        // TOTAL — EDITABLE
        // ------------------------------------------

        _editField(
          label: 'Total Amount',
          controller:
              _totalAmountController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),

        const SizedBox(height: 2),

        Align(
          alignment:
              Alignment.centerRight,
          child: Text(
            'Final booking amount',
            style: const TextStyle(
              fontSize: 9,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 10),

        _editField(
          label: 'Amount Paid',
          controller:
              _paidAmountController,
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
        ),


        const SizedBox(height: 12),



        _buildEditPendingAmount(),
      ],
    ),
  );
}
Widget _buildEditPendingAmount() {
  final total =
      double.tryParse(
            _totalAmountController.text
                .trim(),
          ) ??
          0;

  final paid =
      double.tryParse(
            _paidAmountController.text
                .trim(),
          ) ??
          0;

  final pending =
      (total - paid) < 0
          ? 0.0
          : (total - paid);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 11,
    ),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius:
          BorderRadius.circular(12),
      border: Border.all(
        color: AppColors.border,
      ),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.account_balance_wallet_outlined,
          size: 17,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Pending Amount',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          _money(pending),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
String _paymentStatusLabel(
  dynamic status,
) {
  return status
      .toString()
      .split('.')
      .last
      .replaceAll(
        RegExp(r'([a-z])([A-Z])'),
        r'$1 $2',
      )
      .toUpperCase();
}

  Widget _priceRow(
    String label,
    double value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child:
          Row(
        children: [
          Expanded(
            child:
                Text(
              label,
              style:
                  TextStyle(
                fontSize:
                    bold ? 12 : 10,
                fontWeight:
                    bold
                        ? FontWeight.w800
                        : FontWeight.w600,
                color:
                    bold
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '${value < 0 ? '-' : ''}₹${_money(value.abs())}',
            style:
                TextStyle(
              fontSize:
                  bold ? 13 : 11,
              fontWeight:
                  FontWeight.w800,
              color:
                  valueColor ??
                      AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentBadge(
    PaymentStatus status,
  ) {
    final color =
        _paymentColor(
      status,
    );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
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
          20,
        ),
      ),
      child:
          Text(
        _paymentLabel(
          status,
        ),
        style:
            TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.w800,
          color:
              color,
        ),
      ),
    );
  }

  // ============================================================
  // INSPECTION
  // ============================================================

  Widget _buildInspectionCard() {
    return _sectionCard(
      title:
          'Vehicle Inspection',
      icon:
          Icons.speed_rounded,
      child:
          Column(
        children: [
          _inspectionRow(
            icon:
                Icons.speed_rounded,
            label:
                'Starting KM',
            value:
                _booking.startingKm == null
                    ? 'Not recorded'
                    : '${_booking.startingKm} km',
          ),
          _inspectionRow(
            icon:
                Icons.flag_rounded,
            label:
                'Ending KM',
            value:
                _booking.endingKm == null
                    ? 'Not recorded'
                    : '${_booking.endingKm} km',
          ),
          _inspectionRow(
            icon:
                Icons.local_gas_station_outlined,
            label:
                'Fuel at Pickup',
            value:
                _fuelLabel(
              _booking.fuelAtPickup,
            ),
          ),
          _inspectionRow(
            icon:
                Icons.local_gas_station_rounded,
            label:
                'Fuel at Return',
            value:
                _fuelLabel(
              _booking.fuelAtReturn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inspectionRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child:
          Row(
        children: [
          Icon(
            icon,
            size: 17,
            color:
                AppColors.textSecondary,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                Text(
              label,
              style:
                  const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style:
                const TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENTS
  // ============================================================

  Widget _buildDocumentsCard() {
    final hasLicense =
        _booking.licenseNumber !=
            null &&
        _booking.licenseNumber!
            .trim()
            .isNotEmpty;

    final hasId =
        _booking.idProofNumber !=
            null &&
        _booking.idProofNumber!
            .trim()
            .isNotEmpty;

    return _sectionCard(
      title:
          'Customer Documents',
      icon:
          Icons.badge_outlined,
      child:
          Column(
        children: [
          _documentRow(
            title:
                'Driving License',
            subtitle:
                hasLicense
                    ? _booking.licenseNumber!
                    : 'Not provided',
            available:
                hasLicense,
            imageUrl:
                _booking.licenseImageUrl,
            expiry:
                _booking.licenseExpiryDate,
          ),
          const SizedBox(
            height: 10,
          ),
          _documentRow(
            title:
                _booking.idProofType?.isNotEmpty ==
                        true
                    ? _booking.idProofType!
                    : 'ID Proof',
            subtitle:
                hasId
                    ? _booking.idProofNumber!
                    : 'Not provided',
            available:
                hasId,
            imageUrl:
                _booking.idProofImageUrl,
          ),
        ],
      ),
    );
  }

  Widget _documentRow({
    required String title,
    required String subtitle,
    required bool available,
    String? imageUrl,
    DateTime? expiry,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  available
                      ? AppColors.success
                          .withValues(
                        alpha: 0.08,
                      )
                      : AppColors.background,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Icon(
              available
                  ? Icons
                      .verified_outlined
                  : Icons
                      .description_outlined,
              size: 19,
              color:
                  available
                      ? AppColors.success
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppColors.textPrimary,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(
                    fontSize: 9,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
                if (expiry != null) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Expires ${_date(expiry)}',
                    style:
                        const TextStyle(
                      fontSize: 8,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (imageUrl != null &&
              imageUrl
                  .trim()
                  .isNotEmpty)
            const Icon(
              Icons
                  .image_outlined,
              size: 18,
              color:
                  AppColors.textSecondary,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // AGREEMENT
  // ============================================================

  Widget _buildAgreementCard() {
    return _sectionCard(
      title:
          'Agreement',
      icon:
          Icons.description_outlined,
      child:
          _infoGrid([
        _InfoItem(
          'Agreement No.',
          _booking.agreementNumber
                  .trim()
                  .isEmpty
              ? 'Not provided'
              : _booking.agreementNumber,
        ),
        _InfoItem(
          'Terms Accepted',
          _booking.termsAccepted
              ? 'Yes'
              : 'No',
        ),
        _InfoItem(
          'Customer Signature',
          _booking.customerSignatureUrl !=
                      null &&
                  _booking.customerSignatureUrl!
                      .trim()
                      .isNotEmpty
              ? 'Available'
              : 'Not added',
        ),
        _InfoItem(
          'Staff Signature',
          _booking.staffSignatureUrl !=
                      null &&
                  _booking.staffSignatureUrl!
                      .trim()
                      .isNotEmpty
              ? 'Available'
              : 'Not added',
        ),
      ]),
    );
  }

  // ============================================================
  // NOTES
  // ============================================================

  Widget _buildNotesCard({
    required String title,
    required IconData icon,
    required String text,
  }) {
    return _sectionCard(
      title:
          title,
      icon:
          icon,
      child:
          Text(
        text,
        style:
            const TextStyle(
          fontSize: 11,
          height: 1.5,
          color:
              AppColors.textSecondary,
        ),
      ),
    );
  }

  // ============================================================
  // AUDIT
  // ============================================================

  Widget _buildAuditCard() {
    return _sectionCard(
      title:
          'Booking Information',
      icon:
          Icons.info_outline_rounded,
      child:
          _infoGrid([
        _InfoItem(
          'Booking ID',
          _booking.id,
        ),
        _InfoItem(
          'Business',
          _booking.businessId,
        ),
        _InfoItem(
          'Created',
          _dateTime(
            _booking.createdAt,
          ),
        ),
        _InfoItem(
          'Updated',
          _dateTime(
            _booking.updatedAt,
          ),
        ),
        _InfoItem(
          'Created By',
          _booking.createdBy,
        ),
        _InfoItem(
          'Confirmed By',
          _booking.confirmedBy ??
              '—',
        ),
        _InfoItem(
          'Started By',
          _booking.startedBy ??
              '—',
        ),
        _InfoItem(
          'Completed By',
          _booking.completedBy ??
              '—',
        ),
      ]),
    );
  }

  // ============================================================
  // COMMON CARDS
  // ============================================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.surface,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    AppColors.textSecondary,
              ),
              const SizedBox(
                width: 8,
              ),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w800,
                  color:
                      AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: AppSpacing.lg,
          ),
          child,
        ],
      ),
    );
  }

  Widget _infoGrid(
    List<_InfoItem> items,
  ) {
    return LayoutBuilder(
      builder:
          (
        context,
        constraints,
      ) {
        final width =
            constraints.maxWidth;

        final columns =
            width >= 560
                ? 3
                : 2;

        final rows =
            <Widget>[];

        for (
          var i = 0;
          i < items.length;
          i += columns
        ) {
          final rowItems =
              items.skip(i).take(
                columns,
              );

          rows.add(
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children:
                  rowItems
                      .map(
                        (
                          item,
                        ) =>
                            Expanded(
                          child:
                              Padding(
                            padding:
                                const EdgeInsets.only(
                              right: 12,
                              bottom: 14,
                            ),
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style:
                                      const TextStyle(
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  item.value,
                                  maxLines:
                                      3,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        FontWeight.w800,
                                    color:
                                        AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          );
        }

        return Column(
          children:
              rows,
        );
      },
    );
  }

  // ============================================================
  // BOTTOM ACTION
  // ============================================================

  Widget _buildBottomAction(
  Color statusColor,
) {
  // ==========================================================
  // EDIT MODE
  // ==========================================================

  if (_isEditing) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          12,
          AppSpacing.xl,
          12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed:
                _isSaving
                    ? null
                    : _saveChanges,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                50,
              ),
              backgroundColor:
                  AppColors.primary,
              foregroundColor:
                  Colors.white,
              disabledBackgroundColor:
                  AppColors.background,
              disabledForegroundColor:
                  AppColors.textSecondary,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.lg,
                ),
              ),
            ),
            child:
                _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          Icon(
                            Icons
                                .check_rounded,
                            size: 19,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 13,
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

  // ==========================================================
  // NORMAL BOOKING MODE
  // ==========================================================

  final enabled =
      _mainActionEnabled();

  return SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        12,
        AppSpacing.xl,
        12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed:
              enabled
                  ? _handleMainAction
                  : null,
          style:
              ElevatedButton.styleFrom(
            minimumSize: const Size(
              double.infinity,
              50,
            ),
            backgroundColor:
                enabled
                    ? statusColor
                    : AppColors.background,
            foregroundColor:
                enabled
                    ? Colors.white
                    : AppColors.textSecondary,
            disabledBackgroundColor:
                AppColors.background,
            disabledForegroundColor:
                AppColors.textSecondary,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                _mainActionLabel(),
                style:
                    const TextStyle(
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              if (enabled) ...[
                const SizedBox(
                  width: 7,
                ),
                const Icon(
                  Icons
                      .arrow_forward_rounded,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
Widget _buildSaveChangesButton() {
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        12,
        AppSpacing.xl,
        12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed:
              _isSaving
                  ? null
                  : _saveChanges,
          style:
              ElevatedButton.styleFrom(
            minimumSize:
                const Size(
              double.infinity,
              50,
            ),
            backgroundColor:
                AppColors.primary,
            foregroundColor:
                Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
            ),
          ),
          child:
              _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .check_rounded,
                          size: 19,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 13,
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
}

// ============================================================
// DATA CLASSES
// ============================================================

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(
    this.label,
    this.value,
  );
}

class _TimelineStep {
  final BookingStatus status;
  final String title;
  final String subtitle;

  const _TimelineStep(
    this.status,
    this.title,
    this.subtitle,
  );
}
