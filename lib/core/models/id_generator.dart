import 'package:uuid/uuid.dart';

/// Benzersiz kimlik üreten arayüz.
///
/// Üretimde UUID v4, testlerde sıralı (`id-1`, `id-2`, …) implementasyon
/// kullanılarak golden dosyalarla karakteri karakterine karşılaştırma yapılabilir.
abstract class IdGenerator {
  String next();
}

/// Sıralı id üreten test implementasyonu: id-1, id-2, ...
class SequentialIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String next() {
    _counter++;
    return 'id-$_counter';
  }
}

/// Üretim ortamında UUID v4 üreten implementasyon.
class UuidIdGenerator implements IdGenerator {
  final Uuid _uuid;

  UuidIdGenerator({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  @override
  String next() => _uuid.v4();
}
