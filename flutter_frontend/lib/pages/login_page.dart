import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../widgets/frosted_glass_button.dart';
import '../widgets/frosted_glass_textfield.dart';
import '../themes/colors.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _usernameCtl, _passwordCtl;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _usernameCtl = TextEditingController();
    _passwordCtl = TextEditingController();
  }

  Future<void> _login() async {
    if (_usernameCtl.text.isEmpty || _passwordCtl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final res = await apiClient.post('/login', {
        'username': _usernameCtl.text,
        'password': _passwordCtl.text,
      });
      final token = res['token'];
      await storage.write(key: 'token', value: token);
      apiClient.token = token;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_usernameCtl.text.isEmpty || _passwordCtl.text.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final res = await apiClient.post('/signup', {
        'username': _usernameCtl.text,
        'password': _passwordCtl.text,
      });
      final token = res['token'];
      await storage.write(key: 'token', value: token);
      apiClient.token = token;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  border: Border.all(color: kTextLight, width: 2),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: Text('🛒', style: TextStyle(fontSize: 36)),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Grocery AI',
                style: TextStyle(
                  fontFamily: 'StackSansNotch',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Smart Shopping Assistant',
                style: TextStyle(
                  fontSize: 14,
                  color: kTextGray,
                  fontFamily: 'StackSansText',
                ),
              ),
              SizedBox(height: 48),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextDark,
                    fontFamily: 'StackSans',
                  ),
                ),
              ),
              SizedBox(height: 8),
              FrostedGlassTextField(
                controller: _usernameCtl,
                placeholder: 'Enter your username',
                enabled: !_isLoading,
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextDark,
                    fontFamily: 'StackSans',
                  ),
                ),
              ),
              SizedBox(height: 8),
              FrostedGlassTextField(
                controller: _passwordCtl,
                placeholder: 'Enter your password',
                obscureText: true,
                enabled: !_isLoading,
              ),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 12,
                    color: kPrimary,
                    decoration: TextDecoration.underline,
                    fontFamily: 'StackSansText',
                  ),
                ),
              ),
              SizedBox(height: 24),
              if (_errorMsg != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: TextStyle(
                      fontSize: 12,
                      color: kErrorRed,
                      fontFamily: 'StackSansText',
                    ),
                  ),
                ),
              SizedBox(height: 24),
              FrostedGlassButton(
                label: _isLoading ? 'Logging In...' : 'Log In',
                onPressed: _isLoading ? null : _login,
                isPrimary: true,
              ),
              SizedBox(height: 12),
              FrostedGlassButton(
                label: _isLoading ? 'Creating...' : 'Create Account',
                onPressed: _isLoading ? null : _signup,
                isPrimary: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }
}
