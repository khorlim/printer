import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:spa_app/printer/data_models/spa_workslip.dart';

import '../../data_models/spa_receipt.dart';
import '../../printer_utils/utils.dart';

PrintCommands spaWorkSlip(
    {required bool format58mm, required SpaWorkSlipData printData}) {
  PrintCommands commands = PrintCommands();

  String receiptLength =
      ".....................................................";
  String separateLine =
      "-----------------------------------------------------\n";
  String fontSize12Length = "111111111111111111111111111111111111111\n";
  int size12Length = fontSize12Length.length;
  int length = receiptLength.length;

  // int spaceBetween = length - cashierLine.length -1;
  String header = "\n${alignCenter('** Reprint **', size12Length)}\n";

  String title = "${alignCenter("JOB TICKET", size12Length)}\n";

  String memberLabel = "Name    : ${printData.memberName}";
  String memberMobileLabel = "Mobile  : ${printData.memberMobile}";
  String staffLabel = "Masseur : ${printData.staffName}";
  String roomLabel = "Room : ${printData.roomName}";

  String issuedDateLabel = "Issued Date : ${printData.issuedDate}";

  String info = "$memberLabel${staffLabel.padLeft(length - memberLabel.length)}\n"
      "$memberMobileLabel${roomLabel.padLeft(length - memberMobileLabel.length)}\n\n"
      "$issuedDateLabel\n";

  info += '$separateLine';

  String service = '';
  for(String serviceText in printData.services) {
    service += '$serviceText\n';
  }
  service += separateLine;

  String timeText = '${alignCenter(printData.timeString, size12Length)}';

  commands.appendBitmapText(
    text: header,
    fontSize: 12,
  );
  commands.appendBitmapText(text: title, fontSize: 12);
  commands.appendBitmapText(text: info, fontSize: 9);
  commands.appendBitmapText(text: service, fontSize: 9);
  commands.appendBitmapText(text: timeText, fontSize: 12);

  commands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);

  return commands;
}
