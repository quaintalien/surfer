import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebViewApp(
        title: "Test",
      ),
    );
  }
}

// class WebViewExample extends StatefulWidget {
//   const WebViewExample({Key? key}) : super(key: key);
//
//   @override
//   WebViewExampleState createState() => WebViewExampleState();
// }
//
// class WebViewExampleState extends State<WebViewExample> {
//   @override
//   void initState() {
//     super.initState();
//     // Enable hybrid composition.
//     if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     const jsChannels = <JavascriptChannel>{};
//
//     const webView = WebView(
//         initialUrl: 'http://10.0.2.2:1234',
//         javascriptMode: JavascriptMode.unrestricted,
//         javascriptChannels: jsChannels);
//
//     return const SafeArea(
//       child: Opacity(
//         opacity: 1.0,
//         child: webView,
//       ),
//     );
//   }
// }

enum MessageHandlers {
  loginSuccess,
  registerSuccess,
  socialLogin,
  customEvent,
}

extension ParseToString on MessageHandlers {
  String toShortString() {
    return toString().split('.').last;
  }
}

class WebViewApp extends StatefulWidget {
  const WebViewApp({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _WebViewAppState createState() => _WebViewAppState();
}

class _WebViewAppState extends State<WebViewApp> {
  late WebViewController webViewController;

  Future<void> loadHtmlFromAssets(String filename, controller) async {
    String fileText = await rootBundle.loadString(filename);
    controller.loadUrl(Uri.dataFromString(fileText,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString());
  }

  Future<String> loadLocal() async {
    return await rootBundle.loadString('assets/html/index.html');
  }

  @override
  Widget build(BuildContext context) {
    final jsBridgeInitialScript = "window.PianoIDMobileSDK={};" +
        "window.PianoIDMobileSDK.${MessageHandlers.loginSuccess.toShortString()}=" +
        "function(body){try{webkit.messageHandlers.${MessageHandlers.loginSuccess.toShortString()}.postMessage(body)}catch(err){console.log(err)}};" +
        "window.PianoIDMobileSDK.${MessageHandlers.registerSuccess.toShortString()}=" +
        "function(body){try{webkit.messageHandlers.${MessageHandlers.registerSuccess.toShortString()}.postMessage(body)}catch(err){console.log(err)}};" +
        "window.PianoIDMobileSDK.${MessageHandlers.socialLogin.toShortString()}=" +
        "function(body){try{webkit.messageHandlers.${MessageHandlers.socialLogin.toShortString()}.postMessage(body)}catch(err){console.log(err)}};" +
        "window.PianoIDMobileSDK.${MessageHandlers.customEvent.toShortString()}=" +
        "function(body){try{webkit.messageHandlers.${MessageHandlers.customEvent.toShortString()}.postMessage(body)}catch(err){console.log(err)}};";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<String>(
        future: loadLocal(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                ElevatedButton(
                    onPressed: () {
                      webViewController.runJavascriptReturningResult("webkit;");
                    },
                    child: const Text("Reload")),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: WebView(
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    initialUrl: Uri.dataFromString(snapshot.data!,
                            mimeType: 'text/html')
                        .toString(),
                    javascriptMode: JavascriptMode.unrestricted,
                    javascriptChannels: <JavascriptChannel>{
                      JavascriptChannel(
                          name: 'PianoSDK',
                          onMessageReceived: (s) {
                            Scaffold.of(context).showSnackBar(SnackBar(
                              content: Text(s.message),
                            ));
                          }),
                    },
                  ),
                )
              ],
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const CircularProgressIndicator();
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
