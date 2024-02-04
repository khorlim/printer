-> Library
#####Printer#####
  flutter_esc_pos_utils: ^1.0.0
  thermal_printer: ^1.0.4
  flutter_star_prnt: ^2.4.1

#####Utils#######
  flutter_isolate: ^2.0.4
  shared_preferences: ^2.2.2
  http: ^1.1.2
  image: ^4.1.3
  network_info_plus: ^4.1.0+1

-> Info.plist
    ---Star printer---
    <key>UISupportedExternalAccessoryProtocols</key>
    <array>
        <string>jp.star-m.starpro</string>
    </array>

    ---Bluetooth permission---
    <key>NSBluetoothAlwaysUsageDescription</key>
    <string>Allow App use bluetooth?</string>
    <key>NSBluetoothPeripheralUsageDescription</key>
    <string>Allow App use bluetooth?</string>
    <key>UIBackgroundModes</key>
    <array>
        <string>bluetooth-central</string>
        <string>bluetooth-peripheral</string>
    </array>

-> Android 
    <uses-permission android:name="android.permission.INTERNET"></uses-permission>
    <uses-permission android:name="android.permission.BLUETOOTH"></uses-permission>


