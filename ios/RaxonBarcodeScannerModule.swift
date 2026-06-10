import ExpoModulesCore
import UIKit

// MARK: - RaxonBarcodeScannerModule

/// iOS için Bluetooth ve HID barkod okuyucu desteği sağlayan Expo modülü.
/// Harici klavye olarak davranan Bluetooth barkod okuyucuların tuş vuruşlarını yakalar.
public final class RaxonBarcodeScannerModule: Module {
    private var isListening = false
    private var captureKeyboard = true
    private var keyboardHandler: ExternalKeyboardHandler?

    public required init(appContext: AppContext) {
        super.init(appContext: appContext)
    }

    public func definition() -> ModuleDefinition {
        Name("RaxonBarcodeScanner")

        Events("onBarcodeScanned")

        Function("startListening") { (options: [String: Any]?) in
            self.startListening(options: options)
        }

        Function("stopListening") {
            self.stopListening()
        }

        OnDestroy {
            self.stopListening()
        }
    }

    private func startListening(options: [String: Any]?) {
        guard !isListening else {
            stopListening()
        }

        captureKeyboard = options?["captureKeyboard"] as? Bool ?? true

        if captureKeyboard {
            setupKeyboardCapture()
        }

        isListening = true
    }

    private func stopListening() {
        teardownKeyboardCapture()
        isListening = false
    }

    private func setupKeyboardCapture() {
        guard let viewController = appContext?.currentViewController else {
            return
        }

        if #available(iOS 13.4, *) {
            keyboardHandler = ExternalKeyboardHandler(
                viewController: viewController,
                onBarcodeScanned: { [weak self] code in
                    self?.sendEvent("onBarcodeScanned", ["code": code])
                }
            )
            keyboardHandler?.startListening()
        }
    }

    private func teardownKeyboardCapture() {
        keyboardHandler?.stopListening()
        keyboardHandler = nil
    }
}

// MARK: - ExternalKeyboardHandler

/// iOS 13.4+ için harici klavye (Bluetooth barkod okuyucu) girişini yakalayan sınıf.
/// pressesBegan/pressesEnded API'sini kullanarak fiziksel klavye tuşlarını yakalar.
@available(iOS 13.4, *)
private final class ExternalKeyboardHandler {
    private weak var viewController: UIViewController?
    private let onBarcodeScanned: (String) -> Void
    private var keyBuffer: String = ""
    private var lastKeyTime: TimeInterval = 0
    private let bufferTimeout: TimeInterval = 1.0

    // Terminatör tuş kodları
    private let terminatorKeyCodes: Set<Int> = [
        36,  // Return/Enter
        76,  // Numpad Enter
        48,  // Tab
        52,  // Numpad Equal (bazı okuyucularda)
        67,  // Numpad Asterisk (bazı okuyucularda)
    ]

    init(viewController: UIViewController, onBarcodeScanned: @escaping (String) -> Void) {
        self.viewController = viewController
        self.onBarcodeScanned = onBarcodeScanned
    }

    func startListening() {
        // pressesBegan/pressesEnded metodlarını sarmalamak için swizzling kullanacağız
        swizzlePressesMethods()

        // Ayrıca UIResponder chain'den gelen tuş olaylarını da dinle
        setupKeyCommandHandling()
    }

    func stopListening() {
        unswizzlePressesMethods()
        keyBuffer = ""
    }

    private func setupKeyCommandHandling() {
        // UIKeyCommand kullanarak bazı özel tuşları yakalayabiliriz
        // Ancak tüm tuşları yakalamak için pressesBegan/pressesEnded daha iyi
    }

    // MARK: - Tuş İşleme

    func handlePress(_ press: UIPress) -> Bool {
        guard let key = press.key else { return false }

        let keyCode = key.keyCode.rawValue
        let now = Date().timeIntervalSince1970

        // Zaman aşımı kontrolü - tuşlar arası 1 saniyeden fazla varsa tamponu sıfırla
        if now - lastKeyTime > bufferTimeout {
            keyBuffer = ""
        }
        lastKeyTime = now

        // Terminatör tuş kontrolü
        if isTerminator(keyCode) {
            if !keyBuffer.isEmpty {
                let code = keyBuffer
                keyBuffer = ""
                onBarcodeScanned(code)
                return true // Tuşu yut
            }
            // Tampon boşken terminatörü normal davranışa bırak
            return false
        }

        // Karakter tuşu mu?
        if let char = characterFromKey(key) {
            keyBuffer.append(char)
            return true // Tuşu yut (UI'ya ulaşmasını engelle)
        }

        return false
    }

    private func isTerminator(_ keyCode: Int) -> Bool {
        return terminatorKeyCodes.contains(keyCode)
    }

