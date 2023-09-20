import 'package:flutter/material.dart';

import 'print_data.dart';

class CarReceiptData extends PrintData {
  final String shopName;
  final String shopIcon;
  final String address;
  final String receiptID;
  final String invNo;
  final String salesDate;
  final String issuedDate;
  final String cashierName;
  final String staffName;
  final String mobile;
  final String location;
  final String carPlate;
  final String carModel;
  // final String subtotal;
  // final String outstanding;
  // final String rounding;
  // final String grandTotal;
  final List<Map<String, String>> services;
  final List<Map<String, dynamic>> payments;

  CarReceiptData({
    required this.shopName,
    required this.shopIcon,
    required this.address,
    required this.receiptID,
    required this.invNo,
    required this.salesDate,
    required this.issuedDate,
    required this.cashierName,
    required this.staffName,
    required this.mobile,
    required this.location,
    required this.carPlate,
    required this.carModel,
    // required this.subtotal,
    // required this.outstanding,
    // required this.rounding,
    // required this.grandTotal,
    required this.services,
    required this.payments,
  });
}
