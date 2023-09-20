/* Packages 
  flutter_star_prnt: ^2.4.1
  esc_pos_printer: ^4.1.0
  esc_pos_utils: ^1.1.0
  network_discovery: ^1.0.0
  bluetooth_print: ^4.3.0
  flutter_blue_plus: ^1.14.7
*/

/* Prerequisite
Need to add this into your info.plist for star bluetooth printers
ios/Runner/Info.plist
<key>UISupportedExternalAccessoryProtocols</key>
  <array>
    <string>jp.star-m.starpro</string>
  </array>
<key>NSBluetoothAlwaysUsageDescription</key>  
<string>Need BLE permission</string>  
<key>NSBluetoothPeripheralUsageDescription</key>  
<string>Need BLE permission</string>  
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>  
<string>Need Location permission</string>  
<key>NSLocationAlwaysUsageDescription</key>  
<string>Need Location permission</string>  
<key>NSLocationWhenInUseUsageDescription</key>  
<string>Need Location permission</string>

android/app/src/AndroidManifest.xml
<uses-permission android:name="android.permission.INTERNET"></uses-permission>
<uses-permission android:name="android.permission.BLUETOOTH"></uses-permission>
	    
*/

/*
PrintReceipt printer = PrintReceipt();   //Create PrintReceipt Instance
bool printerFound = await printer.findAnyPrinter(context);

String dateTimeNow =
    DateFormat('d/M/yyyy h:mm:ss a').format(DateTime.now());
SharedPreferences prefs =
    await SharedPreferences.getInstance();

String? shopName = prefs.getString('shopName');
String? shopIcon = prefs.getString('shopIcon');
String? shopLocation = prefs.getString('shopLocation');
String? shopAddress = prefs.getString('shopAddress');

List<Map<String, String>> servicesForReceipt = [];
for (var otem in otemsList) {
  String serviceName = widget.serviceList
      .firstWhere(
        (sku) => sku.skuID == otem['skuID'],
      )
      .name;
  String amount = ((otem['price'] - otem['discount']) *
          otem['quantity'])
      .toStringAsFixed(2);
  servicesForReceipt.add({
    "name": serviceName,
    "price": otem['price'].toStringAsFixed(2),
    "discount": otem['discount'].toStringAsFixed(2),
    "amount": amount,
    "quantity": otem['quantity'].toString()
  });
}

List<Map<String, String>> paymentsForReceipt = [];
for (var payment in paymentCollection) {
  String paymentName = paymentMethods.firstWhere((method) =>
      method['paymentTypeID'] ==
      payment['paymentTypeID'])['title'];
  paymentsForReceipt.add({
    "paymentMethod": paymentName,
    "amount": payment['amount'].toStringAsFixed(2),
  });
}
SpaReceiptData spaReceiptData = SpaReceiptData(
  context: context,
  shopName: shopName!,
  shopIcon: shopIcon!,
  address: shopAddress!,
  receiptID: "",
  cashierName: "",
  invNo: "",
  salesDate: "",
  issuedDate: dateTimeNow,
  staffName: "",
  mobile: "",
  roomName: "",
  location: shopLocation!,
  services: servicesForReceipt,
  payments: paymentsForReceipt,
);

CarReceiptData carReceiptData = CarReceiptData(
  carPlate: 'FB6765',
  carModel: 'Toyota',
  shopName: shopName!,
  shopIcon: shopIcon!,
  address: shopAddress!,
  receiptID: "",
  cashierName: "",
  invNo: "",
  salesDate: "",
  issuedDate: dateTimeNow,
  staffName: "",
  mobile: "",
  location: shopLocation!,
  services: servicesForReceipt,
  payments: paymentsForReceipt,
);

SpaWorkSlipData spaWorkSlipData = SpaWorkSlipData(
    memberName: 'Lim Han',
    staffName: 'Dayon',
    memberMobile: '60102812876',
    roomName: 'SHIT Room',
    issuedDate: dateTimeNow,
    services: [
      '1x Whatever Spa',
      '5x Whatever Foot Massage'
    ],
    timeString: 'START TIME 10:30am to 5pm');

printer.startPrint(context, carReceiptData);
*/

//Example Data
/*
List of Services
services : [{'name': 'Spa', 'price': '200.00', 'discount': '0.00', 'amount': '200.00', 'quantity': '1'}]
List of Payments
payments : [{'paymentMethod': 'cash', 'amount': '100.00'}, {'paymentMethod': 'debit card', 'amount': '100.00'}]
*/