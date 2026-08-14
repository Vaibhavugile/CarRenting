import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/payment_model.dart';
import '../../services/accounts_service.dart';

// Use your existing AppColors import.
// Change this path if your AppColors file is somewhere else.
import '../../app/theme.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
  });

  @override
  State<AccountsScreen> createState() =>
      _AccountsScreenState();
}

class _AccountsScreenState
    extends State<AccountsScreen> {
  // ==========================================================
  // DATE FORMATTERS
  // ==========================================================

  final DateFormat _dateFormat =
      DateFormat('dd MMM yyyy');

  final DateFormat _transactionDateFormat =
      DateFormat('dd MMM yyyy • hh:mm a');

  final NumberFormat _currencyFormat =
      NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  // ==========================================================
  // DATE RANGE
  // ==========================================================

  late DateTime _startDate;
  late DateTime _endDate;

  // ==========================================================
  // DATA
  // ==========================================================

  AccountsSummary? _summary;

  bool _isLoading = false;

  String? _errorMessage;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _endDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // Load TODAY by default.
    _loadAccounts();
  }

  // ==========================================================
  // LOAD ACCOUNTS
  // ==========================================================

  Future<void> _loadAccounts() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary =
          await AccountsService.instance
              .getAccounts(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            _cleanErrorMessage(e);
      });
    }
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  String _cleanErrorMessage(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message;
  }

  // ==========================================================
  // START DATE PICKER
  // ==========================================================

  Future<void> _selectStartDate() async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select start date',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );

      // Keep the range valid.
      if (_startDate.isAfter(
        _endDate,
      )) {
        _endDate = _startDate;
      }
    });
  }

  // ==========================================================
  // END DATE PICKER
  // ==========================================================

  Future<void> _selectEndDate() async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select end date',
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );

      // Keep the range valid.
      if (_endDate.isBefore(
        _startDate,
      )) {
        _startDate = _endDate;
      }
    });
  }

  // ==========================================================
  // APPLY DATE FILTER
  // ==========================================================

  Future<void> _applyDateFilter() async {
    await _loadAccounts();
  }

  // ==========================================================
  // RESET TO TODAY
  // ==========================================================

  Future<void> _resetToToday() async {
    final now = DateTime.now();

    setState(() {
      _startDate = DateTime(
        now.year,
        now.month,
        now.day,
      );

      _endDate = DateTime(
        now.year,
        now.month,
        now.day,
      );
    });

    await _loadAccounts();
  }

  // ==========================================================
  // CURRENCY
  // ==========================================================

  String _money(
    double amount,
  ) {
    return _currencyFormat.format(
      amount,
    );
  }

  // ==========================================================
  // PAYMENT TYPE LABEL
  // ==========================================================

  String _paymentTypeLabel(
    PaymentType type,
  ) {
    switch (type) {
      case PaymentType.rent:
        return 'Rent';

      case PaymentType.deposit:
        return 'Deposit';

      case PaymentType.refundDeposit:
        return 'Refund Deposit';
    }
  }

  // ==========================================================
  // PAYMENT MODE LABEL
  // ==========================================================

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

  // ==========================================================
  // PAYMENT ICON
  // ==========================================================

  IconData _paymentModeIcon(
    PaymentMode mode,
  ) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.payments_outlined;

      case PaymentMode.upi:
        return Icons.qr_code_2_outlined;

      case PaymentMode.card:
        return Icons.credit_card_outlined;

      case PaymentMode.bankTransfer:
        return Icons.account_balance_outlined;

      case PaymentMode.other:
        return Icons.more_horiz;
    }
  }

  // ==========================================================
  // PAYMENT TYPE ICON
  // ==========================================================

  IconData _paymentTypeIcon(
    PaymentType type,
  ) {
    switch (type) {
      case PaymentType.rent:
        return Icons.home_work_outlined;

      case PaymentType.deposit:
        return Icons.account_balance_wallet_outlined;

      case PaymentType.refundDeposit:
        return Icons.keyboard_return_outlined;
    }
  }

  // ==========================================================
  // PAYMENT TYPE COLOR
  // ==========================================================

  Color _paymentTypeColor(
    PaymentType type,
  ) {
    switch (type) {
      case PaymentType.rent:
        return AppColors.primary;

      case PaymentType.deposit:
        return Colors.green;

      case PaymentType.refundDeposit:
        return Colors.orange;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor:
            AppColors.background,
        foregroundColor:
            AppColors.textPrimary,
        title: const Text(
          'Accounts',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh:
              _loadAccounts,

          child: _buildBody(),
        ),
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_isLoading &&
        _summary == null) {
      return const Center(
        child:
            CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    if (_errorMessage != null &&
        _summary == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        30,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ====================================================
          // DATE FILTER
          // ====================================================

          _buildDateFilter(),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // LOADING OVERLAY
          // ====================================================

          if (_isLoading)
            const Padding(
              padding:
                  EdgeInsets.only(
                bottom: 12,
              ),
              child:
                  LinearProgressIndicator(
                minHeight: 2,
              ),
            ),

          // ====================================================
          // ERROR
          // ====================================================

          if (_errorMessage != null)
            _buildInlineError(),

          // ====================================================
          // SUMMARY
          // ====================================================

          _buildSummarySection(),

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // TRANSACTIONS
          // ====================================================

          _buildTransactionsSection(),
        ],
      ),
    );
  }

  // ==========================================================
  // DATE FILTER
  // ==========================================================

  Widget _buildDateFilter() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child:
                    _buildDateField(
                  label: 'Start Date',
                  date: _startDate,
                  onTap:
                      _selectStartDate,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    _buildDateField(
                  label: 'End Date',
                  date: _endDate,
                  onTap:
                      _selectEndDate,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton(
                  onPressed:
                      _resetToToday,
                  style:
                      OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(
                      0,
                      44,
                    ),
                    side:
                        BorderSide(
                      color:
                          AppColors.border,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),
                  child:
                      const Text(
                    'Today',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                flex: 2,
                child:
                    ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _applyDateFilter,
                  style:
                      ElevatedButton.styleFrom(
                    minimumSize:
                        const Size(
                      0,
                      44,
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
                        11,
                      ),
                    ),
                  ),
                  child:
                      const Text(
                    'Apply',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DATE FIELD
  // ==========================================================

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(11),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color:
              AppColors.background,
          borderRadius:
              BorderRadius.circular(11),
          border: Border.all(
            color:
                AppColors.border,
          ),
        ),

        child: Row(
          children: [
            Icon(
              Icons
                  .calendar_today_outlined,
              size: 16,
              color:
                  AppColors.primary,
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: Column(
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
                    height: 2,
                  ),

                  Text(
                    _dateFormat.format(
                      date,
                    ),
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SUMMARY SECTION
  // ==========================================================

  Widget _buildSummarySection() {
    final summary =
        _summary;

    if (summary == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const Text(
          'Financial Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // ====================================================
        // TOTAL RECEIVED
        // ====================================================

        _buildLargeSummaryCard(
          title: 'Total Received',
          amount:
              summary.totalReceived,
          icon:
              Icons.account_balance_wallet_outlined,
          accentColor:
              AppColors.primary,
        ),

        const SizedBox(
          height: 10,
        ),

        // ====================================================
        // RENT + DEPOSIT
        // ====================================================

        Row(
          children: [
            Expanded(
              child:
                  _buildSmallSummaryCard(
                title: 'Total Rent',
                amount:
                    summary.totalRent,
                icon:
                    Icons.home_work_outlined,
                accentColor:
                    AppColors.primary,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
                  _buildSmallSummaryCard(
                title: 'Total Deposit',
                amount:
                    summary.totalDeposit,
                icon:
                    Icons
                        .account_balance_wallet_outlined,
                accentColor:
                    Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        // ====================================================
        // REFUNDED
        // ====================================================

        _buildSmallSummaryCard(
          title:
              'Deposit Refunded',
          amount:
              summary.totalRefundDeposit,
          icon:
              Icons.keyboard_return_outlined,
          accentColor:
              Colors.orange,
        ),
      ],
    );
  }

  // ==========================================================
  // LARGE SUMMARY CARD
  // ==========================================================

  Widget _buildLargeSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,

            decoration:
                BoxDecoration(
              color:
                  accentColor.withValues(
                alpha: 0.08,
              ),
              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              icon,
              color:
                  accentColor,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 12,
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
                    fontSize: 11,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _money(amount),
                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SMALL SUMMARY CARD
  // ==========================================================

  Widget _buildSmallSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(15),
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
              Container(
                width: 30,
                height: 30,

                decoration:
                    BoxDecoration(
                  color:
                      accentColor.withValues(
                    alpha: 0.08,
                  ),
                  shape:
                      BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  size: 15,
                  color:
                      accentColor,
                ),
              ),

              const Spacer(),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            title,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 10,
              color:
                  AppColors.textSecondary,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            _money(amount),
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // TRANSACTIONS SECTION
  // ==========================================================

  Widget _buildTransactionsSection() {
    final summary =
        _summary;

    if (summary == null) {
      return const SizedBox();
    }

    final payments =
        summary.payments;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            Text(
              '${payments.length} ${payments.length == 1 ? 'transaction' : 'transactions'}',
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        if (payments.isEmpty)
          _buildEmptyTransactions()
        else
          ...payments.map(
            (payment) =>
                _buildTransactionItem(
              payment,
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // TRANSACTION ITEM
  // ==========================================================

  Widget _buildTransactionItem(
    PaymentModel payment,
  ) {
    final typeColor =
        _paymentTypeColor(
      payment.type,
    );

    final isRefund =
        payment.type ==
            PaymentType.refundDeposit;

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 9,
      ),

      padding:
          const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ====================================================
          // TYPE ICON
          // ====================================================

          Container(
            width: 38,
            height: 38,

            decoration:
                BoxDecoration(
              color:
                  typeColor.withValues(
                alpha: 0.08,
              ),
              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              _paymentTypeIcon(
                payment.type,
              ),
              size: 18,
              color:
                  typeColor,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          // ====================================================
          // DETAILS
          // ====================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _paymentTypeLabel(
                          payment.type,
                        ),
                        style:
                            const TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    Text(
                      '${isRefund ? '-' : '+'}${_money(payment.amount)}',
                      style:
                          TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            typeColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '${_paymentModeLabel(payment.mode)} • '
                  '${_transactionDateFormat.format(payment.paymentDate)}',
                  style:
                      const TextStyle(
                    fontSize: 9,
                    color:
                        AppColors.textSecondary,
                  ),
                ),

                if (payment.referenceNumber !=
                        null &&
                    payment.referenceNumber!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Ref: ${payment.referenceNumber}',
                    style:
                        const TextStyle(
                      fontSize: 9,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],

                if (payment.notes !=
                        null &&
                    payment.notes!
                        .trim()
                        .isNotEmpty) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    payment.notes!,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 9,
                      color:
                          AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY TRANSACTIONS
  // ==========================================================

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color:
            AppColors.background,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              AppColors.border,
        ),
      ),

      child: Column(
        children: [
          Icon(
            Icons
                .receipt_long_outlined,
            size: 34,
            color:
                AppColors.textSecondary,
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'No transactions found.',
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            'No payments were recorded for the selected date range.',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 10,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Container(
              width: 52,
              height: 52,

              decoration:
                  BoxDecoration(
                color:
                    Colors.red.withValues(
                  alpha: 0.08,
                ),
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .error_outline,
                color:
                    Colors.red,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Unable to load accounts',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    AppColors.textSecondary,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            ElevatedButton(
              onPressed:
                  _loadAccounts,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child:
                  const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // INLINE ERROR
  // ==========================================================

  Widget _buildInlineError() {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      padding:
          const EdgeInsets.all(11),

      decoration: BoxDecoration(
        color:
            Colors.red.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color:
              Colors.red.withValues(
            alpha: 0.15,
          ),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons
                .error_outline,
            size: 17,
            color:
                Colors.red,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  const TextStyle(
                fontSize: 10,
                color:
                    Colors.red,
              ),
            ),
          ),

          IconButton(
            onPressed:
                _loadAccounts,
            icon:
                const Icon(
              Icons.refresh,
              size: 18,
            ),
            padding:
                EdgeInsets.zero,
            constraints:
                const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}