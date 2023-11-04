package com.tcubedstudios.flutter_audio_recorder4

import androidx.annotation.CallSuper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

abstract class FlutterPluginImpl : FlutterPlugin, MethodCallHandler {

    companion object {
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            val channel = MethodChannel(registrar.messenger(), "flutter_audio_recorder4")
            channel.setMethodCallHandler(FlutterAudioRecorder4Plugin())//TODO - CHRIS - need to pass registrar for older projects
        }
    }

    protected var result: Result? = null

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel : MethodChannel

    //region Flutter plugin binding
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_audio_recorder4")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
    //endregion

    @CallSuper
    override fun onMethodCall(call: MethodCall, result: Result) {
        this.result = result
    }
}