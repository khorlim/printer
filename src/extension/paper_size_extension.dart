part of '../super_printer.dart';

List<PaperSize> allPaperSizes = [
  PaperSize.mm80,
  PaperSize.mm58,
];

PaperSize getPaperSizeFromString(String size) {
  return switch (size) {
    '80mm' => PaperSize.mm80,
    '58mm' => PaperSize.mm58,
    '72mm' => PaperSize.mm72,
    _ => PaperSize.mm80,
  };
}

extension PaperSizeExtension on PaperSize {
  String get name => switch (this) {
        PaperSize.mm80 => '80mm',
        PaperSize.mm58 => '58mm',
        PaperSize.mm72 => '72mm',
        _ => '',
      };
}
