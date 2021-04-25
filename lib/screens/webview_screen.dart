import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    if(Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: WebView(
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (controller) {
                    _controller.complete(controller);
                  },
                  initialUrl: 'https://flutter.dev',
                )
            ),
            FutureBuilder(
              future: _controller.future,
              builder: (context,AsyncSnapshot<WebViewController> snapshot) {
                final webViewReady = snapshot.connectionState == ConnectionState.done;
                final controller = snapshot.data;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: webViewReady ? () async{
                          if(await controller.canGoForward()){
                            await controller.goForward();
                          } else {
                            print('history 없음');
                          }
                        }: null
                    ),
                    IconButton(icon: Icon(
                        Icons.refresh),
                      onPressed: webViewReady ? (){
                        controller.reload();
                      } : null,
                    ),
                    IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed:webViewReady ? () async{
                          if(await controller.canGoBack()){
                            await controller.goBack();
                          }
                        }: null
                    ),
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }
}