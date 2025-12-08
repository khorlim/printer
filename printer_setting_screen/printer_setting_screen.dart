import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tunai_widget/tunai_text_field.dart';
import 'package:tunai_widget/tunai_widget.dart';
import '../../../core_utils/tunai_dialog/tunai_dialog.dart';
import '../../../core_utils/tunai_navigator/tunai_navigator.dart';
import '../../../translation/strings.g.dart';
import '../../../tunai_style/common_widgets/input/butt/appbar_butt/text_butt.dart';
import '../../../tunai_style/common_widgets/layout/always_scrollable_center_widget/always_scrollable_center_widget.dart';
import '../../../tunai_style/common_widgets/layout/list_view/tunai_list_view/tunai_animated_list_view.dart';
import '../../../tunai_style/common_widgets/scaffold/appbar/tunai_app_bar.dart';
import '../../../tunai_style/common_widgets/scaffold/tunai_scaffold.dart';
import '../../../tunai_style/common_widgets/typo/default_icon/chevron/default_chevron_down.dart';
import '../../../tunai_style/extension/build_context_extension.dart';
import '../../../tunai_style/widgets/dialog/custom_dialog/src/custom_dialog.dart';
import '../../../tunai_style/widgets/dialog/popup_menu/tunai_popup_menu/tunai_popup_menu.dart';
import '../src/printer_managers/xprinter_manager.dart';

import '../super_printer.dart';
import 'utils/printer_type_storage.dart';
import 'utils/receipt_icon_size_storage.dart';
import 'widget/paper_size_option_menu.dart';
import 'widget/receipt_icon_size_popup_menu.dart';

class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({super.key});

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

enum PrinterType {
  starMicro,
  bluetooth,
  network,
  usb,
  manual,
  ;

  String get name => switch (this) {
        PrinterType.bluetooth => t.bluetooth,
        PrinterType.network => t.network,
        PrinterType.usb => 'USB',
        PrinterType.starMicro => 'Star Micronics',
        PrinterType.manual => t.manual,
      };

  static PrinterType fromName(String name) {
    if (name == PrinterType.starMicro.name) return PrinterType.starMicro;
    if (name == PrinterType.bluetooth.name) return PrinterType.bluetooth;
    if (name == PrinterType.network.name) return PrinterType.network;
    if (name == PrinterType.usb.name) return PrinterType.usb;
    if (name == PrinterType.manual.name) return PrinterType.manual;

    return PrinterType.starMicro;
  }
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  final SuperPrinter superPrinter = SuperPrinter();
  final XPrinterManager xPrinterManager = XPrinterManager();
  final PrinterTypeStorage printerTypeStorage = PrinterTypeStorage();
  final ReceiptIconSizeStorage receiptIconSizeStorage =
      ReceiptIconSizeStorage();

  ReceiptIconSize get selectedReceiptIconSize =>
      receiptIconSizeStorage.fetch() ?? ReceiptIconSize.medium;

  List<CustomPrinter> starPrinterList = [];
  List<CustomPrinter> btPlusPrinterList = [];
  List<CustomPrinter> networkPrinterList = [];
  List<CustomPrinter> usbPrinterList = [];

  late final StreamSubscription<List<CustomPrinter>> btDeviceSubs;
  late final StreamSubscription<List<CustomPrinter>> btPlusDeviceSubs;
  late final StreamSubscription<List<CustomPrinter>> starDeviceSubs;
  late final StreamSubscription<List<CustomPrinter>> networkDeviceSubs;
  late final StreamSubscription<List<CustomPrinter>> usbDeviceSubs;

  late final StreamSubscription<CustomPrinter?> selectedPrinterSubs;
  late final StreamSubscription<PStatus> printerStatusSubs;

  PStatus? printerStatus;
  CustomPrinter? selectedPrinter;
  late PrinterType selectedPrinterType =
      printerTypeStorage.fetch() ?? PrinterType.bluetooth;

  final List<PaperSize> paperSizeList = [
    PaperSize.mm80,
    PaperSize.mm58,
  ];

  late PaperSize selectedPaperSize = paperSizeList.first;

  final double conHeight = 50;

  bool isSearching = false;
  bool searchingStarPrinter = false;
  final TextEditingController manualIpController = TextEditingController();

