import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  void _showOrgLoginDialog(AuthProvider auth) {
    final orgNameController = TextEditingController();
    final orgEmailController = TextEditingController();
    String selectedRole = 'Operator';
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.business, color: Color(0xFF3B82F6)),
                  SizedBox(width: 8),
                  Text('ASM Organization Login', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: orgNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.person, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: orgEmailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Organization Email',
                        hintText: 'yourname@asmltd.com',
                        hintStyle: const TextStyle(color: Color(0xFF475569)),
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.email, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Your Role:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    const SizedBox(height: 4),
                    ...['Operator', 'ShiftEngineer', 'Admin'].map((role) {
                      final label = role == 'ShiftEngineer' ? 'Shift Engineer' : role;
                      return RadioListTile<String>(
                        title: Text(label, style: const TextStyle(color: Colors.white)),
                        value: role,
                        groupValue: selectedRole,
                        activeColor: const Color(0xFF3B82F6),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedRole = val);
                        },
                      );
                    }),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(errorMsg!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final name = orgNameController.text.trim();
                    final email = orgEmailController.text.trim();
                    
                    if (name.isEmpty || email.isEmpty) {
                      setDialogState(() => errorMsg = 'Please fill in all fields.');
                      return;
                    }
                    if (!email.toLowerCase().endsWith('@asmltd.com')) {
                      setDialogState(() => errorMsg = 'Only @asmltd.com emails are allowed.');
                      return;
                    }
                    
                    Navigator.pop(dialogContext);
                    try {
                      await auth.loginWithOrgEmail(name, email, selectedRole);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Login failed: $e'), backgroundColor: const Color(0xFFEF4444)),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.precision_manufacturing, size: 64, color: Color(0xFF3B82F6)),
              const SizedBox(height: 16),
              const Text('ASM PMS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              if (!_isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              auth.isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_isLogin) {
                              auth.login(_usernameController.text, _passwordController.text);
                            } else {
                              auth.signup(_nameController.text, _usernameController.text, _passwordController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF3B82F6),
                          ),
                          child: Text(_isLogin ? 'LOGIN' : 'SIGN UP'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showOrgLoginDialog(auth),
                          icon: const Icon(Icons.business, size: 24),
                          label: const Text('Sign in with ASM Org Email'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin ? 'Create an account' : 'Back to Login'),
                            ),
                            if (_isLogin)
                              TextButton(
                                onPressed: () {
                                  if (_usernameController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter your email first to reset password')),
                                    );
                                    return;
                                  }
                                  auth.forgotPassword(_usernameController.text);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Password reset link sent to ${_usernameController.text}')),
                                  );
                                },
                                child: const Text('Forgot Password?'),
                              ),
                          ],
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
