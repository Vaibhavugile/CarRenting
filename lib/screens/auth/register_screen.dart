
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/auth_service.dart';
import '../business/business_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.instance.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (!mounted) return;

      // ----------------------------------------------------------
      // IMPORTANT
      //
      // Registration is complete.
      //
      // The next step is BUSINESS SETUP.
      // ----------------------------------------------------------

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const BusinessSetupScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        _getErrorMessage(e),
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
  // ERROR MESSAGE
  // ============================================================

  String _getErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains(
      'email-already-in-use',
    )) {
      return 'An account already exists with this email.';
    }

    if (message.contains(
      'invalid-email',
    )) {
      return 'Please enter a valid email address.';
    }

    if (message.contains(
      'weak-password',
    )) {
      return 'Please choose a stronger password.';
    }

    if (message.contains(
      'network-request-failed',
    )) {
      return 'Please check your internet connection.';
    }

    if (message.contains(
      'operation-not-allowed',
    )) {
      return 'Email and password registration is not enabled.';
    }

    return 'Unable to create your account. Please try again.';
  }

  // ============================================================
  // ERROR SNACKBAR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,

        behavior:
            SnackBarBehavior.floating,

        margin: const EdgeInsets.all(
          AppSpacing.lg,
        ),

        shape: RoundedRectangleBorder(
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
              size: 20,
            ),

            const SizedBox(
              width: AppSpacing.md,
            ),

            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
  // VALIDATION
  // ============================================================

  String? _validateName(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter your full name';
    }

    if (value.trim().length < 2) {
      return 'Please enter a valid name';
    }

    return null;
  }

  String? _validateEmail(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final email = value.trim();

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Please create a password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value !=
        _passwordController.text) {
      return 'Passwords do not match';
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
        backgroundColor:
            AppColors.background,

        leading: IconButton(
          onPressed: _loading
              ? null
              : () {
                  Navigator.of(context)
                      .pop();
                },

          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),

        title: const Text(
          'Create Account',
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

                  decoration: BoxDecoration(
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
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.xxl,
                ),

                Text(
                  'Create your account',

                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge,
                ),

                const SizedBox(
                  height: AppSpacing.sm,
                ),

                Text(
                  'Set up your account first. You will add your rental business and branch next.',

                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium,
                ),

                const SizedBox(
                  height: AppSpacing.xxxl,
                ),

                // ==================================================
                // ACCOUNT SECTION
                // ==================================================

                _SectionHeader(
                  title: 'Account Details',
                  subtitle:
                      'Your personal login information',
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // ==================================================
                // FULL NAME
                // ==================================================

                _FieldLabel(
                  label: 'Full name',
                  requiredField: true,
                ),

                const SizedBox(
                  height: AppSpacing.sm,
                ),

                TextFormField(
                  controller:
                      _nameController,

                  textCapitalization:
                      TextCapitalization.words,

                  textInputAction:
                      TextInputAction.next,

                  autofillHints: const [
                    AutofillHints.name,
                  ],

                  decoration:
                      const InputDecoration(
                    hintText:
                        'Enter your full name',

                    prefixIcon: Icon(
                      Icons
                          .person_outline_rounded,
                    ),
                  ),

                  validator:
                      _validateName,
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // ==================================================
                // EMAIL
                // ==================================================

                _FieldLabel(
                  label: 'Email address',
                  requiredField: true,
                ),

                const SizedBox(
                  height: AppSpacing.sm,
                ),

                TextFormField(
                  controller:
                      _emailController,

                  keyboardType:
                      TextInputType
                          .emailAddress,

                  textInputAction:
                      TextInputAction.next,

                  autofillHints: const [
                    AutofillHints.email,
                  ],

                  decoration:
                      const InputDecoration(
                    hintText:
                        'Enter your email',

                    prefixIcon: Icon(
                      Icons
                          .email_outlined,
                    ),
                  ),

                  validator:
                      _validateEmail,
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // ==================================================
                // PHONE
                // ==================================================

                _FieldLabel(
                  label: 'Phone number',
                  requiredField: false,
                ),

                const SizedBox(
                  height: AppSpacing.sm,
                ),

                TextFormField(
                  controller:
                      _phoneController,

                  keyboardType:
                      TextInputType.phone,

                  textInputAction:
                      TextInputAction.next,

                  autofillHints: const [
                    AutofillHints
                        .telephoneNumber,
                  ],

                  maxLength: 10,

                  decoration:
                      const InputDecoration(
                    hintText:
                        'Enter phone number',

                    prefixIcon: Icon(
                      Icons
                          .phone_outlined,
                    ),

                    counterText: '',
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // ==================================================
                // PASSWORD
                // ==================================================

                _FieldLabel(
                  label: 'Password',
                  requiredField: true,
                ),

                const SizedBox(
                  height: AppSpacing.sm,
                ),

                TextFormField(
                  controller:
                      _passwordController,

                  obscureText:
                      _obscurePassword,

                  textInputAction:
                      TextInputAction.next,

                  autofillHints: const [
                    AutofillHints
                        .newPassword,
                  ],

                  decoration:
                      InputDecoration(
                    hintText:
                        'Create a password',

                    prefixIcon: const Icon(
                      Icons
                          .lock_outline_rounded,
                    ),

                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword =
                              !_obscurePassword;
                        });
                      },

                      icon: Icon(
                        _obscurePassword
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                      ),
                    ),
                  ),

                  validator:
                      _validatePassword,
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // ==================================================
                // CONFIRM PASSWORD
                // ==================================================

                _FieldLabel(
                  label:
                      'Confirm password',
                  requiredField: true,
                ),

                const SizedBox(
                  height: AppSpacing.sm,
                ),

                TextFormField(
                  controller:
                      _confirmPasswordController,

                  obscureText:
                      _obscureConfirmPassword,

                  textInputAction:
                      TextInputAction.done,

                  autofillHints: const [
                    AutofillHints
                        .newPassword,
                  ],

                  onFieldSubmitted:
                      (_) {
                    if (!_loading) {
                      _register();
                    }
                  },

                  decoration:
                      InputDecoration(
                    hintText:
                        'Confirm your password',

                    prefixIcon: const Icon(
                      Icons
                          .lock_outline_rounded,
                    ),

                    suffixIcon:
                        IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },

                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons
                                .visibility_outlined
                            : Icons
                                .visibility_off_outlined,
                      ),
                    ),
                  ),

                  validator:
                      _validateConfirmPassword,
                ),

                const SizedBox(
                  height: AppSpacing.xxl,
                ),

                // ==================================================
                // NEXT STEP INFO
                // ==================================================

                Container(
                  width: double.infinity,

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
                        CrossAxisAlignment.start,

                    children: [
                      Container(
                        width: 34,
                        height: 34,

                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            AppRadius.sm,
                          ),
                        ),

                        child: const Icon(
                          Icons
                              .business_center_outlined,
                          size: 18,
                          color:
                              AppColors.accent,
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
                              'Next: Business Setup',

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
                              'After creating your account, you will add your business, first branch and unique branch code.',

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
                  height: AppSpacing.xxl,
                ),

                // ==================================================
                // CREATE ACCOUNT BUTTON
                // ==================================================

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : _register,

                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.2,
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
                                'Create Account',
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
                  height: AppSpacing.lg,
                ),

                // ==================================================
                // LOGIN
                // ==================================================

                Center(
                  child: TextButton(
                    onPressed:
                        _loading
                            ? null
                            : () {
                                Navigator.of(
                                  context,
                                ).pop();
                              },

                    child: const Text(
                      'Already have an account? Sign in',
                    ),
                  ),
                ),

                const SizedBox(
                  height: AppSpacing.lg,
                ),

                // ==================================================
                // SECURITY
                // ==================================================

                Center(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons
                            .verified_user_outlined,
                        size: 16,
                        color:
                            AppColors.textMuted,
                      ),

                      const SizedBox(
                        width:
                            AppSpacing.sm,
                      ),

                      Text(
                        'Your account is securely protected',

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
        ),
      ),
    );
  }
}

// ================================================================
// SECTION HEADER
// ================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,

          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          subtitle,

          style: Theme.of(context)
              .textTheme
              .bodySmall,
        ),
      ],
    );
  }
}

// ================================================================
// FIELD LABEL
// ================================================================

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool requiredField;

  const _FieldLabel({
    required this.label,
    required this.requiredField,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Text(
          label,

          style: Theme.of(context)
              .textTheme
              .labelLarge,
        ),

        if (requiredField) ...[
          const SizedBox(
            width: 3,
          ),

          const Text(
            '*',

            style: TextStyle(
              color: AppColors.danger,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

