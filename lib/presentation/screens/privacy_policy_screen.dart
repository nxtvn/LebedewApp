import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/platform/platform_helper.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  static const String privacyPolicyUrl = 'https://lebedew.de/datenschutz/';

  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
  
  /// Öffnet die Datenschutzrichtlinie im externen Browser
  static Future<void> openInBrowser() async {
    final Uri url = Uri.parse(privacyPolicyUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Konnte die URL nicht öffnen: $url');
    }
  }
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Fehler beim Laden der Seite: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(PrivacyPolicyScreen.privacyPolicyUrl));
  }

  @override
  Widget build(BuildContext context) {
    return PlatformHelper.isIOS() ? _buildIOSLayout() : _buildAndroidLayout();
  }

  Widget _buildAndroidLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datenschutzerklärung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => PrivacyPolicyScreen.openInBrowser(),
            tooltip: 'Im Browser öffnen',
          ),
        ],
      ),
      body: _buildWebViewContent(),
    );
  }

  Widget _buildIOSLayout() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Datenschutzerklärung'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.globe),
          onPressed: () => PrivacyPolicyScreen.openInBrowser(),
        ),
      ),
      child: _buildWebViewContent(),
    );
  }

  Widget _buildWebViewContent() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            PlatformHelper.isIOS()
                ? CupertinoButton.filled(
                    child: const Text('Erneut versuchen'),
                    onPressed: () {
                      _controller.reload();
                    },
                  )
                : ElevatedButton(
                    onPressed: () {
                      _controller.reload();
                    },
                    child: const Text('Erneut versuchen'),
                  ),
            const SizedBox(height: 16),
            PlatformHelper.isIOS()
                ? CupertinoButton(
                    child: const Text('Im Browser öffnen'),
                    onPressed: () => PrivacyPolicyScreen.openInBrowser(),
                  )
                : TextButton(
                    onPressed: () => PrivacyPolicyScreen.openInBrowser(),
                    child: const Text('Im Browser öffnen'),
                  ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          Center(
            child: PlatformHelper.isIOS()
                ? const CupertinoActivityIndicator(radius: 16)
                : const CircularProgressIndicator(),
          ),
      ],
    );
  }
} 