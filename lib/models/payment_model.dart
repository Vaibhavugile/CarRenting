import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================
// PAYMENT TYPE
//
// WHAT is this payment for?
// ============================================================

enum PaymentType {
  rent,
  deposit,
  refundDeposit,
}

// ============================================================
// PAYMENT MODE
//
// HOW was the payment made?
// ============================================================

enum PaymentMode {
  cash,
  upi,
  card,
  bankTransfer,
  other,
}

// ============================================================
// PAYMENT MODEL
// ============================================================

class PaymentModel {
  final String id;
  final String bookingId;

  // ----------------------------------------------------------
  // BUSINESS / BRANCH
  //
  // Stored directly on every payment.
  // This allows future Accounts / Reports / Exports to query
  // payments directly using collectionGroup('payments').
  // ----------------------------------------------------------

  final String businessId;
  final String branchCode;

  // ----------------------------------------------------------
  // PAYMENT
  // ----------------------------------------------------------

  final double amount;

  // What the payment represents:
  // rent / deposit / refundDeposit
  final PaymentType type;

  // How the payment was made:
  // cash / upi / card / bankTransfer / other
  final PaymentMode mode;

  // ----------------------------------------------------------
  // PAYMENT DATE
  // ----------------------------------------------------------

  final DateTime paymentDate;

  // ----------------------------------------------------------
  // OPTIONAL DETAILS
  // ----------------------------------------------------------

  final String? referenceNumber;
  final String? notes;

  // ----------------------------------------------------------
  // AUDIT
  // ----------------------------------------------------------

  final String? addedBy;
  final DateTime createdAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const PaymentModel({
    required this.id,
    required this.bookingId,

    required this.businessId,
    required this.branchCode,

    required this.amount,
    required this.type,
    required this.mode,
    required this.paymentDate,

    this.referenceNumber,
    this.notes,

    this.addedBy,
    required this.createdAt,
  });

  // ==========================================================
  // FROM FIRESTORE
  // ==========================================================

  factory PaymentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data =
        doc.data() ?? {};

    return PaymentModel(
      id:
          doc.id,

      bookingId:
          data['bookingId']
                  ?.toString() ??
              '',

      // ------------------------------------------------------
      // BUSINESS ID
      //
      // Old payments may not have this field yet.
      // They will safely load as an empty string.
      // ------------------------------------------------------

      businessId:
          data['businessId']
                  ?.toString() ??
              '',

      // ------------------------------------------------------
      // BRANCH CODE
      //
      // Old payments may not have this field yet.
      // They will safely load as an empty string.
      // ------------------------------------------------------

      branchCode:
          data['branchCode']
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              '',

      // ------------------------------------------------------
      // AMOUNT
      // ------------------------------------------------------

      amount:
          (data['amount'] as num?)
                  ?.toDouble() ??
              0.0,

      // ------------------------------------------------------
      // PAYMENT TYPE
      //
      // Old payments without `type` are treated as RENT.
      // ------------------------------------------------------

      type:
          _typeFromString(
        data['type'],
      ),

      // ------------------------------------------------------
      // PAYMENT MODE
      // ------------------------------------------------------

      mode:
          _modeFromString(
        data['mode'],
      ),

      // ------------------------------------------------------
      // PAYMENT DATE
      // ------------------------------------------------------

      paymentDate:
          _dateFromFirestore(
            data['paymentDate'],
          ) ??
          DateTime.now(),

      // ------------------------------------------------------
      // REFERENCE NUMBER
      // ------------------------------------------------------

      referenceNumber:
          data['referenceNumber']
              ?.toString(),

      // ------------------------------------------------------
      // NOTES
      // ------------------------------------------------------

      notes:
          data['notes']
              ?.toString(),

      // ------------------------------------------------------
      // ADDED BY
      // ------------------------------------------------------

      addedBy:
          data['addedBy']
              ?.toString(),

      // ------------------------------------------------------
      // CREATED AT
      // ------------------------------------------------------

      createdAt:
          _dateFromFirestore(
            data['createdAt'],
          ) ??
          DateTime.now(),
    );
  }

  // ==========================================================
  // TO FIRESTORE
  // ==========================================================

  Map<String, dynamic> toFirestore() {
    return {
      // ------------------------------------------------------
      // BOOKING
      // ------------------------------------------------------

      'bookingId':
          bookingId,

      // ------------------------------------------------------
      // BUSINESS / BRANCH
      //
      // IMPORTANT FOR FUTURE ACCOUNTS.
      // ------------------------------------------------------

      'businessId':
          businessId,

      'branchCode':
          branchCode,

      // ------------------------------------------------------
      // PAYMENT AMOUNT
      // ------------------------------------------------------

      'amount':
          amount,

      // ------------------------------------------------------
      // PAYMENT TYPE
      // ------------------------------------------------------

      'type':
          type.name,

      // ------------------------------------------------------
      // PAYMENT MODE
      // ------------------------------------------------------

      'mode':
          mode.name,

      // ------------------------------------------------------
      // PAYMENT DATE
      // ------------------------------------------------------

      'paymentDate':
          Timestamp.fromDate(
        paymentDate,
      ),

      // ------------------------------------------------------
      // OPTIONAL DETAILS
      // ------------------------------------------------------

      'referenceNumber':
          referenceNumber,

      'notes':
          notes,

      // ------------------------------------------------------
      // AUDIT
      // ------------------------------------------------------

      'addedBy':
          addedBy,

      'createdAt':
          Timestamp.fromDate(
        createdAt,
      ),
    };
  }

  // ==========================================================
  // PAYMENT TYPE FROM FIRESTORE
  // ==========================================================

  static PaymentType _typeFromString(
    dynamic value,
  ) {
    switch (value) {
      case 'deposit':
        return PaymentType.deposit;

      case 'refundDeposit':
        return PaymentType.refundDeposit;

      case 'rent':
      default:
        // Existing payments without a type are treated
        // as rent so old Firestore data continues to work.
        return PaymentType.rent;
    }
  }

  // ==========================================================
  // PAYMENT MODE FROM FIRESTORE
  // ==========================================================

  static PaymentMode _modeFromString(
    dynamic value,
  ) {
    switch (value) {
      case 'upi':
        return PaymentMode.upi;

      case 'card':
        return PaymentMode.card;

      case 'bankTransfer':
        return PaymentMode.bankTransfer;

      case 'other':
        return PaymentMode.other;

      case 'cash':
      default:
        return PaymentMode.cash;
    }
  }

  // ==========================================================
  // FIRESTORE DATE PARSER
  // ==========================================================

  static DateTime? _dateFromFirestore(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}