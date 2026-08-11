import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMode {
  cash,
  upi,
  card,
  bankTransfer,
  other,
}

class PaymentModel {
  final String id;
  final String bookingId;

  final double amount;
  final PaymentMode mode;

  final DateTime paymentDate;

  final String? referenceNumber;
  final String? notes;

  final String? addedBy;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.mode,
    required this.paymentDate,
    this.referenceNumber,
    this.notes,
    this.addedBy,
    required this.createdAt,
  });

  factory PaymentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return PaymentModel(
      id: doc.id,

      bookingId:
          data['bookingId'] ?? '',

      amount:
          (data['amount'] ?? 0).toDouble(),

      mode:
          _modeFromString(
        data['mode'],
      ),

      paymentDate:
          _dateFromFirestore(
            data['paymentDate'],
          ) ??
          DateTime.now(),

      referenceNumber:
          data['referenceNumber'],

      notes:
          data['notes'],

      addedBy:
          data['addedBy'],

      createdAt:
          _dateFromFirestore(
            data['createdAt'],
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,

      'amount': amount,

      'mode':
          mode.name,

      'paymentDate':
          Timestamp.fromDate(
        paymentDate,
      ),

      'referenceNumber':
          referenceNumber,

      'notes':
          notes,

      'addedBy':
          addedBy,

      'createdAt':
          Timestamp.fromDate(
        createdAt,
      ),
    };
  }

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