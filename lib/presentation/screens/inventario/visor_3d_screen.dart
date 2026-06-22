import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class Visor3DScreen extends StatefulWidget {
  final String modelo3dUrl;
  final String productoNombre;

  const Visor3DScreen({
    Key? key,
    required this.modelo3dUrl,
    required this.productoNombre,
  }) : super(key: key);

  @override
  State<Visor3DScreen> createState() => _Visor3DScreenState();
}

class _Visor3DScreenState extends State<Visor3DScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Visor 3D</title>
  <!-- Import the model-viewer element -->
  <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js"></script>
  <style>
    body {
      margin: 0;
      padding: 0;
      width: 100vw;
      height: 100vh;
      overflow: hidden;
      background-color: #f5f6fa;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    model-viewer {
      width: 100%;
      height: 100%;
      background-color: #f5f6fa;
      --poster-color: transparent;
    }
    /* Estilo premium para el botón de Realidad Aumentada */
    .ar-button {
      background-color: #1565C0;
      color: white;
      border: none;
      border-radius: 30px;
      padding: 14px 28px;
      font-size: 15px;
      font-weight: 600;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      box-shadow: 0 4px 20px rgba(21, 101, 192, 0.4);
      position: absolute;
      bottom: 30px;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      cursor: pointer;
      z-index: 999;
      transition: background-color 0.2s, transform 0.2s;
      -webkit-tap-highlight-color: transparent;
    }
    .ar-button:active {
      background-color: #0d47a1;
      transform: translateX(-50%) scale(0.95);
    }
    .ar-icon {
      width: 20px;
      height: 20px;
      fill: none;
      stroke: currentColor;
      stroke-width: 2;
      stroke-linecap: round;
      stroke-linejoin: round;
    }
    /* Spinner de carga */
    #lazy-load-poster {
      position: absolute;
      left: 0;
      right: 0;
      top: 0;
      bottom: 0;
      background-color: #f5f6fa;
      display: flex;
      justify-content: center;
      align-items: center;
      z-index: 100;
      transition: opacity 0.5s;
    }
    .spinner {
      border: 4px solid rgba(0, 0, 0, 0.05);
      width: 40px;
      height: 40px;
      border-radius: 50%;
      border-left-color: #1565C0;
      animation: spin 1s linear infinite;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div id="lazy-load-poster">
    <div class="spinner"></div>
  </div>

  <model-viewer
    src="${widget.modelo3dUrl}"
    alt="${widget.productoNombre}"
    ar
    ar-modes="webxr scene-viewer quick-look"
    camera-controls
    auto-rotate
    interaction-prompt="auto"
    shadow-intensity="1.5"
    shadow-softness="1"
    exposure="1"
    environment-image="neutral"
    loading="eager">
    
    <button slot="ar-button" class="ar-button">
      <svg class="ar-icon" viewBox="0 0 24 24">
        <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
        <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
        <line x1="12" y1="22.08" x2="12" y2="12"></line>
      </svg>
      Ver en Realidad Aumentada (AR)
    </button>
  </model-viewer>

  <script>
    const modelViewer = document.querySelector('model-viewer');
    const poster = document.querySelector('#lazy-load-poster');
    
    modelViewer.addEventListener('load', () => {
      poster.style.opacity = '0';
      setTimeout(() => poster.style.display = 'none', 500);
      // Notificar a Flutter que terminó de cargar si fuera necesario
    });
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.bgColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;
            if (url.startsWith('intent://')) {
              // Convert intent:// to https://
              String httpsUrl = url.replaceFirst('intent://', 'https://');
              
              // Extract and clean Intent variables (Chrome handles this best natively)
              final intentIndex = httpsUrl.indexOf('#Intent;');
              if (intentIndex != -1) {
                httpsUrl = httpsUrl.substring(0, intentIndex);
              }

              try {
                final Uri uri = Uri.parse(httpsUrl);
                // Launch in external app (system browser like Chrome)
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No se pudo abrir el visor AR: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text('${widget.productoNombre} - Vista 3D'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
