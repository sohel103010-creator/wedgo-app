# Flutter + WebRTC keep rules
-keep class io.flutter.** { *; }
-keep class com.wedgo.matrimony.** { *; }
# flutter_webrtc
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
# supabase / postgrest
-keepnames class * extends com.google.gson.TypeAdapter
