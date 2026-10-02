import 'package:flutter/material.dart';
import 'package:verdelia_localizations/gen_l10n/app_localizations.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({super.key});

  @override
  State<PasswordChangeScreen> createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Replace with actual password change logic:
      // await AuthService.changePassword(
      //   currentPassword: _currentPasswordController.text,
      //   newPassword: _newPasswordController.text,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordChangeSuccess),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.changePassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Icon(
                Icons.lock_reset,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                loc.passwordChangeTitle,
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.passwordChangeSubtitle,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Current Password
              Text(
                loc.currentPassword,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  hintText: loc.currentPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.currentPasswordRequired;
                  }
                  if (value.length < 8) {
                    return loc.passwordTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // New Password
              Text(
                loc.newPassword,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  hintText: loc.newPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.newPasswordRequired;
                  }
                  if (value.length < 8) {
                    return loc.passwordTooShort;
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return loc.passwordUppercaseError;
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return loc.passwordNumberError;
                  }
                  if (value == _currentPasswordController.text) {
                    return loc.passwordSameAsCurrent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Password strength indicator
              LinearProgressIndicator(
                value: _calculatePasswordStrength(_newPasswordController.text),
                backgroundColor: Colors.grey[200],
                color: _getPasswordStrengthColor(_newPasswordController.text),
                minHeight: 4,
              ),
              const SizedBox(height: 4),
              Text(
                _getPasswordStrengthText(_newPasswordController.text),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getPasswordStrengthColor(_newPasswordController.text),
                ),
              ),
              const SizedBox(height: 12),

              // Confirm Password
              Text(
                loc.confirmPassword,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: loc.confirmPasswordHint,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return loc.confirmPasswordRequired;
                  }
                  if (value != _newPasswordController.text) {
                    return loc.passwordsDontMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary, // Button background color
                  foregroundColor: Theme.of(context)
                      .colorScheme
                      .onPrimary, // Text & icon color
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12), // optional
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(loc.changePasswordButton),
              ),
              const SizedBox(height: 16),

              // Password Requirements
              _buildPasswordRequirements(loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.passwordRequirements,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: _newPasswordController.text.length >= 8
                  ? Colors.green
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(loc.passwordLengthRequirement),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: RegExp(r'[A-Z]').hasMatch(_newPasswordController.text)
                  ? Colors.green
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(loc.passwordUppercaseRequirement),
          ],
        ),
        Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: RegExp(r'[0-9]').hasMatch(_newPasswordController.text)
                  ? Colors.green
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(loc.passwordNumberRequirement),
          ],
        ),
      ],
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;
    if (password.length >= 8) strength += 0.3;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.3;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.3;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength += 0.1;

    return strength.clamp(0.0, 1.0);
  }

  Color _getPasswordStrengthColor(String password) {
    final strength = _calculatePasswordStrength(password);
    if (strength < 0.4) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  String _getPasswordStrengthText(String password) {
    final strength = _calculatePasswordStrength(password);
    if (password.isEmpty) return '';
    if (strength < 0.4) return AppLocalizations.of(context)!.weakPassword;
    if (strength < 0.7) return AppLocalizations.of(context)!.mediumPassword;
    return AppLocalizations.of(context)!.strongPassword;
  }
}
