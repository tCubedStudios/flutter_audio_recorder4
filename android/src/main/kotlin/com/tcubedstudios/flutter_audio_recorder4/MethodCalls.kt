package com.tcubedstudios.flutter_audio_recorder4

enum class MethodCalls(var methodName: String) {

    HAS_PERMISSIONS("hasPermissions"),
    INIT("init"),
    CURRENT("current"),
    START("start"),
    PAUSE("pause"),
    RESUME("resume"),
    STOP("stop");

    companion object {
        fun String.toMethodCall() = MethodCalls.values().firstOrNull { it.methodName == this }
    }
}