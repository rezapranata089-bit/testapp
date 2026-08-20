# Keep rules wajib untuk flutter_local_notifications agar tidak crash
# saat R8/ProGuard menghapus info tipe generik yang dibutuhkan Gson untuk
# menyimpan & membaca daftar notifikasi terjadwal (menyebabkan error
# "Missing type parameter" dan notifikasi gagal terdaftar ke OS).
-keep class com.dexterous.flutterlocalnotifications.** { *; }

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes EnclosingMethod
-keepattributes InnerClasses

-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * implements java.lang.reflect.Type

-dontwarn org.xmlpull.v1.**