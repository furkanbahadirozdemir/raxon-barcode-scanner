import { NativeModule, requireNativeModule } from 'expo';

import {
  BarcodeScannerOptions,
  RaxonBarcodeScannerModuleEvents,
} from './RaxonBarcodeScanner.types';

declare class RaxonBarcodeScannerModule extends NativeModule<RaxonBarcodeScannerModuleEvents> {
  startListening(options?: BarcodeScannerOptions): void;
  stopListening(): void;
}

export default requireNativeModule<RaxonBarcodeScannerModule>('RaxonBarcodeScanner');
