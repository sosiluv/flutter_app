import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_app/screens/auth_screen.dart';

main(){
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    home: FirstLoading(),
  ));
}

class FirstLoading extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if(snapshot.hasError){
          return HasError();
        }
        if(snapshot.connectionState == ConnectionState.done){
          return AuthScreen();
          // return AuthScreenBuilder();
        }
        return Splash();
      },
    );
  }
}
class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Align(
            child: Text('로 딩 중'),
          )
      ),
    );
  }
}



class HasError extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('에러 발생')
          ],
        ),
      ),
    );
  }
}