// import 'dart:typed_data';

// import 'package:esc_pos_printer/esc_pos_printer.dart';
// import 'package:esc_pos_utils/esc_pos_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;

// import '../../data_models/spa_workslip.dart';
// import '../../printer_utils/dialogs.dart';

// Future<void> spaWorkSlip(
//       BuildContext context, NetworkPrinter printer, SpaWorkSlipData printData) async {
//     showLoadingDialog(context, 'Printing');
//      printer..text('** REPRINT **',
//         linesAfter: 1,
//         styles: PosStyles(
//           bold: true,
//           align: PosAlign.center,
//         ));
//     printer..text('JOB TICKET',
//         linesAfter: 1,
//         styles: PosStyles(
//           align: PosAlign.center,
//         ));

//     printer.row([
//       PosColumn(
//           text: 'Name   : ${printData.memberName}',
//           width: 7,
//           styles: PosStyles(align: PosAlign.left)),
//       PosColumn(
//           text: 'Masseur: ${printData.staffName}',
//           width: 5,
//           styles: PosStyles(align: PosAlign.left)),
//     ]);
//     printer.row([
//       PosColumn(
//           text: 'Mobile : ${printData.memberMobile}',
//           width: 7,
//           styles: PosStyles(align: PosAlign.left)),
//       PosColumn(
//           text: 'Room : ${printData.roomName}',
//           width: 5,
//           styles: PosStyles(align: PosAlign.left)),
//     ]);
//     printer.feed(1);

//     printer.text('Issued Date : ${printData.issuedDate}',
//         linesAfter: 1, styles: PosStyles(align: PosAlign.left));
//     printer.hr();
//     printer.feed(1);

//     for (String serviceText in printData.services) {
//       printer
//           .text(serviceText, styles: PosStyles(align: PosAlign.left));
//     }
//     printer.hr();
//     printer.feed(1);
//     printer.text(printData.timeString,
//         styles: PosStyles(bold: true, align: PosAlign.center));
//     printer.feed(2);
//     printer.cut();
//     hideLoadingDialog(context);
//   }