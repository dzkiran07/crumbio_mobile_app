import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/api/api_endpoint.dart';

class KhaltiWebviewScreen extends StatefulWidget {
  final String paymentUrl;

  const KhaltiWebviewScreen({super.key, required this.paymentUrl});

  @override
  State<KhaltiWebviewScreen> createState() => _KhaltiWebviewScreenState();
}

class _KhaltiWebviewScreenState extends State<KhaltiWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _returnHandled = false;

  bool _isReturnUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;
    final returnUri = Uri.parse(ApiEndpoints.khaltiReturnUrl);
    return uri.host == returnUri.host && uri.path == returnUri.path;
  }

  void _finishAsReturned() {
    if (_returnHandled || !mounted) return;
    _returnHandled = true;
    Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            if (_isReturnUrl(request.url)) {
              _finishAsReturned();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khalti Checkout'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
