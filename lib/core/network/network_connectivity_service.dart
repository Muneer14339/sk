import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<List<ConnectivityResult>>
      _connectivityChangedController =
      StreamController<List<ConnectivityResult>>.broadcast();

  bool _isDialogShowing = false;
  bool _isInitialized = false;
  BuildContext? _context;

  void initialize(BuildContext context) {
    debugPrint('NetworkConnectivityService: Initializing...');
    if (_isInitialized) {
      debugPrint('NetworkConnectivityService: Already initialized');
      return;
    }

    _context = context;
    _isInitialized = true;

    debugPrint('NetworkConnectivityService: Setting up connectivity listener');
    // Listen to connectivity changes with error handling
    _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        debugPrint('NetworkConnectivityService: Connectivity error: $error');
      },
      onDone: () =>
          debugPrint('NetworkConnectivityService: Connectivity stream closed'),
    );

    debugPrint(
        'NetworkConnectivityService: Performing initial connectivity check');
    // Initial check
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    debugPrint('NetworkConnectivityService: Checking initial connection...');
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      debugPrint(
          'NetworkConnectivityService: Initial connectivity result: $connectivityResult');
      await _updateConnectionStatus(connectivityResult);
    } catch (e) {
      debugPrint(
          'NetworkConnectivityService: Error checking initial connection: $e');
    }
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    debugPrint(
        'NetworkConnectivityService: Connection status changed: $result');

    if (!_isInitialized) {
      debugPrint(
          'NetworkConnectivityService: Not initialized, skipping update');
      return;
    }

    final context = _context;
    if (context == null) {
      debugPrint('NetworkConnectivityService: No context available');
      return;
    }

    final isConnected = !result.contains(ConnectivityResult.none);
    debugPrint('NetworkConnectivityService: isConnected: $isConnected');

    // Ensure we're in a valid context
    if (!context.mounted) {
      debugPrint('NetworkConnectivityService: Context is not mounted');
      return;
    }

    if (!isConnected) {
      debugPrint('NetworkConnectivityService: No internet, showing dialog');
      _showNoInternetDialog();
    } else {
      debugPrint(
          'NetworkConnectivityService: Internet available, dismissing dialog');
      _dismissDialog();
    }

    // Always notify listeners
    if (!_connectivityChangedController.isClosed) {
      _connectivityChangedController.add(result);
    }
  }

  void _showNoInternetDialog() {
    debugPrint('NetworkConnectivityService: Showing no internet dialog');

    if (_isDialogShowing) {
      debugPrint('NetworkConnectivityService: Dialog already showing');
      return;
    }

    final context = _context;
    if (context == null) {
      debugPrint('NetworkConnectivityService: No context available for dialog');
      return;
    }

    if (!context.mounted) {
      debugPrint('NetworkConnectivityService: Context not mounted for dialog');
      return;
    }

    _isDialogShowing = true;

    // Show a proper dialog that blocks interaction with the app
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) => WillPopScope(
        onWillPop: () async => false, // Prevent dismissing with back button
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.signal_wifi_off,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Trying to reconnect...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      // This will be called when the dialog is dismissed
      _isDialogShowing = false;
    });
  }

  void _dismissDialog() {
    if (!_isDialogShowing) return;

    final context = _context;
    if (context != null && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _isDialogShowing = false;
  }

  void dispose() {
    _dismissDialog();
    if (!_connectivityChangedController.isClosed) {
      _connectivityChangedController.close();
    }
    _context = null;
    _isInitialized = false;
  }

  // Getter for connectivity changes stream
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivityChangedController.stream;
}
