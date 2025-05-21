import 'package:shared_pref_helper/shared_pref_helper.dart';

import '../printer_setting_screen.dart';

class PrinterTypeStorage extends AbstractSharedPrefStorage<PrinterType> {
  @override
  String convertDataToString(PrinterType data) {
    return data.name;
  }

  @override
  PrinterType convertStringToData(String data) {
    return PrinterType.fromName(data);
  }

  @override
  String get key => 'printer_type';
}
