// learnflow_ai/flutter_app/lib/screens/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:learnflow_ai/services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _walletAddressController = TextEditingController();
  String _currentWalletAddress = 'Not set';
  double _tokenBalance = 0.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  @override
  void dispose() {
    _walletAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Fetch current student profile to get registered wallet address
      final student = await _apiService.fetchCurrentStudentProfile();
      if (student != null && student.walletAddress != null) {
        _currentWalletAddress = student.walletAddress!;
        _walletAddressController.text = _currentWalletAddress;
      } else {
        _currentWalletAddress = 'No wallet registered yet.';
      }

      // Fetch token balance
      final balanceResult = await _apiService.getLearnFlowTokenBalance();
      if (balanceResult['success']) {
        _tokenBalance = balanceResult['balance'];
      } else {
        _errorMessage = balanceResult['message'];
        _tokenBalance = 0.0;
      }
    } catch (e) {
      _errorMessage = 'Error loading wallet data: $e';
      _tokenBalance = 0.0;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerOrUpdateWallet() async {
    if (_walletAddressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a wallet address.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newAddress = _walletAddressController.text;
    Map<String, dynamic> result;

    // Check if a wallet is already registered
    final student = await _apiService.fetchCurrentStudentProfile();
    if (student != null && student.walletAddress != null && student.walletAddress!.isNotEmpty) {
      // Wallet exists, attempt to update
      result = await _apiService.updateWallet(newAddress);
    } else {
      // No wallet exists, attempt to register
      result = await _apiService.registerWallet(newAddress);
    }

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      await _loadWalletData(); // Reload data to show updated balance/address
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['message']}')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.deepPurple.shade800, // Darker purple for app bar
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade800, Colors.purple.shade600, Colors.purpleAccent.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(28.0), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 12, // More pronounced shadow
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded
                      margin: const EdgeInsets.only(bottom: 30), // Increased margin
                      color: Colors.white.withOpacity(0.95), // Slightly less opaque
                      child: Padding(
                        padding: const EdgeInsets.all(25.0), // Increased padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your LearnFlow Token (LFT) Balance:',
                              style: TextStyle(
                                fontSize: 20, // Larger font
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 15), // Increased spacing
                            Text(
                              '${_tokenBalance.toStringAsFixed(2)} LFT',
                              style: const TextStyle(
                                fontSize: 48, // Much larger balance font
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                shadows: [
                                  Shadow(blurRadius: 8.0, color: Colors.black38, offset: Offset(1.0, 1.0)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25), // Increased spacing
                            const Text(
                              'Registered Wallet Address:',
                              style: TextStyle(
                                fontSize: 18, // Larger font
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText( // Make address selectable for easy copying
                              _currentWalletAddress,
                              style: const TextStyle(
                                fontSize: 15, // Slightly larger
                                color: Colors.black87,
                                fontFamily: 'monospace', // Use monospace for addresses
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white.withOpacity(0.95),
                      child: Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentWalletAddress.startsWith('No wallet') ? 'Register Your Wallet' : 'Update Your Wallet Address',
                              style: const TextStyle(
                                fontSize: 22, // Larger font
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 25), // Increased spacing
                            TextField(
                              controller: _walletAddressController,
                              decoration: InputDecoration(
                                labelText: 'Ethereum Wallet Address (0x...)',
                                hintText: 'e.g., 0xAbc123...',
                                labelStyle: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.w500),
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.deepPurple.shade200, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2.5),
                                ),
                                filled: true,
                                fillColor: Colors.deepPurple.shade50.withOpacity(0.7),
                                prefixIcon: Icon(Icons.account_balance_wallet_rounded, color: Colors.deepPurple.shade400), // Rounded icon
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              ),
                              keyboardType: TextInputType.text,
                              maxLines: 1,
                              style: const TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                            const SizedBox(height: 30), // Increased spacing
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _registerOrUpdateWallet,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 24, // Larger loading indicator
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5, // Thicker stroke
                                      ),
                                    )
                                  : Icon(_currentWalletAddress.startsWith('No wallet') ? Icons.add_rounded : Icons.save_rounded, size: 28), // Rounded icons
                              label: Text(_currentWalletAddress.startsWith('No wallet') ? 'Register Wallet' : 'Update Wallet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent.shade700, // Richer blue
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40), // Larger button
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                elevation: 10,
                                shadowColor: Colors.black.withOpacity(0.6),
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Text(
                                  'Error: $_errorMessage',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
