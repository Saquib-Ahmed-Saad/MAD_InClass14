import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/fcm_service.dart';
import '../../data/services/auth_service.dart';
import 'authentication_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.messagingController,
  });

  final AuthService authService;
  final FCMController messagingController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  bool _updatingPassword = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ValueListenableBuilder<FCMStatus>(
        valueListenable: widget.messagingController,
        builder: (BuildContext context, FCMStatus status, _) {
          final accentColor = _accentColorFor(context, status.lastMessage);
          final accentIcon = _accentIconFor(status.lastMessage);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Signed in as',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentUser?.email ?? 'No email found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.cloud_done_outlined, color: accentColor),
                            const SizedBox(width: 8),
                            Text(
                              'Cloud Messaging Monitor',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Permission: ${_permissionLabel(status.permissionStatus)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${status.connectionState}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Current FCM token',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          status.token ?? 'Fetching token...',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(24),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentColor.withAlpha(80),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    backgroundColor: accentColor.withAlpha(32),
                                    foregroundColor: accentColor,
                                    child: Icon(accentIcon),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          status.lastMessage?.title ??
                                              'Waiting for a cloud message',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          status.lastMessage?.body ??
                                              'Send a Firebase Console test message to this token to prove foreground, background, or terminated handling.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  Chip(
                                    avatar: const Icon(
                                      Icons.route_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Handler: ${status.lastMessage?.source.label ?? 'Not hit yet'}',
                                    ),
                                  ),
                                  Chip(
                                    avatar: const Icon(
                                      Icons.palette_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'asset=${status.lastMessage?.assetKey ?? 'default'}',
                                    ),
                                  ),
                                  Chip(
                                    avatar: const Icon(
                                      Icons.bolt_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'action=${status.lastMessage?.actionKey ?? 'none'}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Payload: ${status.lastMessage?.payloadSummary ?? 'No message payload received yet'}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Message id: ${status.lastMessage?.messageId ?? 'No message yet'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Update Password',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New password',
                            ),
                            validator: (String? value) {
                              if (value == null || value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _updatingPassword
                                ? null
                                : _handlePasswordChange,
                            child: _updatingPassword
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Change Password'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _permissionLabel(AuthorizationStatus status) {
    return switch (status) {
      AuthorizationStatus.authorized => 'authorized',
      AuthorizationStatus.denied => 'denied',
      AuthorizationStatus.notDetermined => 'not determined',
      AuthorizationStatus.provisional => 'provisional',
    };
  }

  Color _accentColorFor(BuildContext context, FCMMessagePayload? message) {
    return switch (message?.assetKey) {
      'promo' => Colors.deepOrange,
      'sale' => Colors.pink,
      'offer' => Colors.teal,
      'warning' => Colors.amber.shade800,
      _ => Theme.of(context).colorScheme.primary,
    };
  }

  IconData _accentIconFor(FCMMessagePayload? message) {
    return switch (message?.actionKey) {
      'show_animation' => Icons.play_circle_fill_rounded,
      'open_offer' => Icons.local_activity_rounded,
      'show_offer' => Icons.local_offer_rounded,
      _ => Icons.notifications_active_outlined,
    };
  }

  Future<void> _handlePasswordChange() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _updatingPassword = true);

    try {
      await widget.authService.changePassword(_newPasswordController.text);
      if (!mounted) {
        return;
      }
      _newPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      final fallback = error.code == 'requires-recent-login'
          ? 'Please sign in again, then try changing your password.'
          : 'Could not update password.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message ?? fallback)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error while updating password'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingPassword = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await widget.authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AuthenticationScreen(
            messagingController: widget.messagingController,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign out failed. Please try again.')),
      );
    }
  }
}
