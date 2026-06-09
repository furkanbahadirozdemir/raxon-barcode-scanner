export type BarcodeScanPayload = {
  code: string;
  symbology?: string;
};

export type BarcodeScannerOptions = {
  /**
   * DataWedge intent action used for barcode broadcasts.
   * @default "com.raxon.barcode.ACTION"
   */
  intentAction?: string;
  /**
   * DataWedge profile name created or updated for this app.
   * @default "RaxonBarcodeScanner"
   */
  profileName?: string;
  /**
   * Automatically configure a DataWedge profile on Zebra devices.
   * Set to false if you manage DataWedge profiles manually.
   * @default true
   */
  configureDataWedge?: boolean;
  /**
   * Capture input from scanners that act as a keyboard (HID / keyboard-wedge).
   * Keystrokes are buffered and emitted as a single scan when Enter/Tab is
   * received; the keys are swallowed so they don't interact with the UI.
   * @default true
   */
  captureKeyboard?: boolean;
};

export type RaxonBarcodeScannerModuleEvents = {
  onBarcodeScanned: (params: BarcodeScanPayload) => void;
};

export type UseBarcodeScannerResult = {
  isListening: boolean;
};
