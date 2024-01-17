import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/general_module/order_module/import_path.dart';
import 'package:tunaipro/share_code/widget/add_space.dart';
import 'package:tunaipro/share_code/widget/small_widget/close_button.dart';

import 'super_printer.dart';

class PrinterSettingPage extends StatefulWidget {
  const PrinterSettingPage({super.key});

  @override
  State<PrinterSettingPage> createState() => _PrinterSettingPageState();
}

class _PrinterSettingPageState extends State<PrinterSettingPage> {
  final SuperPrinter superPrinter = SuperPrinter();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final List<PrinterWidget> widgetList = [];

  List<CustomPrinter> btDeviceList = [];

  late final StreamSubscription<List<CustomPrinter>> btDeviceSubs;
  late final StreamSubscription<List<CustomPrinter>> starDeviceSubs;
  late final StreamSubscription<List<CustomPrinter>> networkDeviceSubs;
  late final StreamSubscription<CustomPrinter> selectedPrinterSubs;
  late final StreamSubscription<PStatus> printerStatusSubs;

  PStatus? printerStatus;
  CustomPrinter? selectedPrinter;

  final List<PaperSize> paperSizeList = [
    PaperSize.mm80,
    PaperSize.mm58,
  ];

  late PaperSize selectedPaperSize = paperSizeList.first;

