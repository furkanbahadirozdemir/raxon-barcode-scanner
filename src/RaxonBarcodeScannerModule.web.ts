import { registerWebModule, NativeModule } from 'expo';

import { RaxonBarcodeScannerModuleEvents } from './RaxonBarcodeScanner.types';

// RaxonBarcodeScannerModule is not available on the web platform.
class RaxonBarcodeScannerModule extends NativeModule<RaxonBarcodeScannerModuleEvents> {}

export default registerWebModule(RaxonBarcodeScannerModule, 'RaxonBarcodeScannerModule');
