import 'package:flutter/material.dart';

main(){
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FirstLoading());
}

class FirstLoading extends StatelessWidget{



  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return FutureBuilder(
        builder: (context, snapshot) {

        },
    )
  }}

