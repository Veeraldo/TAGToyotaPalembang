import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tagtoyota/screen/home_screen.dart';
import 'package:tagtoyota/screen/signin_screen.dart';
import 'package:tagtoyota/screen/signup_screen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: StreamBuilder(stream: FirebaseAuth.instance.authStateChanges(), 
    builder:(context, snapshot){
      print("DEBU AUTH : ${snapshot.data}");
      if(snapshot.connectionState == ConnectionState.waiting){
        return Center(
          child: CircularProgressIndicator(),
        );
      }else if(snapshot.hasError){
        return Center(child: Text("Error"),
        );
      }else{
        if(snapshot.data == null){
          return SignInScreen();
        }else{
          return HomeScreen();
        }
      }
    },),);
  }
}