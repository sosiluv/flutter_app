import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/storage_main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';

enum _SupportState{unknown, supported, unsupported}
enum _LocalAuthState {not, ing, err, pass}
enum _FirebaseAuthState {not, ing, err, pass}

class AuthScreenBuilder extends StatelessWidget {
  final LocalAuthentication auth = LocalAuthentication();

  Future<_SupportState> supportHandler() async {
    bool isSupported = await auth.isDeviceSupported();
    if(isSupported){
      return _SupportState.supported;
    } else {
      return _SupportState.unsupported;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: supportHandler(),
        builder: (context,AsyncSnapshot<_SupportState> snapshot) {
          if(snapshot.data == _SupportState.supported){
            return AuthScreen();
          } else if(snapshot.data == _SupportState.unsupported){
            return NoSupport();
          } else {
            return Container();
          }
        },
      ),
    );
  }
}

class NoSupport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Align(
          child: Text('No Support!'),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  _LocalAuthState _localAuthState = _LocalAuthState.not;
  _FirebaseAuthState _firebaseAuthState = _FirebaseAuthState.not;
  int ignoreLocalAuth = 0;

  requestPermission() async {
    if(await Permission.camera.isDenied){
      await Permission.camera.request();
    }
    if(await Permission.storage.isDenied){
      await Permission.storage.request();
    }
    _authenticate();
  }

  Future<void> _authenticate() async{
    if(await Permission.storage.isDenied || await Permission.camera.isDenied){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('카메라 와 저장소 권한을요청해 주세요'),
        duration: Duration(seconds: 1),
      ));
      await Future.delayed(Duration(seconds: 1));
      openAppSettings();
      return null;
    }
    print('Local Auth going');

    bool authenticated = false;
    try{
      print('local auth true start');
      setState(() {
        _localAuthState = _LocalAuthState.ing;
      });
      authenticated = await auth.authenticate(
          androidAuthStrings: AndroidAuthMessages(
              signInTitle: '사인인타이틀',
              biometricHint: '바이오매트릭스힌트'
          ),
          localizedReason: '인증 방식을 선택해 주세요 !',
          useErrorDialogs: true,
          stickyAuth: true
      );
    } on PlatformException catch (e){
      print(e);
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('오류방생!'),
            content: Text('$e'),
          );
        },
      );
      setState(() {
        _localAuthState = _LocalAuthState.err;
      });
      return;
    }
    if(!mounted) return;
    setState(() {
      authenticated ? _localAuthState = _LocalAuthState.pass : _localAuthState = _LocalAuthState.not;
    });

    if(_localAuthState == _LocalAuthState.pass){
      setState(() {
        _firebaseAuthState = _FirebaseAuthState.not;
      });
      signInWithGoogle();
    }
  }

  Future<void> signInWithGoogle() async{
    setState(() {
      _firebaseAuthState = _FirebaseAuthState.ing;
    });
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
    googleUser.authentication.then((value){
      print('value. idToken ${value.idToken}');
    });
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,idToken: googleAuth.idToken
    );
    UserCredential myFirebase = await FirebaseAuth.instance.signInWithCredential(credential);

    if(myFirebase.credential == null){
      setState(() {
        _firebaseAuthState = _FirebaseAuthState.not;
      });
    } else {
      setState(() {
        _firebaseAuthState = _FirebaseAuthState.pass;
      });
    }

    if(_firebaseAuthState == _FirebaseAuthState.pass){
      Timer(Duration(milliseconds: 500),(){
        print('navigated to main');
        Navigator.pushReplacement(
            context, MaterialPageRoute(
          builder: (context) {
            return StorageMain();
          },));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment(0, 0.8),
            child: InkWell(
              onLongPress: () {
                print('local - Auth - Start');
                _authenticate();
              },
              onTap: (){
                Timer(Duration(seconds: 1),() => ignoreLocalAuth = 0);
                ignoreLocalAuth++;
                if(ignoreLocalAuth > 5){
                  signInWithGoogle();
                }
              },
              child: Icon(
                Icons.fingerprint,
                size:  100,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if(_localAuthState == _LocalAuthState.pass)
                  Text('로컬 인증 성공!')
                else if(_localAuthState == _LocalAuthState.not)
                  Text('인증을 진행해 주세요')
                else if(_localAuthState == _LocalAuthState.err)
                    Text('LocalAuthErr.')
                  else if(_localAuthState == _LocalAuthState.ing)
                      Text('로컬 인증 중...'),

                if(_firebaseAuthState == _FirebaseAuthState.pass)
                  Text('파이어 베이스 인증 성공!')
                else if(_firebaseAuthState == _FirebaseAuthState.ing)
                  Text('파이어 베이스 인증 중!')
              ],
            ),
          )
        ],
      ),
    );
  }
}