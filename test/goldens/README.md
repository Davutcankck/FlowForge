# Golden Dosyaları (`test/goldens/`)

> **UYARI:** n8n golden'ları (`linear.n8n.json`, `if_branch.n8n.json`) **GEÇİCİ**dir; `typeVersion` ve parametre şemaları henüz hedef n8n sürümüne gerçek import yapılarak doğrulanmadı (`TODO(verify-n8n)`).

## Doğrulama Notları (Risk R-01)
- Katalogdaki tüm 10 düğümün `typeVersion` değeri doğrulanana kadar **`1`** (`TODO(verify-n8n)`) olarak tutulur.
- **`httpRequest` parametre notu:** `n8n-nodes-base.httpRequest` düğümünde `method` parametresi n8n `typeVersion: 1` sürümünde `requestMethod` olarak adlandırılıyordu (`method` alanı v3/v4 şemasında kullanılmaktadır). Hedef n8n sürümünde gerçek import doğrulaması yapıldığında `typeVersion` ve `defaultParameters` şeması birlikte güncellenip golden dosyaları yenilenecektir.

## Widget Golden Notu
- `preview_*.png` Windows font render'ına bağlıdır; başka platformda farklı çıkabilir.
