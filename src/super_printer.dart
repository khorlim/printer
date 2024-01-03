import 'dart:async';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:thermal_printer/thermal_printer.dart';
import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/extra_utils/printer/src/print_command_adapter.dart';
import 'package:tunaipro/extra_utils/printer/src/printer_managers/bt_print_manager.dart';
import 'package:tunaipro/extra_utils/printer/src/model/custom_printer_model.dart';
import 'package:tunaipro/extra_utils/printer/src/printer_managers/network_print_manager.dart';
import 'package:tunaipro/extra_utils/printer/src/printer_managers/star_print_manager.dart';
import 'package:tunaipro/extra_utils/printer/src/receipt_commands/receipt_manager.dart';
import 'package:thermal_printer/printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperPrinter {
  static final SuperPrinter _instance = SuperPrinter._internal();

  factory SuperPrinter() {
    return _instance;
  }

  SuperPrinter._internal() {
    () async {
      sharedPrefs = await SharedPreferences.getInstance();
      final String? savedPrinterJsonString = sharedPrefs.getString('printer');
      _paperSize = sharedPrefs.getString('printerPaperSize') == 'mm58'
          ? PaperSize.mm58
          : PaperSize.mm80;

      if (savedPrinterJsonString == null) {
        debugPrint('## No printer settings found locally. ##');
      } else {
        debugPrint('## Applying stored printer settings.');
        _selectedPrinter =
            CustomPrinter.fromJson(jsonDecode(savedPrinterJsonString));
        _selectedPrinterController.add(_selectedPrinter!);
        bool status = await checkStatus();
        debugPrint('-> Printer Connection Status : $status');
        if (!status) {
          connect(_selectedPrinter!);
        }
      }
    }();

    _btDeviceSubscription =
        _bluePrintManager.btDeviceStream.listen((btDeviceList) {
      _bluePrinterListController.add(btDeviceList
          .map((printer) => CustomPrinter.fromPrinterDevice(printer,
              printerType: PType.btPrinter))
          .toList());
    });
    _networkDeviceSubscription =
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

    _btDeviceStatusSubs = _bluePrintManager.statusStream.listen((btStatus) {
      if (btStatus == BTStatus.connected) {
        _status = PStatus.connected;
        _printerStatusController.add(PStatus.connected);
      } else if (btStatus == BTStatus.none) {
        _status = PStatus.none;
        _printerStatusController.add(PStatus.none);
      }
    });
    _networkDeviceStatusSubs =
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

  late final StreamSubscription<List<PrinterDevice>> _btDeviceSubscription;
  late final StreamSubscription<List<PrinterDevice>> _networkDeviceSubscription;
  late final StreamSubscription<BTStatus> _btDeviceStatusSubs;
  late final StreamSubscription<TCPStatus> _networkDeviceStatusSubs;

  late final SharedPreferences sharedPrefs;

  CustomPrinter? get currentPrinter => _selectedPrinter;

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
  PaperSize _paperSize = PaperSize.mm80;
  PStatus _status = PStatus.none;

  //PrintStatus? _printStatus;
  List<CustomPrinter> _starPrinterList = [];
  // List<CustomPrinter> _btPrinterList = [];
  // List<CustomPrinter> _networkPrinterList = [];

  Future<void> searchPrinter() async {
    _bluePrintManager.searchPrinter();

    try {
      await _starPrintManager.searchPrinter().then((starPList) {
        _starPrinterList =
            starPList.map((port) => CustomPrinter.fromPortInfo(port)).toList();
        _starPrinterListController.add(_starPrinterList);
      });
    } catch (e) {
      debugPrint('-----Failed to search star printer. $e-----');
    }

    // RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    // final List<CustomPrinter> starPrinterList = await Isolate.run(
    //   () => _searchStarPrinter(rootIsolateToken),
    // );
    // _starPrinterList = starPrinterList;
    // _starPrinterListController.add(_starPrinterList);

    _networkPrintManager.searchPrinter();

    return;
  }

  Future<void> connect(CustomPrinter printer) async {
    if (_status == PStatus.connecting) {
      debugPrint('Connecting.... dont spam');
      return;
    }
    _status = PStatus.connecting;
    _printerStatusController.add(PStatus.connecting);

    _selectedPrinter = printer;
    _selectedPrinterController.add(_selectedPrinter!);
    _savePrinterSetting(_selectedPrinter!);

    debugPrint(
        '---> Trying to connect printer : ${_selectedPrinter?.name} (${_selectedPrinter?.address})');
    bool connected = false;
    switch (printer.printerType) {
      case PType.btPrinter:
        connected =
            await _bluePrintManager.connectPrinter(printer.toPrinterDevice());
        break;
      case PType.networkPrinter:
        connected = await _networkPrintManager
            .checkConnection(printer.toPrinterDevice());
        break;
      case PType.starPrinter:
        connected =
            await _starPrintManager.getPrinterStatus(printer.toPortInfo());
        break;
    }
    if (connected) {
      debugPrint('----> Successfully connected printer. Ready to print.');
    } else {
      debugPrint('----> Failed to connect printer.');
    }
    _status = connected ? PStatus.connected : PStatus.none;
    _printerStatusController.add(_status);
  }

  Future<bool> checkStatus() async {
    debugPrint('-----> Checking printer status');
    if (_selectedPrinter == null) {
      debugPrint('----- No Selected Printer.');
      return false;
    }
    _status = PStatus.connecting;
    _printerStatusController.add(_status);

    _selectedPrinterController.add(_selectedPrinter!);
    bool status = false;
    switch (_selectedPrinter!.printerType) {
      case PType.btPrinter:
        status = await _bluePrintManager.getStatus();
        break;
      case PType.networkPrinter:
        status = await _networkPrintManager
            .checkConnection(_selectedPrinter!.toPrinterDevice());
        break;
      case PType.starPrinter:
        status = await _starPrintManager
            .getPrinterStatus(_selectedPrinter!.toPortInfo());
        break;
    }

    if (status) {
      _status = PStatus.connected;
      _printerStatusController.add(_status);
      return true;
    } else {
      _status = PStatus.none;
      _printerStatusController.add(_status);
      return false;
    }
  }

  Future<bool> startPrint(
      {required ReceiptType receiptType,
      required ReceiptData receiptData}) async {
    if (_selectedPrinter == null) {
      debugPrint('No printer selected.');
      return false;
    }
    if (_status != PStatus.connected) {
      debugPrint('No connected printer');
      return false;
    }

    debugPrint('Paper Size : ${getPaperSizeString(_paperSize)}');

    PrintCommandAdapter printCommand = await ReceiptManager.getReceipt(
        receiptType: receiptType,
        receiptData: receiptData,
        printerType: _selectedPrinter!.printerType,
        paperSize: _paperSize);

    bool printSuccess = false;
    try {
      switch (_selectedPrinter!.printerType) {
        case PType.btPrinter:
          printSuccess =
              await _bluePrintManager.sendPrintCommand(printCommand.bytes);
          break;
        case PType.networkPrinter:
          printSuccess =
              await _networkPrintManager.sendPrintCommand(printCommand.bytes);
          break;
        case PType.starPrinter:
          printSuccess = await _starPrintManager.sendPrintCommand(
              printer: _selectedPrinter!,
              commands: printCommand.starPrintCommands);
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

  void changePaperSize(PaperSize paperSize) {
    _paperSize = paperSize;
  }

  void _savePrinterSetting(CustomPrinter printer) async {
    debugPrint('## Storing printer setting to local. ##');
    try {
      await sharedPrefs.setString('printer', jsonEncode(printer.toJson()));
    } catch (e) {
      debugPrint('Failed to store printer setting to local. $e');
    }
  }

  void dispose() {
    // Cancel the stream subscriptions to avoid memory leaks
    _btDeviceSubscription.cancel();
    _networkDeviceSubscription.cancel();
    _btDeviceStatusSubs.cancel();
    _networkDeviceStatusSubs.cancel();
  }

  static String getPaperSizeString(PaperSize paperSize) {
    switch (paperSize) {
      case PaperSize.mm80:
        return 'mm80';
      case PaperSize.mm58:
        return 'mm58';
      case PaperSize.mm72:
        return 'mm72';
      default:
        return 'mm80';
    }
  }
}

@pragma('vm:entry-point')
Future<List<CustomPrinter>> _searchStarPrinter(
    RootIsolateToken rootIsolateToken) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  final StarPrintManager starPrintManager = StarPrintManager();
  List<CustomPrinter> starPrinterList = [];
  try {
    await starPrintManager.searchPrinter().then((starPList) {
      starPrinterList =
          starPList.map((port) => CustomPrinter.fromPortInfo(port)).toList();
    });
    return starPrinterList;
  } catch (e) {
    debugPrint('-----Failed to search star printer. $e-----');
    return [];
  }
}
