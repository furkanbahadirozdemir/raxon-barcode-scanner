import { NativeModule, requireNativeModule } from 'expo';

import { RaxonBarcodeScannerModuleEvents } from './RaxonBarcodeScanner.types';

declare class RaxonBarcodeScannerModule extends NativeModule<RaxonBarcodeScannerModuleEvents> {}

export default requireNativeModule<RaxonBarcodeScannerModule>('RaxonBarcodeScanner');
