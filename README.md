# raxon-barcode-scanner

Zebra ve benzeri kurumsal Android cihazlarda fiziksel barkod okuyucudan gelen veriyi React Native / Expo uygulamanıza aktaran hook tabanlı paket.

## Özellikler

- `useBarcodeScanner` hook ile basit entegrasyon
- Zebra DataWedge profilini otomatik oluşturma / güncelleme
- Klavye gibi davranan (HID / keyboard-wedge) okuyucu desteği: tuş vuruşları tamponlanır, Enter/Tab ile tek barkod olarak yayınlanır ve UI'a sızmaz
- Android 13+ broadcast receiver uyumluluğu
- Expo Modules API ile autolinking

## Kurulum

```bash
npm install raxon-barcode-scanner
```

Expo projelerinde development build veya `expo prebuild` gerekir. Expo Go içinde native modül çalışmaz.

```bash
npx expo prebuild
npx expo run:android
```

## Kullanım

```tsx
import { useCallback, useState } from 'react';
import { useBarcodeScanner } from 'raxon-barcode-scanner';

function ScannerScreen() {
  const [enabled, setEnabled] = useState(true);

  const onReadBarcode = useCallback((payload) => {
    console.log(payload.code, payload.symbology);
  }, []);

  const scanner = useBarcodeScanner(enabled, onReadBarcode);

  return (
    <>
      <Switch value={enabled} onValueChange={setEnabled} />
      <Text>{scanner.isListening ? 'Dinleniyor' : 'Kapalı'}</Text>
    </>
  );
}
```

`Switch` ve `Text` için `react-native` importunu eklemeyi unutmayın.

`enabled` değeri `true` olduğu sürece native dinleyici açık kalır. `false` yapıldığında dinleyici kapanır.

### Gelişmiş ayarlar

```tsx
useBarcodeScanner(enabled, onReadBarcode, {
  intentAction: 'com.myapp.barcode.ACTION',
  profileName: 'MyAppScanner',
  configureDataWedge: true,
  captureKeyboard: true,
});
```

| Seçenek | Varsayılan | Açıklama |
| --- | --- | --- |
| `intentAction` | `com.raxon.barcode.ACTION` | DataWedge broadcast action |
| `profileName` | `RaxonBarcodeScanner` | DataWedge profil adı |
| `configureDataWedge` | `true` | Profili otomatik yapılandır |
| `captureKeyboard` | `true` | Klavye modundaki (HID) okuyucuları yakala |

`configureDataWedge: false` kullanın eğer DataWedge profilini MDM veya manuel olarak yönetiyorsanız. Bu durumda `intentAction` değerinin profildeki Intent Output action ile eşleşmesi gerekir.

## Test projesi

Depodaki `example` uygulaması modülü test etmek içindir.

```bash
cd example
npm install
npm run android
```

Kök dizinden:

```bash
npm run open:android
```

## Desteklenen cihazlar

- Zebra TC serisi ve DataWedge yüklü cihazlar
- DataWedge Intent Output ile broadcast gönderen diğer kurumsal Android cihazlar
- Klavye (HID / keyboard-wedge) modunda çalışan okuyucular ve el terminalleri

## npm yayını

```bash
npm run build
npm publish --access public
```

## Lisans

MIT
