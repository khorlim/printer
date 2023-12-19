import 'dart:async';

import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:printer_test/bluetooth_print_page.dart';
import 'package:printer_test/printer/printer_managers/bt_print_manager.dart';
import 'package:printer_test/printer/model/custom_printer_model.dart';
import 'package:printer_test/printer/printer_managers/network_print_manager.dart';
import 'package:printer_test/printer/printer_managers/star_print_manager.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/capability_profile.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/enums.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/generator.dart';
import 'package:thermal_printer/esc_pos_utils_platform/src/pos_styles.dart';
import 'package:thermal_printer/printer.dart';

class SuperPrinter {
  static final SuperPrinter _instance = SuperPrinter._internal();

  factory SuperPrinter() {
    return _instance;
  }

  SuperPrinter._internal() {
    var btDeviceSubscription =
        _bluePrintManager.btDeviceStream.listen((btDeviceList) {
      _bluePrinterListController.add(btDeviceList
          .map((printer) => CustomPrinter.fromPrinterDevice(printer,
              printerType: PType.btPrinter))
          .toList());
    });
    var networkDeviceSubscription =
        _networkPrintManager.networkDevicesStream.listen((networkDeviceList) {
      List<CustomPrinter> networkDList = networkDeviceList
          .map((printer) => CustomPrinter.fromPrinterDevice(printer,
              printerType: PType.networkPrinter))
          .toList();
      networkDList.removeWhere((printer) => _starPrinterList.any((starPrinter) {
            String cleanAddress = starPrinter.address.substring(4);
            //   print('comparing ${cleanAddress} : ${printer.address}');
            return cleanAddress == printer.address;
          }));
      _networkPrinterListController.add(networkDList);
    });

    var btDeviceStatusSubs = _bluePrintManager.statusStream.listen((btStatus) {
      if (btStatus == BTStatus.connected) {
        _status = PStatus.connected;
        _printerStatusController.add(PStatus.connected);
      } else if (btStatus == BTStatus.none) {
        _status = PStatus.none;
        _printerStatusController.add(PStatus.none);
      }
    });
    var networkDeviceStatusSubs =
        _networkPrintManager.statusStream.listen((tcpStatus) {
      if (tcpStatus == TCPStatus.connected) {
        _status = PStatus.connected;
        _printerStatusController.add(PStatus.connected);
      } else if (tcpStatus == TCPStatus.none) {
        _status = PStatus.none;
        _printerStatusController.add(PStatus.none);
      }
    });
  }

  Stream<CustomPrinter> get selectedPrinterStream =>
      _selectedPrinterController.stream;
  Stream<PStatus> get printerStatusStream => _printerStatusController.stream;

  Stream<List<CustomPrinter>> get starPrinterListStream =>
      _starPrinterListController.stream;
  Stream<List<CustomPrinter>> get bluePrinterListStream =>
      _bluePrinterListController.stream;
  Stream<List<CustomPrinter>> get networkPrinterListStream =>
      _networkPrinterListController.stream;

  final StarPrintManager _starPrintManager = StarPrintManager();
  final BluetoothPrintManager _bluePrintManager = BluetoothPrintManager();
  final NetworkPrintManager _networkPrintManager = NetworkPrintManager();

  final StreamController<CustomPrinter> _selectedPrinterController =
      StreamController<CustomPrinter>.broadcast();
  final StreamController<PStatus> _printerStatusController =
      StreamController<PStatus>.broadcast();
  final StreamController<List<CustomPrinter>> _starPrinterListController =
      StreamController<List<CustomPrinter>>.broadcast();
  final StreamController<List<CustomPrinter>> _bluePrinterListController =
      StreamController<List<CustomPrinter>>.broadcast();
  final StreamController<List<CustomPrinter>> _networkPrinterListController =
      StreamController<List<CustomPrinter>>.broadcast();

  CustomPrinter? _selectedPrinter;
  PStatus _status = PStatus.none;
  PrintStatus? _printStatus;

  List<CustomPrinter> _starPrinterList = [];
  List<CustomPrinter> _btPrinterList = [];
  List<CustomPrinter> _networkPrinterList = [];

  Future<void> searchPrinter() async {
    _bluePrintManager.searchPrinter();
    await _starPrintManager.searchPrinter().then((starPList) {
      List<CustomPrinter> starPrinterList =
          starPList.map((port) => CustomPrinter.fromPortInfo(port)).toList();
      _starPrinterList = starPrinterList;
      _starPrinterListController.add(starPrinterList);
    });
    _networkPrintManager.searchPrinter();
  }

  Future<void> connect(CustomPrinter printer) async {
    if (_status == PStatus.connecting) {
      print('Connecting.... dont spam');
      return;
    }
    _status = PStatus.connecting;
    _printerStatusController.add(PStatus.connecting);
    bool connected = false;
    _selectedPrinter = printer;
    _selectedPrinterController.add(_selectedPrinter!);
    print(
        'selected printer : ${_selectedPrinter?.name} (${_selectedPrinter?.address})');
    switch (printer.printerType) {
      case PType.btPrinter:
        connected =
            await _bluePrintManager.connectPrinter(printer.toPrinterDevice());
        break;
      case PType.networkPrinter:
        connected = await _networkPrintManager
            .connectPrinter(printer.toPrinterDevice());
        break;
      case PType.starPrinter:
        connected =
            await _starPrintManager.getPrinterStatus(printer.toPortInfo());
        break;
    }
    _status = connected ? PStatus.connected : PStatus.none;
    _printerStatusController.add(_status);
  }

  Future<bool> startPrint() async {
    if (_selectedPrinter == null) {
      print('No printer selected.');
      return false;
    }
    if (_status != PStatus.connected) {
      print('No connected printer');
      return false;
    }
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text('Test Print',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Product 1');
    bytes += generator.text('Product 2');
    bytes += generator.feed(2);
    bytes += generator.cut();

    PrintCommands commands = PrintCommands();
    BitmapTextHelper bitmapTextHelper = BitmapTextHelper();

    String raster = bitmapTextHelper.alignText('Thank you', Alignment.Center) +
        bitmapTextHelper.rowWithCustomSpaces(
            ['Total', 'Discount', 'Amount'], [39 ~/ 3, 39 ~/ 3, 39 ~/ 3],
            alignment: Alignment.Center) +
        bitmapTextHelper.rowWithCustomSpaces(
            ['100 :', '200', '1'], [39 ~/ 3, 39 ~/ 3, 39 ~/ 3]) +
        bitmapTextHelper.rowWithCustomSpaces(
            ['10 :', '8000', '900'], [39 ~/ 3, 39 ~/ 3, 39 ~/ 3]);
    commands.appendBitmapText(text: raster);
    commands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);
    bool printSuccess = false;
    try {
      switch (_selectedPrinter!.printerType) {
        case PType.btPrinter:
          printSuccess = await _bluePrintManager.sendPrintCommand(bytes);
          break;
        case PType.networkPrinter:
          printSuccess = await _networkPrintManager.sendPrintCommand(bytes);
          break;
        case PType.starPrinter:
          printSuccess = await _starPrintManager.sendPrintCommand(
              printer: _selectedPrinter!, commands: commands);
          break;
      }
    } catch (e) {
      printSuccess = false;
      print('faill.....');
    }
    if (!printSuccess) {
      connect(_selectedPrinter!);
    }
    return printSuccess;
  }
}
