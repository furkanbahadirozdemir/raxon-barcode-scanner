package expo.modules.raxonbarcodescanner

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class RaxonBarcodeScannerModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("RaxonBarcodeScanner")

    Events("onChange")
  }
}
