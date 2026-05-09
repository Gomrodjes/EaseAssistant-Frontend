import 'package:flutter/material.dart';

class Measures {

  static Size size(BuildContext context) => MediaQuery.of(context).size;

  static double width(BuildContext context) => MediaQuery.of(context).size.width;

  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  static double scale(BuildContext context) => MediaQuery.of(context).size.width / 400;

}