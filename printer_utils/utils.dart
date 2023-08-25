import 'package:flutter_star_prnt/flutter_star_prnt.dart';

String emulationFor(String modelName) {
  String emulation = 'StarGraphic';
  if (modelName != '') {
    final em = StarMicronicsUtilities.detectEmulation(modelName: modelName);
    emulation = em!.emulation!;
  }
  return emulation;
}

String space(int count) {
  return ' ' * count;
}

String dash(int count) {
  return '-' * count;
}

String alignCenter(String text, int totalWidth) {
  if (text.length <= totalWidth) {
    int spaces = (totalWidth - text.length) ~/ 2;
    return ' ' * spaces + text + ' ' * spaces;
  } else {
    List<String> words = text.split(' ');
    List<String> lines = [];
    String currentLine = '';

    for (String word in words) {
      if (currentLine.isEmpty ||
          currentLine.length + word.length + 1 <= totalWidth) {
        if (currentLine.isNotEmpty) {
          currentLine += ' ';
        }
        currentLine += word;
      } else {
        lines.add(alignCenterLine(currentLine, totalWidth));
        currentLine = word;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(alignCenterLine(currentLine, totalWidth));
    }

    return lines.join('\n');
  }
}
String alignCenterLine(String line, int totalWidth) {
  int spaces = (totalWidth - line.length) ~/ 2;
  return ' ' * spaces + line + ' ' * spaces;
}

String extractIPAddress(String input) {
  // Assuming the input string follows the format "TCP:<IP_ADDRESS>"
  List<String> parts = input.split(':');
  if (parts.length == 2 && parts[0] == "TCP") {
    return parts[1];
  } else {
    return "Invalid input";
  }
}