    private func characterFromKey(_ key: UIKey) -> Character? {
        // Karakter önceliği:
        // 1. modifiersiz karakter (temel ASCII)
        // 2. modifiers varsa ve shift varsa büyük harf

        var char: Character?

        // UIKey.characters ile dene
        if let chars = key.characters, !chars.isEmpty {
            char = chars.first
        }

        // UIKey.charactersIgnoringModifiers ile dene (Shift/Ctrl/Alt olmadan)
        if char == nil, let chars = key.charactersIgnoringModifiers, !chars.isEmpty {
            char = chars.first
        }

        // Eğer hala nil ise, keyCode'dan çevir
        if char == nil {
            char = characterFromKeyCode(key.keyCode.rawValue)
        }

        return char
    }

    private func characterFromKeyCode(_ keyCode: Int) -> Character? {
        // iOS fiziksel klavye key kodlarından karakter dönüşümü
        // Bluetooth barkod okuyucular genellikle standart USB HID key kodları kullanır
        let mapping: [Int: Character] = [
            // Rakamlar (ana klavye)
            23: "0", 22: "1", 26: "2", 20: "3", 25: "4",
            29: "5", 27: "6", 24: "7", 28: "8", 21: "9",

            // Numpad rakamlar
            98: "0", 89: "1", 90: "2", 91: "3", 92: "4",
            93: "5", 94: "6", 95: "7", 96: "8", 97: "9",

            // Harfler (ana klavye)
            12: "q", 13: "w", 14: "e", 15: "r", 17: "t",
            16: "y", 32: "u", 34: "i", 31: "o", 35: "p",
            0: "a", 1: "s", 2: "d", 3: "f", 5: "g",
            4: "h", 38: "k", 37: "j", 40: "l", 6: "z",
            7: "x", 8: "c", 9: "v", 11: "b", 45: "n",
            46: "m",

            // Özel karakterler
            51: "\u{0008}", // Backspace (silme)
            117: "\u{007F}", // Delete
            42: ",", 43: "-", 44: ".", 47: "/",
            39: "'", 33: "[", 30: "]", 41: ";", 50: "`",
            115: "\u{001B}", // Escape

            // Boşluk
            49: " ",
        ]

        return mapping[keyCode]
    }

    // MARK: - Method Swizzling

    private func swizzlePressesMethods() {
        guard let viewController = viewController else { return }

        let originalPressesBeganSelector = #selector(UIViewController.pressesBegan(_:with:))
        let swizzledPressesBeganSelector = #selector(UIViewController.raxon_pressesBegan(_:with:))

        let originalPressesEndedSelector = #selector(UIViewController.pressesEnded(_:with:))
        let swizzledPressesEndedSelector = #selector(UIViewController.raxon_pressesEnded(_:with:))

        swizzleMethod(
            for: UIViewController.self,
            originalSelector: originalPressesBeganSelector,
            swizzledSelector: swizzledPressesBeganSelector
        )

        swizzleMethod(
            for: UIViewController.self,
            originalSelector: originalPressesEndedSelector,
            swizzledSelector: swizzledPressesEndedSelector
        )

        // Bu view controller'a weak referans ile handler'a erişim sağla
        objc_setAssociatedObject(
            viewController,
            &AssociatedKeys.keyboardHandler,
            self,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    private func unswizzlePressesMethods() {
        // Method swizzling geri alınamaz ama handler'ı temizleyebiliriz
        if let viewController = viewController {
            objc_setAssociatedObject(
                viewController,
                &AssociatedKeys.keyboardHandler,
                nil,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private func swizzleMethod(
        for classType: AnyClass,
        originalSelector: Selector,
        swizzledSelector: Selector
    ) {
        guard let originalMethod = class_getInstanceMethod(classType, originalSelector),
              let swizzledMethod = class_getInstanceMethod(classType, swizzledSelector) else {
            return
        }

        let didAddMethod = class_addMethod(
            classType,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )

        if didAddMethod {
            class_replaceMethod(
                classType,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

// MARK: - UIViewController Extension

private var AssociatedKeys = (
    keyboardHandler: "raxon_keyboardHandler"
)

@available(iOS 13.4, *)
extension UIViewController {
    @objc dynamic func raxon_pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        // Orijinal implementasyonu çağır (swizzling yüzünden bu aslında orijinal)
        raxon_pressesBegan(presses, with: event)

        // Handler varsa tuşları işle
        if let handler = objc_getAssociatedObject(self, &AssociatedKeys.keyboardHandler)
            as? ExternalKeyboardHandler {
            for press in presses {
                _ = handler.handlePress(press)
            }
        }
    }

    @objc dynamic func raxon_pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        // Orijinal implementasyonu çağır
        raxon_pressesEnded(presses, with: event)
    }
}

// MARK: - UIKey Extensions

@available(iOS 13.4, *)
extension UIKey {
    var keyCode: UIKeyboardHIDUsage {
        return self.keyCode
    }
}