import { registerWebModule, NativeModule } from 'expo';

import {
  BarcodeScannerOptions,
  RaxonBarcodeScannerModuleEvents,
} from './RaxonBarcodeScanner.types';

class RaxonBarcodeScannerModule extends NativeModule<RaxonBarcodeScannerModuleEvents> {
  startListening(_options?: BarcodeScannerOptions): void {
    console.warn('raxon-barcode-scanner is only supported on Android.');
  }

  stopListening(): void {
    // no-op
  }
}

export default registerWebModule(RaxonBarcodeScannerModule, 'RaxonBarcodeScanner');
