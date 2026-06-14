# Stripe SDK references push-provisioning classes that aren't bundled.
# Keep them and suppress the missing-class warnings so R8 doesn't fail.
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**