  @override
  void initState() {
    super.initState();

    selectedPrinterSubs = superPrinter.selectedPrinterStream.listen((event) {
      if (!mounted) return;
      setState(() {
        selectedPrinter = event;
      });
    });
    printerStatusSubs = superPrinter.printerStatusStream.listen((event) {
      if (!mounted) return;
      setState(() {
        printerStatus = event;
      });
    });

    btDeviceSubs = superPrinter.bluePrinterListStream.listen((event) {
      if (!mounted) return;
      setState(() {
        btPlusPrinterList = event.toSet().toList();
      });
    });
    starDeviceSubs = superPrinter.starPrinterListStream.listen((event) {
      if (!mounted) return;
      setState(() {
        starPrinterList = event;
      });
    });
    networkDeviceSubs = superPrinter.networkPrinterListStream.listen((event) {
      if (!mounted) return;
      setState(() {
        networkPrinterList = List.from(event);
      });
    });

    btPlusDeviceSubs = superPrinter.btPlusPrinterListStream.listen((event) {
      if (!mounted) return;
      setState(() {
        btPlusPrinterList = event;
      });
    });

    usbDeviceSubs = superPrinter.usbPrinterListStream.listen((event) {
      if (!mounted) return;
      setState(() {
        usbPrinterList = event;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      superPrinter.checkStatus();
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      final storedPaperSizeString =
          sharedPreferences.getString('printerPaperSize') ?? '';
      selectedPaperSize = getPaperSizeFromString(storedPaperSizeString);

      searchPrinter();
    });
  }

  Future<void> searchPrinter({String? manualGateway}) async {
    setState(() {
      isSearching = true;
    });

    final iminPrinter = await superPrinter.searchForIminPrinter();

    if (iminPrinter != null) {
      bool confirm = await TunaiDialog.showAlertDialog(
        title: 'Imin Printer Found',
        message: 'Do you want to connect to the Imin Printer?',
        action: 'Connect',
      );
      if (confirm) {
        superPrinter.connect(iminPrinter);
      }
    }

    await superPrinter.searchPrinter(
      searchForStarPrinter: selectedPrinterType == PrinterType.starMicro,
      manualGateway: manualGateway,
    );

    setState(() {
      isSearching = false;
    });
  }

  void onPaperSizeChanged(PaperSize size) {
    setState(() {
      selectedPaperSize = size;
      superPrinter.changePaperSize(selectedPaperSize);
    });
    storePrinterPaperSize(selectedPaperSize);
  }

  void onPrinterPressed(CustomPrinter printer) {
    superPrinter.connect(printer);
  }

  void onPrinterTypeChanged(PrinterType type) {
    setState(() {
      selectedPrinterType = type;
    });
    printerTypeStorage.store(type);

    if (type == PrinterType.starMicro) {
      searchPrinter();
    }
  }

  void onDisconnect() async {
    await superPrinter.disconnect();
  }

  @override
  void dispose() {
    btDeviceSubs.cancel();
    starDeviceSubs.cancel();
    networkDeviceSubs.cancel();
    selectedPrinterSubs.cancel();
    printerStatusSubs.cancel();
    usbDeviceSubs.cancel();
    manualIpController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TunaiScaffold(
      resizeToAvoidBottomInset: context.deviceType.isMobile,
      appBar: TunaiAppBar(
        title: Text(t.device),
        actions: [
          if (selectedPrinterType == PrinterType.manual)
            TextButt(
              onPressed: () {
                superPrinter.connect(
                  CustomPrinter(
                    name: '${t.manual} (${manualIpController.text})',
                    address: manualIpController.text,
                    printerType: PType.networkPrinter,
                  ),
                );
              },
              text: t.connect,
            ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsets.only(left: 20.0, right: 20, bottom: 5, top: 10),
        child: Column(
          children: [
            _LabelButt(
              icon: CupertinoIcons.printer,
              title: t.type,
              trailing: _DropDownLabel(
                title: selectedPrinterType.name,
              ),
              onPressed: (context, trailingContext) {
                PrinterTypeOptionMenu(
                  context: trailingContext,
                  onTypeChanged: onPrinterTypeChanged,
                ).show();
              },
            ),
            const TunaiSpace.medium(),
            _LabelButt(
              icon: CupertinoIcons.doc_plaintext,
              title: t.paperSize,
              trailing: _DropDownLabel(
                title: selectedPaperSize.name,
              ),
              onPressed: (context, trailingContext) {
                PaperSizeOptionMenu(
                  context: trailingContext,
                  onSizeChanged: onPaperSizeChanged,
                ).show();
              },
            ),
            const TunaiSpace.medium(),
            _LabelButt(
              icon: CupertinoIcons.doc_text,
              title: t.iconSize,
              trailing: _DropDownLabel(
                title: selectedReceiptIconSize.displayName,
              ),
              onPressed: (context, trailingContext) {
                ReceiptIconSizePopupMenu(
                  selectedSize: selectedReceiptIconSize,
                  onSelected: (size) {
                    receiptIconSizeStorage.store(size);
                    setState(() {});
                  },
                ).show(trailingContext);
              },
            ),
            const TunaiSpace.medium(),
            Builder(builder: (context) {
              bool connecting = printerStatus == PStatus.connecting;
              // bool connected = printerStatus == PStatus.connected;
              bool failedToConnect = printerStatus != null &&
                  selectedPrinter != null &&
                  printerStatus == PStatus.none;
              // bool noDevice = selectedPrinter == null;
              return _LabelButt(
                icon: CupertinoIcons.printer_fill,
                title: t.device,
                trailing: Row(
                  children: [
                    TunaiText(
                      selectedPrinter?.name ?? t.none,
                      color: failedToConnect
                          ? context.color.error
                          : context.color.onBackground,
                    ),
                    if (connecting)
                      const Padding(
                        padding: EdgeInsets.only(left: TunaiSpacing.small),
                        child: CupertinoActivityIndicator(),
                      ),
                  ],
                ),
                onPressed: (context, trailingContext) async {
                  if (failedToConnect) {
                    superPrinter.connect(selectedPrinter!);
                    return;
                  }
                  if (selectedPrinter == null ||
                      selectedPrinter?.printerType == PType.starPrinter) {
                    return;
                  }

                  bool confirm = await TunaiDialog.showAlertDialog(
                    title: t.forgetDevice,
                    message: t.thisActionCannotBeUndone,
                    action: t.forget,
                  );
                  if (confirm) {
                    onDisconnect();
                  }
                },
              );
            }),
            selectedPrinterType == PrinterType.manual
                ? Padding(
                    padding: const EdgeInsets.only(top: TunaiSpacing.medium),
                    child: _LabelButt(
                      icon: CupertinoIcons.globe,
                      title: t.manual,
                      trailing: SizedBox(
                        // height: 50,
                        width: 100,
                        child: TunaiTextField(
                          controller: manualIpController,
                          textAlign: TextAlign.right,
                          hintText: '0.0.0.0',
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 5,
                            bottom: 10,
                            top: 30,
                          ),
                          child: Row(
                            children: [
                              TunaiText(t.nearbyDevices),
                              if (isSearching)
                                const CupertinoActivityIndicator(),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator.adaptive(
                            onRefresh: () async {
                              await searchPrinter();
                            },
                            child: Builder(
                              builder: (context) {
                                final List<CustomPrinter> printers =
                                    switch (selectedPrinterType) {
                                  PrinterType.starMicro => starPrinterList,
                                  PrinterType.bluetooth => btPlusPrinterList,
                                  PrinterType.network => networkPrinterList,
                                  PrinterType.usb => usbPrinterList,
                                  PrinterType.manual => [],
                                };

                                if (printers.isEmpty) {
                                  return AlwaysScrollableCentered(
                                    child: TunaiText(
                                      t.empty,
                                      color: context.color.onBackgroundLow,
                                    ),
                                  );
                                }
                                return Animate(
                                  effects: const [FadeEffect()],
                                  child: _PrinterListView(
                                    printers: printers,
                                    onPrinterPressed: (printer) {
                                      onPrinterPressed(printer);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> storePrinterPaperSize(PaperSize paperSize) async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      sharedPreferences.setString('printerPaperSize', paperSize.name);
    } catch (e) {
      debugPrint('-----> Failed to store printer paper size to local.');
    }
  }
}

class _LabelButt extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final void Function(BuildContext context, BuildContext trailingContext)?
      onPressed;
  final BorderRadius? borderRadius;

  const _LabelButt({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onPressed,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    BuildContext trailingContext = context;
    return TunaiContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: TunaiSpacing.medium,
        vertical: TunaiSpacing.normal,
      ),
      borderRadius: borderRadius,
      onPressed: onPressed == null
          ? null
          : () => onPressed?.call(context, trailingContext),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: context.color.primary,
          ),
          const TunaiSpace.normal(),
          Expanded(
            child: TunaiText(title),
          ),
          Builder(builder: (context) {
            trailingContext = context;
            return trailing;
          }),
        ],
      ),
    );
  }
}

class _DropDownLabel extends StatelessWidget {
  final String title;
  const _DropDownLabel({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TunaiText(title),
        const TunaiSpace.small(),
        const DefaultChevronDown(),
      ],
    );
  }
}

class _PrinterListView extends StatelessWidget {
  final List<CustomPrinter> printers;
  final void Function(CustomPrinter printer) onPrinterPressed;
  const _PrinterListView({
    required this.printers,
    required this.onPrinterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TunaiAnimatedListView<CustomPrinter>(
      items: printers,
      itemBuilder: (printer) {
        bool isFirst = printers.first == printer;
        bool isLast = printers.last == printer;
        return Column(
          children: [
            _LabelButt(
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const TunaiRadius.normal() : Radius.zero,
                bottom: isLast ? const TunaiRadius.normal() : Radius.zero,
              ),
              icon: CupertinoIcons.printer_fill,
              title: printer.name.isEmpty ? printer.address : printer.name,
              trailing: const SizedBox.shrink(),
              onPressed: (context, trailingContext) =>
                  onPrinterPressed(printer),
            ),
          ],
        );
      },
    );
  }
}

class PrinterTypeOptionMenu {
  final BuildContext context;
  final void Function(PrinterType type) onTypeChanged;
  PrinterTypeOptionMenu({
    required this.context,
    required this.onTypeChanged,
  });

  Future<void> show() async {
    late final List<TunaiPopupMenuItem> items = PrinterType.values
        .map((type) => TunaiPopupMenuItem(
            title: type.name,
            onPressed: () {
              TunaiNavigator.pop();
              onTypeChanged(type);
            }))
        .toList();

    return TunaiPopupMenu(
      items: items,
      alignTargetWidget: AlignTargetWidget.centerBottomRight,
    ).show(
      context,
      navigatorContext: TunaiNavigator.currentContext,
    );
  }
}
