import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core_utils/tunai_navigator/tunai_navigator.dart';
import '../../../tunai_style/widgets/custom_dialog/dialog_manager/dialog_manager.dart';
import '../../../tunai_style/style_imports.dart';

Future<void> showChangePrinterIpDialog({
  String? initialIP,
  required Future<void> Function(String currentIp, String newIp) onConfirm,
}) async {
  return await DialogManager(
          context: TunaiNavigator.currentContext,
          child: ChangeIpPage(initialIP: initialIP, onConfirm: onConfirm))
      .show();
}

class ChangeIpPage extends StatefulWidget {
  final String? initialIP;
  final Future<void> Function(String currentIp, String newIp) onConfirm;

  const ChangeIpPage({super.key, required this.onConfirm, this.initialIP});

  @override
  State<ChangeIpPage> createState() => _ChangeIpPageState();
}

class _ChangeIpPageState extends State<ChangeIpPage> {
  bool isLoading = false;
  late final TextEditingController currentPrinterIpController =
      TextEditingController(text: widget.initialIP);
  final TextEditingController newPrinterIpController = TextEditingController();

  bool get canConfirm =>
      currentPrinterIpController.text.isNotEmpty &&
      newPrinterIpController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: getDeviceType(context) == DeviceType.mobile,
      appBar: TunaiAppBar(
        elevation: 0,
        title: Text('Change Ip Address'),
        leading: CloseButt(),
        actions: [
          if (canConfirm)
            AppBarButt(
                title: t.confirm,
                onPressed: () async {
                  try {
                    await widget.onConfirm(
                      currentPrinterIpController.text,
                      newPrinterIpController.text,
                    );
                  } catch (e) {}
                })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            buildTextField(
              hint: 'Current Printer IP Address',
              controller: currentPrinterIpController,
            ),
            const SizedBox(
              height: 10,
            ),
            buildTextField(
              hint: 'New Printer IP Address',
              controller: newPrinterIpController,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
      {required String hint, required TextEditingController controller}) {
    return TunaiTextField(
      controller: controller,
      hintText: hint,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[0-9.]'),
        ),
      ],
      onChanged: (value) {
        setState(() {});
      },
    );
  }
}
