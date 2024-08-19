import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'api_service.dart'; // Import ApiService ที่เราสร้างขึ้น
import 'hms.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final FocusNode _buttonFocusNode = FocusNode();
  bool isLoading = false;
  bool _isObscure = true;

  final maskFormatter = MaskTextInputFormatter(
    mask: '##-##-######',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();

    _buttonFocusNode.addListener(() {
      if (_buttonFocusNode.hasFocus) {
        _buttonFocusNode.consumeKeyboardToken();
      }
    });
  }

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (isLoading) return;
    if (!_formKey.currentState!.validate()) {
      _showDialog('Validation Error', 'Please fill out all fields.');
      return;
    }

    setState(() => isLoading = true);
    final apiService = ApiService(); // Create an instance of ApiService

    try {
      await Future.delayed(const Duration(seconds: 2));
      final jsonResponse = await apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      final userlogin = jsonResponse['userlogin'];
      if (userlogin is List && userlogin.isNotEmpty) {
        final visitId = userlogin[0]['visit_id'];
        final hn = userlogin[0]['hn'];
        if (visitId != null && hn != null) {
          _navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
                builder: (context) => HomeMedSheet(visitId: visitId, hn: hn)),
          );
        }
      } else {
        _showDialog('Login Failed!', 'Invalid Username or Password');
      }
    } catch (e) {
      _showDialog('Error', 'An error occurred: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content, style: const TextStyle(fontSize: 20)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      onGenerateRoute: (setting) => MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/login.png', width: 200, height: 150),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                          hintText: "กรุณากรอกหมายเลข HN",
                          labelText: 'Username'),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your HN' : null,
                      inputFormatters: [maskFormatter],
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Please enter your HN number here.'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText:
                          _isObscure, // ใช้ _isObscure เพื่อควบคุมการแสดงของรหัสผ่าน
                      decoration: InputDecoration(
                        hintText: "กรุณากรอกหมายเลข 4 ตัวท้าย",
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isObscure =
                                  !_isObscure; // เปลี่ยนสถานะรหัสผ่าน (แสดงหรือซ่อน)
                            });
                          },
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'กรุณากรอกหมายเลข 4 ตัวท้าย' : null,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: const TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  'กรอกหมายเลข 4 ตัวท้ายหลังบัตรประชาชน หรือ วันเดือนปีเกิด\n',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'เช่น ปปปปดดวว\n',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Please enter the last 4 digits of your Passport or your Birthday.\n',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'Ex. yyyymmdd',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      focusNode: _buttonFocusNode,
                      onPressed: isLoading ? null : () => _login(),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12)),
                      child: isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  CircularProgressIndicator(
                                      color: Colors.white),
                                  SizedBox(width: 24),
                                  Text('Please Wait...'),
                                ])
                          : const Text('Login',
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
