import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showAlertDialog(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

class CupertinoLoadingDialog extends StatelessWidget {
  final String title;

  const CupertinoLoadingDialog({super.key,  this.title = "Loading"});
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoActivityIndicator(),
          SizedBox(width: 16),
          Text("$title"),
        ],
      ),
    );
  }
}

// Example of using the CupertinoLoadingDialog:

void showLoadingDialog(BuildContext context, String? title) {
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing the dialog on tap outside
    builder: (BuildContext context) {
      return CupertinoLoadingDialog(title: title!,);
    },
  );
}

void hideLoadingDialog(BuildContext context) {
  Navigator.pop(context);
}