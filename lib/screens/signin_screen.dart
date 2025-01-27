import 'package:flutter/material.dart';
import 'package:pawnetwork/color_utils.dart';
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body:Container(decoration: BoxDecoration(gradient:LinearGradient(colors:[
      hexStringToColor("CB2B93"),
      hexStringToColor("CB2B93"),
      hexStringToColor("CB2B93"),
    ]
     ))));
  }
}