  bool isSearching = false;
  @override
  void initState() {
    super.initState();

    btDeviceSubs = superPrinter.bluePrinterListStream.listen((event) {
      PType printerType = PType.btPrinter;

      updatePrinterWidget(printerType, event);
    });
    starDeviceSubs = superPrinter.starPrinterListStream.listen((event) {
      PType printerType = PType.starPrinter;

      updatePrinterWidget(printerType, event);
    });
    networkDeviceSubs = superPrinter.networkPrinterListStream.listen((event) {
      PType printerType = PType.networkPrinter;

      updatePrinterWidget(printerType, event);
    });

    selectedPrinterSubs = superPrinter.selectedPrinterStream.listen((event) {
      setState(() {
        selectedPrinter = event;
      });
    });
    printerStatusSubs = superPrinter.printerStatusStream.listen((event) {
      setState(() {
        printerStatus = event;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      superPrinter.checkStatus();
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      selectedPaperSize =
          sharedPreferences.getString('printerPaperSize') == 'mm58'
              ? PaperSize.mm58
              : PaperSize.mm80;
    });
  }

  void updatePrinterWidget(PType printerType, List<CustomPrinter> printerList) {
    String printerTitle = printerType == PType.btPrinter
        ? 'Bluetooth Device'
        : printerType == PType.starPrinter
            ? 'Star Printer'
            : 'Network Device';

    int foundListIndex =
        widgetList.indexWhere((element) => element.printerType == printerType);
    if (foundListIndex == -1 && printerList.isNotEmpty) {
      addListItem(PrinterWidget(
        printerType: printerType,
        printerWidget: _buildPrinterList(
          title: printerTitle,
          printerList: printerList,
        ),
      ));
    } else if (printerList.isEmpty) {
      removeListItem(PrinterWidget(
          printerWidget:
              _buildPrinterList(title: printerTitle, printerList: printerList),
          printerType: printerType));
    } else {
      widgetList[foundListIndex] = PrinterWidget(
          printerWidget:
              _buildPrinterList(title: printerTitle, printerList: printerList),
          printerType: printerType);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void addListItem(PrinterWidget pWidget) {
    widgetList.insert(0, pWidget);
    _listKey.currentState!
        .insertItem(0, duration: Duration(milliseconds: 1000));
  }

  void removeListItem(PrinterWidget pWidget) {
    if (widgetList.isEmpty) {
      return;
    }

    int index = widgetList
        .indexWhere((element) => element.printerType == pWidget.printerType);
    widgetList.removeAt(index);
    _listKey.currentState!.removeItem(
        index, (context, animation) => SizeTransition(sizeFactor: animation));
  }

  @override
  void dispose() {
    btDeviceSubs.cancel();
    starDeviceSubs.cancel();
    networkDeviceSubs.cancel();
    selectedPrinterSubs.cancel();
    printerStatusSubs.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Printer',
        leading: CustomCloseButton(),
        actions: [
          if (printerStatus != null &&
              selectedPrinter != null &&
              printerStatus == PStatus.none)
            CupertinoButton(
                child: Text(
                  'Reconnect',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: primaryBlue),
                ),
                onPressed: () {
                  superPrinter.connect(selectedPrinter!);
                })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10.0, right: 10, bottom: 5),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    selectedPrinter == null
                        ? 'No Printer'
                        : '${selectedPrinter!.name}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  if (selectedPrinter != null)
                    printerStatus == null
                        ? SizedBox.shrink()
                        : printerStatus == PStatus.none
                            ? Icon(
                                CupertinoIcons.xmark,
                                color: Colors.red,
                              )
                            : printerStatus == PStatus.connecting
                                ? CupertinoActivityIndicator()
                                : Icon(
                                    CupertinoIcons.check_mark,
                                    color: Colors.green,
                                  ),
                ],
              ),
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   children: [
            //     CupertinoButton(
            //         child: Text('Test Print'),
            //         onPressed: () {
            //           ReceiptData fakeReceiptData = ReceiptData(
            //               voidValue: false,
            //               salesID: 0,
            //               icon: globalOutlet?.shopIcon ?? '',
            //               shopName: globalOutlet?.shopName ?? '',
            //               templateID: 0,
            //               customerMobile: 'Mobile',
            //               customerName: 'Name',
            //               customerAddress: [],
            //               remark: [],
            //               editDate: 'Date',
            //               shopAddress: [],
            //               title: 'Test Print',
            //               field: [],
            //               items: [],
            //               payments: [],
            //               redeems: [],
            //               customerDetail: null,
            //               footer: []);
            //           superPrinter.startPrint(
            //               receiptData: fakeReceiptData,
            //               receiptType: ReceiptType.beauty);
            //         }),
            //     CupertinoButton(child: Text('Test Drawer'), onPressed: () {}),
            //   ],
            // ),
            buildPaperSizeOption(),
            CupertinoButton(
                child: Column(
                  children: [
                    Text('Search for printer'),
                    if (isSearching) CupertinoActivityIndicator()
                  ],
                ),
                onPressed: isSearching
                    ? null
                    : () async {
                        setState(() {
                          isSearching = true;
                        });
                        await superPrinter.searchPrinter();
                        setState(() {
                          isSearching = false;
                        });
                      }),
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: 0,
                itemBuilder: (context, index, animation) {
                  return SizeTransition(
                    sizeFactor: animation,
                    key: UniqueKey(),
                    child: widgetList[index].printerWidget,
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Row buildPaperSizeOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Paper Size: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        DropdownButton(
            value: selectedPaperSize,
            items: paperSizeList
                .map((paperSize) => DropdownMenuItem(
                      value: paperSize,
                      child: Text(
                        paperSize == PaperSize.mm80 ? 'mm80' : 'mm58',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedPaperSize = value!;
                superPrinter.changePaperSize(selectedPaperSize);
              });
              storePrinterPaperSize(selectedPaperSize);
            }),
      ],
    );
  }

  Widget _buildPrinterList(
      {required String title, required List<CustomPrinter> printerList}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddSpace(
          height: 10,
        ),
        Text(
          title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
        AddSpace(
          height: 5,
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: printerList.length,
          itemBuilder: (context, index) {
            final CustomPrinter printer = printerList[index];
            return _buildPrinterButton(printer);
          },
        )
      ],
    );
  }

  Widget _buildPrinterButton(CustomPrinter printer) {
    return Container(
      margin: EdgeInsets.only(bottom: 5),
      child: CupertinoButton(
          padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          child: Text(
            printer.name,
            style: TextStyle(
              color: primaryBlue,
              fontSize: 14,
            ),
          ),
          onPressed: () {
            superPrinter.connect(printer);
          }),
    );
  }

  Future<void> storePrinterPaperSize(PaperSize paperSize) async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String paperSizeString = paperSize == PaperSize.mm80 ? 'mm80' : 'mm58';
      sharedPreferences.setString('printerPaperSize', paperSizeString);
    } catch (e) {
      debugPrint('-----> Failed to store printer paper size to local.');
    }
  }
}

class PrinterWidget {
  final PType printerType;
  final Widget printerWidget;

  PrinterWidget({required this.printerWidget, required this.printerType});
}
