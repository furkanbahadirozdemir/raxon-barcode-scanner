// Reexport the native module. On web, it will be resolved to RaxonBarcodeScannerModule.web.ts
// and on native platforms to RaxonBarcodeScannerModule.ts
export { default } from './RaxonBarcodeScannerModule';
export * from './RaxonBarcodeScanner.types';
