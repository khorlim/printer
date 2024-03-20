import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thermal_printer/thermal_printer.dart';
import 'package:tunaipro/engine/receipt/model/receipt_data.dart';
import 'package:tunaipro/general_module/order_module/import_path.dart';
import 'package:tunaipro/homepage/utils/navigation_service.dart';
import 'package:tunaipro/share_code/widget/small_widget/close_button.dart';
import 'package:tunaipro/shared/shared_widgets/custom_popup_menu/custom_popup_menu.dart';
import 'package:tunaipro/shared/shared_widgets/text_field_2.dart';

import 'super_printer.dart';

class PrinterSettingPage extends StatefulWidget {
  final BuildContext context;
  const PrinterSettingPage({super.key, required this.context});

  @override
  State<PrinterSettingPage> createState() => _PrinterSettingPageState();
}

class _PrinterSettingPageState extends State<PrinterSettingPage> {
  final SuperPrinter superPrinter = SuperPrinter();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final List<PrinterWidget> widgetList = [];

  List<CustomPrinter> starPrinterList = [];

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

  final double conHeight = 50;

  bool isSearching = false;
  bool searchingStarPrinter = false;

  @override
  void initState() {
    super.initState();

    btDeviceSubs = superPrinter.bluePrinterListStream.listen((event) {
      PType printerType = PType.btPrinter;

      updatePrinterWidget(
          printerType, List<CustomPrinter>.from(event).toSet().toList());
    });
    starDeviceSubs = superPrinter.starPrinterListStream.listen((event) {
      starPrinterList = event;
      setState(() {});
      // PType printerType = PType.starPrinter;

      // updatePrinterWidget(printerType, event);
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

      searchPrinter();
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

  Future<void> searchPrinter({String? manualGateway}) {
    setState(() {
      isSearching = true;
    });
    return superPrinter
        .searchPrinter(
            searchForStarPrinter: false, manualGateway: manualGateway)
        .then((value) {
      setState(() {
        isSearching = false;
      });
    });
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
      resizeToAvoidBottomInset: getDeviceType(context) == DeviceType.mobile,
      // appBar: CustomAppBar(
      //   title: 'Printer',
      //   leading: CustomCloseButton(),
      //   actions: [
      //     if (printerStatus != null &&
      //         selectedPrinter != null &&
      //         printerStatus == PStatus.none)
      //       CupertinoButton(
      //           child: Text(
      //             'Reconnect',
      //             style: TextStyle(
      //                 fontSize: 14,
      //                 fontWeight: FontWeight.w500,
      //                 color: primaryBlue),
      //           ),
      //           onPressed: () {
      //             superPrinter.connect(selectedPrinter!);
      //           })
      //   ],
      // ),
      body: Padding(
        padding:
            const EdgeInsets.only(left: 20.0, right: 20, bottom: 5, top: 10),
        child: Column(
          children: [
            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Text(
            //         selectedPrinter == null
            //             ? 'No Printer'
            //             : '${selectedPrinter!.name}',
            //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            //       ),
            //       if (selectedPrinter != null)
            //         printerStatus == null
            //             ? SizedBox.shrink()
            //             : printerStatus == PStatus.none
            //                 ? Icon(
            //                     CupertinoIcons.xmark,
            //                     color: Colors.red,
            //                   )
            //                 : printerStatus == PStatus.connecting
            //                     ? CupertinoActivityIndicator()
            //                     : Icon(
            //                         CupertinoIcons.check_mark,
            //                         color: Colors.green,
            //                       ),
            //     ],
            //   ),
            // ),
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
            if (selectedPrinter != null)
              buildSelectedPrinter(onPressed: () {
                superPrinter.connect(selectedPrinter!);
              }),

            buildPaperSizeOption(),

            if (isSearching && widgetList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: CupertinoActivityIndicator(),
              ),

            // CupertinoButton(
            //     child: Column(
            //       children: [
            //         Text('Search for printer'),
            //         if (isSearching) CupertinoActivityIndicator()
            //       ],
            //     ),
            //     onPressed: isSearching
            //         ? null
            //         : () async {
            //             searchPrinter();
            //           }),
            Expanded(
              child: RefreshIndicator.adaptive(
                onRefresh: () async {
                  await searchPrinter();
                },
                child: SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        AnimatedList(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
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
                        // Container(
                        //   height: conHeight,
                        //   width: double.infinity,
                        //   margin: EdgeInsets.only(top: 20),
                        //   decoration: BoxDecoration(
                        //       color: Colors.white,
                        //       borderRadius: BorderRadius.circular(8)),
                        //   child: CupertinoButton(
                        //       padding: EdgeInsets.zero,
                        //       child: Row(
                        //         mainAxisAlignment: MainAxisAlignment.center,
                        //         children: [
                        //           TText(
                        //             'Search for star printer',
                        //             color: searchingStarPrinter
                        //                 ? MyColor.grey
                        //                 : MyColor.blue,
                        //           ),
                        //           if (searchingStarPrinter)
                        //             CupertinoActivityIndicator(),
                        //         ],
                        //       ),
                        //       onPressed: searchingStarPrinter
                        //           ? null
                        //           : () async {
                        //               setState(() {
                        //                 searchingStarPrinter = true;
                        //               });
                        //               await superPrinter.searchStarPrinter();
                        //               setState(() {
                        //                 searchingStarPrinter = false;
                        //               });
                        //             }),
                        // ),
                        buildStarPrinterList(),
                        buildManualConnectField(onSubmitted: (value) {
                          superPrinter.connect(CustomPrinter(
                              name: 'Manual ($value)',
                              address: value,
                              printerType: PType.networkPrinter));
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildStarPrinterList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddSpace(
          height: 10,
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () async {
            setState(() {
              searchingStarPrinter = true;
            });
            await superPrinter.searchStarPrinter();
            setState(() {
              searchingStarPrinter = false;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 5),
            child: Row(
              children: [
                TText(
                  'Star Printer',
                  color: MyColor.grey,
                ),
                AddSpace(
                  width: 5,
                ),
                searchingStarPrinter
                    ? CupertinoActivityIndicator()
                    : Icon(
                        CupertinoIcons.search,
                        color: MyColor.grey.color,
                        size: 17,
                      )
              ],
            ),
          ),
        ),
        AddSpace(
          height: 5,
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: AnimateList(
                interval: 100.ms,
                effects: [
                  FadeEffect(),
                ],
                children: starPrinterList.mapIndexed((index, printer) {
                  bool isLast = index == starPrinterList.length - 1;
                  return Column(
                    children: [
                      _buildPrinterButton(printer),
                      if (!isLast)
                        Divider(
                          height: 0,
                          thickness: 0.5,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                    ],
                  );
                }).toList()),
          ),
        )
      ],
    );
  }

  Widget buildManualConnectField(
      {required void Function(String value) onSubmitted}) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              child: Row(
                children: [
                  TText(
                    'Manual Connect',
                    color: MyColor.grey,
                  ),
                  Icon(
                    CupertinoIcons.radiowaves_right,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
              onPressed: () {
                String ipAddress = '';
                DialogManager(
                    context: locator<NavigationService>().currentContext,
                    height: 240,
                    width: 300,
                    pushDialogAboveWhenKeyboardShow: true,
                    child: Container(
                      color: primaryBackgroundColor,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: TText(
                              'Custom Ip address',
                              size: TextSize.px15,
                            ),
                          ),
                          Center(
                            child: Container(
                              width: 150,
                              child: CustomTextField2(
                                backgroundColor: primaryBackgroundColor,
                                autofocus: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                hintText: 'Manual Connect',
                                onChanged: (value) {
                                  ipAddress = value;
                                },
                                onSubmitted: (value) {},
                              ),
                            ),
                          ),
                          Spacer(),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: 15, vertical: 10),
                            child: CupertinoButton(
                                color: MyColor.blue.color,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 11),
                                borderRadius: BorderRadius.circular(8),
                                child: TText(
                                  'Connect',
                                  color: MyColor.white,
                                ),
                                onPressed: () {
                                  if (ipAddress.isEmpty) {
                                    showInformDialog(context,
                                        title: 'Empty Ip Address', message: '');
                                    return;
                                  }
                                  onSubmitted(ipAddress);
                                  Navigator.pop(locator<NavigationService>()
                                      .currentContext);
                                }),
                          ),
                        ],
                      ),
                    )).show();
              })
          // CustomTextField2(
          //   contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          //   hintText: 'Manual Connect',

          //   onSubmitted: onSubmitted,
          // ),
        ],
      ),
    );
  }

  Widget buildSelectedPrinter({void Function()? onPressed}) {
    bool reconnect = printerStatus != null &&
        selectedPrinter != null &&
        printerStatus == PStatus.none;
    bool notConnected = printerStatus == null;
    bool connecting = printerStatus == PStatus.connecting;
    bool connected = printerStatus == PStatus.connected;

    String trailingText = reconnect
        ? 'Reconnect'
        : notConnected
            ? ''
            : connecting
                ? 'Connecting'
                : connected
                    ? 'Connected'
                    : '';

    return Animate(
      effects: [FadeEffect()],
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        child: buildContainer(
            margin: EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TText(
                    selectedPrinter?.name ?? 'None',
                    color: MyColor.grey,
                  ),
                ),
                connecting
                    ? CupertinoActivityIndicator()
                    : TText(
                        trailingText,
                        color: reconnect || connected
                            ? MyColor.blue
                            : MyColor.grey,
                      ),
              ],
            )),
      ),
    );
  }

  late final List<PopupItem> paperSizePopupItems = paperSizeList
      .map((paperSize) => PopupItem(
          title: getPaperSizeString(paperSize),
          onPressed: () {
            Navigator.pop(widget.context);
            setState(() {
              selectedPaperSize = paperSize;
              superPrinter.changePaperSize(selectedPaperSize);
            });
            storePrinterPaperSize(selectedPaperSize);
          }))
      .toList();

  Widget buildPaperSizeOption() {
    BuildContext? targetCtxt;
    return CupertinoButton(
      onPressed: () {
        CustomPopupMenu(
          items: paperSizePopupItems,
          dialogWidth: 180,
          alignTargetWidget: AlignTargetWidget.bottomCenter,
        ).show(targetCtxt!, navigatorContext: widget.context);
      },
      padding: EdgeInsets.zero,
      minSize: 0,
      child: buildContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TText(
                    'Receipt size',
                    color: MyColor.grey,
                  ),
                  AddSpace(
                    height: 5,
                  ),
                  Builder(builder: (context) {
                    targetCtxt = context;
                    return TText(
                      getPaperSizeString(selectedPaperSize),
                      color: MyColor.black,
                    );
                  }),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 17,
              color: MyColor.grey.color,
            )
          ],
        ),
      ),
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
        Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 5),
          child: TText(
            title,
            color: MyColor.grey,
          ),
        ),
        AddSpace(
          height: 5,
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: printerList.length,
            itemBuilder: (context, index) {
              final CustomPrinter printer = printerList[index];
              bool isLast = index == printerList.length - 1;
              return Column(
                children: [
                  _buildPrinterButton(printer),
                  if (!isLast)
                    Divider(
                      height: 0,
                      thickness: 0.5,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                ],
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildPrinterButton(CustomPrinter printer) {
    return CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TText(
            printer.name,
            color: MyColor.blue,
          ),
        ),
        onPressed: () {
          superPrinter.connect(printer);
        });
  }

  Future<void> storePrinterPaperSize(PaperSize paperSize) async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String paperSizeString = getPaperSizeString(paperSize);
      sharedPreferences.setString('printerPaperSize', paperSizeString);
    } catch (e) {
      debugPrint('-----> Failed to store printer paper size to local.');
    }
  }

  String getPaperSizeString(PaperSize paperSize) {
    return paperSize == PaperSize.mm58 ? 'mm58' : 'mm80';
  }

  Widget buildContainer({required Widget child, EdgeInsets? margin}) {
    return Container(
      height: conHeight,
      margin: margin,
      padding: EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: child,
    );
  }
}

class PrinterWidget {
  final PType printerType;
  final Widget printerWidget;

  PrinterWidget({required this.printerWidget, required this.printerType});
}
