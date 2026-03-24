import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

/// BLE ATT default; max unfragmented write payload is [mtu - 3] → 20 bytes.
const int _minAttPayload = 20;

/// Common BLE serial / ESC-POS-over-GATT data paths (central → peripheral).
const List<String> _preferredDataCharacteristicUuids = [
  '0000ffe1-0000-1000-8000-00805f9b34fb',
  '6e400002-b5a3-f393-e0a9-e50e24dcca9e',
  '49535343-8841-43f4-a8d4-ecbe34729bb3',
  '0000ff01-0000-1000-8000-00805f9b34fb',
  '0000fff2-0000-1000-8000-00805f9b34fb',
  '0000ff02-0000-1000-8000-00805f9b34fb',
];

const List<String> _preferredDataServiceUuids = [
  '0000ffe0-0000-1000-8000-00805f9b34fb',
  '6e400001-b5a3-f393-e0a9-e50e24dcca9e',
  '49535343-fe7d-4ae5-8fa9-9fafd205e455',
];

/// Picked GATT target for raw thermal bytes (avoids "first write char" = control endpoint).
class ThermalBleWriteTarget {
  const ThermalBleWriteTarget({
    required this.characteristic,
    required this.withResponse,
    required this.serviceUuid,
    required this.characteristicUuid,
  });

  final BleCharacteristic characteristic;
  final bool withResponse;
  final String serviceUuid;
  final String characteristicUuid;
}

int _thermalCandidateScore(BleService service, BleCharacteristic c) {
  var score = 0;
  for (var i = 0; i < _preferredDataCharacteristicUuids.length; i++) {
    if (BleUuidParser.compareStrings(c.uuid, _preferredDataCharacteristicUuids[i])) {
      score += 2000 - i;
      break;
    }
  }
  for (var i = 0; i < _preferredDataServiceUuids.length; i++) {
    if (BleUuidParser.compareStrings(service.uuid, _preferredDataServiceUuids[i])) {
      score += 500 - i;
      break;
    }
  }
  if (c.properties.contains(CharacteristicProperty.writeWithoutResponse)) {
    score += 50;
  }
  if (c.properties.contains(CharacteristicProperty.write)) {
    score += 10;
  }
  return score;
}

bool _withResponseForThermalWrite(BleCharacteristic c) {
  final hasWwr =
      c.properties.contains(CharacteristicProperty.writeWithoutResponse);
  final hasW = c.properties.contains(CharacteristicProperty.write);
  if (hasWwr) {
    return false;
  }
  if (hasW) {
    return true;
  }
  return true;
}

/// Chooses a writable characteristic likely to accept ESC/POS payload, not DFU/config.
ThermalBleWriteTarget? pickThermalBleWriteTarget(List<BleService> services) {
  ThermalBleWriteTarget? best;
  var bestScore = -1;
  for (final service in services) {
    for (final c in service.characteristics) {
      final hasWwr =
          c.properties.contains(CharacteristicProperty.writeWithoutResponse);
      final hasW = c.properties.contains(CharacteristicProperty.write);
      if (!hasWwr && !hasW) {
        continue;
      }
      final s = _thermalCandidateScore(service, c);
      if (s > bestScore) {
        bestScore = s;
        best = ThermalBleWriteTarget(
          characteristic: c,
          withResponse: _withResponseForThermalWrite(c),
          serviceUuid: service.uuid,
          characteristicUuid: c.uuid,
        );
      }
    }
  }
  return best;
}

/// Request a high MTU from the peripheral; Android often negotiates up to ~517.
Future<int> negotiatedMaxWritePayload(
  BleDevice device, {
  int requestedMtu = 512,
  int maxCap = 512,
}) async {
  try {
    final mtu = await device.requestMtu(requestedMtu);
    var payload = mtu - 3;
    if (payload < _minAttPayload) {
      payload = _minAttPayload;
    }
    if (payload > maxCap) {
      payload = maxCap;
    }
    debugPrint('BLE MTU=$mtu → max write payload=$payload');
    return payload;
  } catch (e) {
    debugPrint('requestMtu failed, using $_minAttPayload-byte chunks: $e');
    return _minAttPayload;
  }
}

Future<void> writeBytesInAttChunks(
  BleCharacteristic character,
  List<int> bytes, {
  required bool withResponse,
  required int maxPayload,
  Duration? delayBetweenChunks,
}) async {
  final totalBytes = bytes.length;
  if (totalBytes == 0) return;
  final chunkSize = maxPayload < 1 ? _minAttPayload : maxPayload;
  final totalChunks = (totalBytes / chunkSize).ceil();
  for (var i = 0; i < totalChunks; i++) {
    final start = i * chunkSize;
    var end = start + chunkSize;
    if (end > totalBytes) {
      end = totalBytes;
    }
    await character.write(
      bytes.sublist(start, end),
      withResponse: withResponse,
    );

    if (delayBetweenChunks != null) {
      await Future.delayed(delayBetweenChunks);
    }
  }
}
