import 'package:equatable/equatable.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';
import 'package:thermal_printer/thermal_printer.dart';

enum PType {
  btPrinter,
  starPrinter,
  networkPrinter,
  usbPrinter,
  btPlusPrinter,
  imin
}

enum PStatus { connected, connecting, none }

enum PrintStatus { success, failed, printing }

class CustomPrinter extends Equatable {
  final String name;
  final String address;
  final PType printerType;

  const CustomPrinter({
    required this.name,
    required this.address,
    required this.printerType,
  });

  factory CustomPrinter.fromPrinterDevice(PrinterDevice printerDevice,
      {required PType printerType}) {
    if (printerType == PType.usbPrinter) {
      return CustomPrinter(
          name: printerDevice.name,
          address: '${printerDevice.productId}-${printerDevice.vendorId}',
          printerType: printerType);
    }
    return CustomPrinter(
        name: printerDevice.name,
        address: printerDevice.address!,
        printerType: printerType);
  }

  factory CustomPrinter.fromPortInfo(PortInfo portInfo) {
    return CustomPrinter(
        name: portInfo.modelName!,
        address: portInfo.portName!,
        printerType: PType.starPrinter);
  }

  PrinterDevice toPrinterDevice() {
    if (printerType == PType.usbPrinter) {
      List<String> ids = address.split('-');
      String productID = ids[0];
      String vendorID = ids[1];

      return PrinterDevice(
          name: name, productId: productID, vendorId: vendorID);
    }
    return PrinterDevice(name: name, address: address);
  }

  PortInfo toPortInfo() {
    return PortInfo({'modelName': name, 'portName': address});
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'printerType': printerType.toString(),
    };
  }

  factory CustomPrinter.fromJson(Map<String, dynamic> json) {
    return CustomPrinter(
      name: json['name'],
      address: json['address'],
      printerType:
          PType.values.firstWhere((e) => e.toString() == json['printerType']),
    );
  }

  @override
  List<Object?> get props => [name, address, printerType];

  @override
  String toString() {
    return 'CustomPrinter{name: $name, address: $address, printerType: $printerType}';
  }
}
