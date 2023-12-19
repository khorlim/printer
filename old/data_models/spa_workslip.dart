import 'package:flutter/material.dart';

import 'print_data.dart';

class SpaWorkSlipData extends PrintData {
  final String memberName;
  final String staffName;
  final String memberMobile;
  final String roomName;
  final String issuedDate;
  List<String> services;
  final String timeString;
 

  SpaWorkSlipData({
   required this.memberName,
   required this.staffName,
   required this.memberMobile,
   required this.roomName,
   required this.issuedDate,
   required this.services,
   required this.timeString,
   
  });
}
