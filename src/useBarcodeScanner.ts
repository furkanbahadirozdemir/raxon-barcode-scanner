import { useEffect, useRef } from 'react';

import {
  BarcodeScanPayload,
  BarcodeScannerOptions,
  UseBarcodeScannerResult,
} from './RaxonBarcodeScanner.types';
import RaxonBarcodeScanner from './RaxonBarcodeScannerModule';

export function useBarcodeScanner(
  enabled: boolean,
  onReadBarcode: (payload: BarcodeScanPayload) => void,
  options?: BarcodeScannerOptions
): UseBarcodeScannerResult {
  const onReadBarcodeRef = useRef(onReadBarcode);

  useEffect(() => {
    onReadBarcodeRef.current = onReadBarcode;
  });

  useEffect(() => {
    if (!enabled) {
      return;
    }

    let subscription: { remove: () => void } | null = null;

    (async () => {
      await RaxonBarcodeScanner.startListening(options ?? {});

      subscription = RaxonBarcodeScanner.addListener('onBarcodeScanned', (event) => {
        onReadBarcodeRef.current(event);
      });
    })();

    return () => {
      subscription?.remove();
      RaxonBarcodeScanner.stopListening();
    };
  }, [
    enabled,
    options?.intentAction,
    options?.profileName,
    options?.configureDataWedge,
    options?.captureKeyboard,
  ]);

  return { isListening: enabled };
}
