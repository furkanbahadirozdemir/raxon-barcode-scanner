package expo.modules.raxonbarcodescanner

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class RaxonBarcodeScannerModule : Module() {
  companion object {
    private const val DEFAULT_INTENT_ACTION = "com.raxon.barcode.ACTION"
    private const val DEFAULT_PROFILE_NAME = "RaxonBarcodeScanner"
    private const val DATAWEDGE_API_ACTION = "com.symbol.datawedge.api.ACTION"
    private const val DATAWEDGE_RESULT_ACTION = "com.symbol.datawedge.api.RESULT_ACTION"
    private const val DATAWEDGE_PACKAGE = "com.symbol.datawedge"
    private const val SET_CONFIG_EXTRA = "com.symbol.datawedge.api.SET_CONFIG"

    private val BARCODE_DATA_KEYS = listOf(
      "com.symbol.datawedge.data_string",
      "com.motorolasolutions.emdk.datawedge.data_string",
      "data",
      "barcode_string",
      "SCAN_BARCODE1",
      "barcode"
    )

    private val SYMBOLOGY_KEYS = listOf(
      "com.symbol.datawedge.label_type",
      "com.motorolasolutions.emdk.datawedge.label_type",
      "label_type",
      "aimId"
    )
  }

  private var broadcastReceiver: BroadcastReceiver? = null
  private var isListening = false

  private val context: Context
    get() = requireNotNull(appContext.reactContext)

  override fun definition() = ModuleDefinition {
    Name("RaxonBarcodeScanner")

    Events("onBarcodeScanned")

    Function("startListening") { options: Map<String, Any?>? ->
      startListening(options)
    }

    Function("stopListening") {
      stopListening()
    }

    OnDestroy {
      stopListening()
    }
  }

  private fun startListening(options: Map<String, Any?>?) {
    if (isListening) {
      stopListening()
    }

    val intentAction = (options?.get("intentAction") as? String)?.takeIf { it.isNotBlank() }
      ?: DEFAULT_INTENT_ACTION
    val profileName = (options?.get("profileName") as? String)?.takeIf { it.isNotBlank() }
      ?: DEFAULT_PROFILE_NAME
    val configureDataWedge = options?.get("configureDataWedge") as? Boolean ?: true

    if (configureDataWedge) {
      configureDataWedgeProfile(profileName, intentAction)
    }

    registerBarcodeReceiver(intentAction)
    isListening = true
  }

  private fun stopListening() {
    broadcastReceiver?.let { receiver ->
      try {
        context.unregisterReceiver(receiver)
      } catch (_: IllegalArgumentException) {
        // Receiver was already unregistered.
      }
    }
    broadcastReceiver = null
    isListening = false
  }

  private fun registerBarcodeReceiver(intentAction: String) {
    val filter = IntentFilter().apply {
      addAction(intentAction)
      addAction(DATAWEDGE_RESULT_ACTION)
      addCategory(Intent.CATEGORY_DEFAULT)
    }

    val receiver = object : BroadcastReceiver() {
      override fun onReceive(ctx: Context?, intent: Intent?) {
        intent ?: return
        handleIntent(intent)
      }
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      context.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
    } else {
      @Suppress("UnspecifiedRegisterReceiverFlag")
      context.registerReceiver(receiver, filter)
    }

    broadcastReceiver = receiver
  }

  private fun handleIntent(intent: Intent) {
    val action = intent.action ?: return

    if (action == DATAWEDGE_RESULT_ACTION) {
      return
    }

    val code = BARCODE_DATA_KEYS.firstNotNullOfOrNull { key ->
      intent.getStringExtra(key)?.takeIf { it.isNotBlank() }
    } ?: return

    val symbology = SYMBOLOGY_KEYS.firstNotNullOfOrNull { key ->
      intent.getStringExtra(key)?.takeIf { it.isNotBlank() }
    }

    val payload = mutableMapOf<String, Any>("code" to code)
    symbology?.let { payload["symbology"] = it }

    sendEvent("onBarcodeScanned", payload)
  }

  private fun configureDataWedgeProfile(profileName: String, intentAction: String) {
    val packageName = context.packageName

    val barcodePlugin = Bundle().apply {
      putString("PLUGIN_NAME", "BARCODE")
      putString("RESET_CONFIG", "true")
      putString("scanner_selection", "auto")
      putString("scanner_input_enabled", "true")
    }

    val appList = Bundle().apply {
      putString("PACKAGE_NAME", packageName)
      putStringArray("ACTIVITY_LIST", arrayOf("*"))
    }

    val profileConfig = Bundle().apply {
      putString("PROFILE_NAME", profileName)
      putString("PROFILE_ENABLED", "true")
      putString("CONFIG_MODE", "CREATE_IF_NOT_EXIST")
      putParcelableArray("PLUGIN_CONFIG", arrayOf(barcodePlugin))
      putParcelableArray("APP_LIST", arrayOf(appList))
    }

    sendDataWedgeIntent(profileConfig)

    val intentPlugin = Bundle().apply {
      putString("PLUGIN_NAME", "INTENT")
      putString("RESET_CONFIG", "true")
      putString("intent_output_enabled", "true")
      putString("intent_action", intentAction)
      putString("intent_delivery", "2")
      putString("intent_category", "android.intent.category.DEFAULT")
    }

    val intentConfig = Bundle().apply {
      putString("PROFILE_NAME", profileName)
      putString("CONFIG_MODE", "UPDATE")
      putParcelableArray("PLUGIN_CONFIG", arrayOf(intentPlugin))
    }

    sendDataWedgeIntent(intentConfig)
  }

  private fun sendDataWedgeIntent(config: Bundle) {
    val intent = Intent().apply {
      action = DATAWEDGE_API_ACTION
      setPackage(DATAWEDGE_PACKAGE)
      putExtra(SET_CONFIG_EXTRA, config)
    }
    context.sendBroadcast(intent)
  }
}
