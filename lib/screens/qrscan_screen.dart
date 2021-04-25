import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QrScanScreen extends StatefulWidget {
  @override
  _QrScanScreenState createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  Barcode result;
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QrScan'),
      ),
      body: Column(
        children: [
          Expanded(
              flex: 4,
              child: _buildQrView(context)
          ),
          Expanded(
              flex: 1,
              child: Column(
                children: [
                  if(result != null)
                    Text('Date : ${result.code}'),

                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: (){
                            controller.toggleFlash();
                          },
                          child: Text('Flash')
                      ),
                      ElevatedButton(
                          onPressed: (){
                            controller.flipCamera();
                          },
                          child: Text('flipCamera')
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: (){
                            controller.pauseCamera();
                          },
                          child: Text('pausedCamera')
                      ),
                      ElevatedButton(
                          onPressed: (){
                            controller.resumeCamera();
                          },
                          child: Text('resumeCamera')
                      ),
                    ],
                  )
                ],
              )
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context){
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQrViewCreated,
      overlay: QrScannerOverlayShape(
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 200
      ),
    );
  }
  _onQrViewCreated(QRViewController controller){
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }
}