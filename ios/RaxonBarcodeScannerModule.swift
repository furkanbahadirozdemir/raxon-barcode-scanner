import ExpoModulesCore
import GameController
import UIKit

// MARK: - RaxonBarcodeScannerModule

/// iOS için Bluetooth ve HID barkod okuyucu desteği sağlayan Expo modülü.
/// GameController framework'ün GCKeyboard API'si ile donanım klavyesi tuşlarını
/// responder chain'den bağımsız olarak, sistem seviyesinde yakalar.
public final class RaxonBarcodeScannerModule: Module {
    private var isListening = false
    private var keyboardMonitor: HardwareKeyboardMonitor?

    public required init(appContext: AppContext) {
        super.init(appContext: appContext)
    }

    public func definition() -> ModuleDefinition {
        Name("RaxonBarcodeScanner")

        Events("onBarcodeScanned")

        AsyncFunction("startListening") { (options: [String: Any]?) in
            await MainActor.run {
                self.startListening(options: options)
            }
        }

        AsyncFunction("stopListening") {
            await MainActor.run {
                self.stopListening()
            }
        }

        OnDestroy {
            self.stopListening()
        }
    }

    private func startListening(options: [String: Any]?) {
        guard !isListening else { return }

        let captureKeyboard = options?["captureKeyboard"] as? Bool ?? true

        if captureKeyboard {
            let monitor = HardwareKeyboardMonitor()
            monitor.onBarcodeScanned = { [weak self] code in
                self?.sendEvent("onBarcodeScanned", ["code": code])
            }
            monitor.start()
            keyboardMonitor = monitor
        }

        isListening = true
    }

    private func stopListening() {
        keyboardMonitor?.stop()
        keyboardMonitor = nil
        isListening = false
    }
}

// MARK: - HardwareKeyboardMonitor

/// GCKeyboard ile donanım klavyesi (Bluetooth barkod okuyucu) girişini izler.
/// Responder chain'e bağımlı olmadığı için tuş kaybı yaşanmaz ve
/// ekrandaki input'lar ile etkileşime girmez.
private final class HardwareKeyboardMonitor {
    var onBarcodeScanned: ((String) -> Void)?

    private var keyBuffer = ""
    private var lastKeyTime: TimeInterval = 0
    // Tuşlar arası bu süre aşılırsa tampon sıfırlanır (insan yazısını barkoddan ayırır)
    private let bufferTimeout: TimeInterval = 0.5
    private var connectObserver: NSObjectProtocol?
    private var attachedInputs: [ObjectIdentifier: GCKeyboardInput] = [:]

    func start() {
        // Halihazırda bağlı klavye varsa hemen dinlemeye başla
        attach(to: GCKeyboard.coalesced)

        // Sonradan bağlanan klavyeler (örn. Bluetooth okuyucu) için bildirim dinle
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.attach(to: notification.object as? GCKeyboard)
        }
    }

    func stop() {
        if let connectObserver {
            NotificationCenter.default.removeObserver(connectObserver)
        }
        connectObserver = nil

        for (_, input) in attachedInputs {
            input.keyChangedHandler = nil
        }
        attachedInputs.removeAll()
        keyBuffer = ""
    }

    private func attach(to keyboard: GCKeyboard?) {
        guard let input = keyboard?.keyboardInput else { return }

        let id = ObjectIdentifier(input)
        guard attachedInputs[id] == nil else { return }
        attachedInputs[id] = input

        input.keyChangedHandler = { [weak self] keyboardInput, _, keyCode, pressed in
            guard pressed else { return }
            self?.handleKey(keyCode, input: keyboardInput)
        }
    }

    private func handleKey(_ keyCode: GCKeyCode, input: GCKeyboardInput) {
        let now = Date().timeIntervalSince1970
        if now - lastKeyTime > bufferTimeout {
            keyBuffer = ""
        }
        lastKeyTime = now

        // Terminatör: Enter / Numpad Enter / Tab
        if keyCode == .returnOrEnter || keyCode == .keypadEnter || keyCode == .tab {
            let code = keyBuffer
            keyBuffer = ""
            if !code.isEmpty {
                let callback = onBarcodeScanned
                DispatchQueue.main.async {
                    callback?(code)
                }
            }
            return
        }

        let shiftPressed =
            input.button(forKeyCode: .leftShift)?.isPressed == true ||
            input.button(forKeyCode: .rightShift)?.isPressed == true

        if let char = Self.character(for: keyCode, shifted: shiftPressed) {
            keyBuffer.append(char)
        }
    }

    // MARK: - GCKeyCode → Karakter eşleştirmesi

    private static func character(for keyCode: GCKeyCode, shifted: Bool) -> Character? {
        if let letter = letters[keyCode] {
            return shifted ? Character(letter.uppercased()) : letter
        }
        if let pair = symbols[keyCode] {
            return shifted ? pair.shifted : pair.normal
        }
        return keypad[keyCode]
    }

    private static let letters: [GCKeyCode: Character] = [
        .keyA: "a", .keyB: "b", .keyC: "c", .keyD: "d", .keyE: "e",
        .keyF: "f", .keyG: "g", .keyH: "h", .keyI: "i", .keyJ: "j",
        .keyK: "k", .keyL: "l", .keyM: "m", .keyN: "n", .keyO: "o",
        .keyP: "p", .keyQ: "q", .keyR: "r", .keyS: "s", .keyT: "t",
        .keyU: "u", .keyV: "v", .keyW: "w", .keyX: "x", .keyY: "y",
        .keyZ: "z",
    ]

    private static let symbols: [GCKeyCode: (normal: Character, shifted: Character)] = [
        .one: ("1", "!"), .two: ("2", "@"), .three: ("3", "#"),
        .four: ("4", "$"), .five: ("5", "%"), .six: ("6", "^"),
        .seven: ("7", "&"), .eight: ("8", "*"), .nine: ("9", "("),
        .zero: ("0", ")"),
        .spacebar: (" ", " "),
        .hyphen: ("-", "_"),
        .equalSign: ("=", "+"),
        .openBracket: ("[", "{"),
        .closeBracket: ("]", "}"),
        .backslash: ("\\", "|"),
        .semicolon: (";", ":"),
        .quote: ("'", "\""),
        .graveAccentAndTilde: ("`", "~"),
        .comma: (",", "<"),
        .period: (".", ">"),
        .slash: ("/", "?"),
    ]

    private static let keypad: [GCKeyCode: Character] = [
        .keypad0: "0", .keypad1: "1", .keypad2: "2", .keypad3: "3",
        .keypad4: "4", .keypad5: "5", .keypad6: "6", .keypad7: "7",
        .keypad8: "8", .keypad9: "9",
        .keypadSlash: "/", .keypadAsterisk: "*",
        .keypadHyphen: "-", .keypadPlus: "+",
        .keypadPeriod: ".", .keypadEqualSign: "=",
    ]
}
