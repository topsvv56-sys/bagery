// เลือกตัวเปิดฐานข้อมูล SQLite ให้เหมาะกับแต่ละแพลตฟอร์ม
// - Android / iOS / macOS : sqflite ปกติ
// - Windows / Linux       : sqflite_common_ffi
// - Web                   : sqflite_common_ffi_web
export 'db_factory_stub.dart'
    if (dart.library.io) 'db_factory_io.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';

