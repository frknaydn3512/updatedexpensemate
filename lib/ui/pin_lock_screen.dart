import 'package:flutter/material.dart';

class PinLockScreen extends StatefulWidget {
  final String savedPin;
  final VoidCallback onSuccess;

  const PinLockScreen({
    Key? key,
    required this.savedPin,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  void _onNumpadChanged() {
    setState(() {
      _errorText = null;
    });
    if (_pinController.text.length == 4) {
      _checkPin();
    }
  }

  void _checkPin() async {
    setState(() {
      _isLoading = true;
    });

    // Kısa bir gecikme ekleyerek animasyon efekti verelim
    await Future.delayed(const Duration(milliseconds: 300));

    if (_pinController.text == widget.savedPin) {
      // Başarılı giriş animasyonu
      setState(() {
        _isLoading = false;
      });
      widget.onSuccess();
    } else {
      // Hata animasyonu
      setState(() {
        _errorText = 'Yanlış PIN!';
        _isLoading = false;
      });
      
      // Hata animasyonu için controller'ı sallayalım
      _pinController.clear();
      
      // Hata mesajını 3 saniye sonra temizle
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorText = null;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onNumpadChanged);
  }

  @override
  void dispose() {
    _pinController.removeListener(_onNumpadChanged);
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Koyu tema
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Üst kısım - Logo ve başlık
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon/logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PIN Kilidi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Güvenliğiniz için PIN kodunuzu girin',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Orta kısım - PIN göstergesi
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // PIN noktaları
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        bool filled = i < _pinController.text.length;
                        bool isError = _errorText != null && filled;
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isError 
                                ? Colors.red 
                                : filled 
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey[600],
                            boxShadow: filled ? [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                        );
                      }),
                    ),
                    
                    // Hata mesajı
                    if (_errorText != null) ...[
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _errorText!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Loading indicator
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Alt kısım - Custom Numpad
              Expanded(
                flex: 3,
                child: _CustomNumpad(
                  controller: _pinController,
                  onEnter: _checkPin,
                  isDisabled: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomNumpad extends StatelessWidget {
  final TextEditingController controller;
  final Function() onEnter;
  final bool isDisabled;

  const _CustomNumpad({
    required this.controller,
    required this.onEnter,
    this.isDisabled = false,
  });

  Widget _buildKeypadButton(BuildContext context, Widget child, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          elevation: 4,
          minimumSize: const Size(60, 60),
          fixedSize: const Size(60, 60),
          disabledBackgroundColor: Colors.grey[700],
          disabledForegroundColor: Colors.grey[500],
        ),
        onPressed: isDisabled ? null : onPressed,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          // 1. Satır
          _buildNumberButton(context, '1'),
          _buildNumberButton(context, '2'),
          _buildNumberButton(context, '3'),
          // 2. Satır
          _buildNumberButton(context, '4'),
          _buildNumberButton(context, '5'),
          _buildNumberButton(context, '6'),
          // 3. Satır
          _buildNumberButton(context, '7'),
          _buildNumberButton(context, '8'),
          _buildNumberButton(context, '9'),
          // 4. Satır: biometrik, 0, backspace
          _buildBiometricButton(context),
          _buildNumberButton(context, '0'),
          _buildBackspaceButton(context),
        ],
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return _buildKeypadButton(
      context,
      Text(
        number,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
      () {
        if (controller.text.length < 4) {
          controller.text += number;
        }
      },
    );
  }

  Widget _buildBiometricButton(BuildContext context) {
    return _buildKeypadButton(
      context,
      const Icon(Icons.fingerprint, size: 28),
      () {
        // Biyometrik kimlik doğrulama (gelecekte eklenebilir)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biyometrik kimlik doğrulama yakında eklenecek'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildBackspaceButton(BuildContext context) {
    return _buildKeypadButton(
      context,
      const Icon(Icons.backspace_outlined, size: 24),
      () {
        if (controller.text.isNotEmpty) {
          controller.text = controller.text.substring(0, controller.text.length - 1);
        }
      },
    );
  }
} 