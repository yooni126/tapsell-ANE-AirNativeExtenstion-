# Tapsell ANE برای Adobe AIR

این پروژه یک Adobe AIR Native Extension مستقل برای Android است که تبلیغ جایزه‌دار Tapsell را به ActionScript 3 متصل می‌کند. هیچ وابستگی‌ای به Starling یا Feathers ندارد و در Adobe Animate، AIR خالص، Starling و Feathers قابل استفاده است.

گزارش دقیق build واقعی این workspace در [BUILD_STATUS_FA.md](BUILD_STATUS_FA.md) قرار دارد.

## مبنای فنی و نسخه‌ها

- SDK انتخاب‌شده برای credentialهای کلاسیک: `ir.tapsell.sdk:tapsell-sdk-android:4.9.15`
- حداقل Android: API 21
- Compile/Target SDK این پروژه: API 34
- Java: 17 برای اجرای Gradle، bytecode کتابخانه Java 8
- AIR: descriptor حداقل 51.3؛ با AIR SDK 51.4 سازگار است. build محلی را می‌توان با 51.3.x یا جدیدتر نیز انجام داد.

کلید طولانی و Zone ID بیست‌وچهارکاراکتری پروژهٔ Duel متعلق به حساب کلاسیک تپسل است. SDK Mediation کلید را فقط در قالب 24-hex یا UUID می‌پذیرد و این کلید را با خطای `Invalid mediation app key` رد می‌کند؛ بنابراین برای این حساب، SDK رسمی 4.9.15 استفاده شده است. برای مهاجرت آینده به Mediation باید App ID جدید پنل Mediation جایگزین شود.

منابع رسمی بررسی‌شده:

- [نمونهٔ رسمی Tapsell Android](https://github.com/tapsellorg/TapsellSDK-AndroidSample)
- [artifact رسمی SDK](https://maven.tapsell.ir/ir/tapsell/sdk/tapsell-sdk-android/)

## نتیجهٔ تحلیل PoolakeyANE

از پروژهٔ مرجع این الگوها استفاده شده‌اند:

1. جداسازی wrapper اکشن‌اسکریپت، native library و مرحلهٔ بسته‌بندی ANE.
2. استفاده از `FREExtension`، `FREContext` و نام‌های تابع ثابت بین دو لایه.
3. ارسال رویدادهای native با `dispatchStatusEventAsync` و دریافت با `StatusEvent.STATUS`.
4. تولید SWC، استخراج `library.swf` و بسته‌بندی چند platform با ADT.

SDK داخل `classes.jar` ادغام نشده است. `platform.xml` وابستگی رسمی Gradle و resourceهای transitive را به build نهایی AIR اضافه می‌کند تا manifest merger و resource merger درست اجرا شوند. لایهٔ native با Java نوشته شده است.

## ساخت ANE (مراحل فارسی)

پیش‌نیازها:

1. AIR SDK 51.4 (یا 51.3.x برای ساخت همین bridge).
2. JDK 17 و متغیر `JAVA_HOME`.
3. Android SDK Platform 34 و Build Tools مناسب.
4. دسترسی Gradle به Maven Central، Google Maven و `https://maven.tapsell.ir`.

PowerShell:

```powershell
cd TapsellANE
.\scripts\build.ps1 -AirSdk "C:\path\to\AIRSDK_51.4"
```

برای تعیین صریح Platform 34:

```powershell
.\scripts\build.ps1 -AirSdk "C:\path\to\AIRSDK" -AndroidCompileSdk 34
```

یا:

```bat
cd TapsellANE
build.bat -AirSdk "C:\path\to\AIRSDK_51.4"
```

مراحل اسکریپت:

1. Gradle کد Java را با API واقعی Tapsell کامپایل می‌کند.
2. `compc` wrapper اکشن‌اسکریپت را به SWC تبدیل می‌کند.
3. `library.swf` از SWC استخراج می‌شود.
4. platformهای `Android-ARM`, `Android-ARM64`, `Android-x86`, `Android-x64` آماده می‌شوند.
5. `adt -target ane` فایل `dist/TapsellANE.ane` را می‌سازد.

ARM64 به‌طور صریح در extension descriptor تعریف شده است. bridge فقط Java bytecode دارد؛ native libraryهای احتمالی شبکه‌های تبلیغاتی توسط Gradle برای ABI صحیح وارد برنامهٔ نهایی می‌شوند.

## نصب در برنامهٔ AIR

فایل `dist/TapsellANE.ane` را داخل `lib` پروژه کپی کنید و extension را اضافه کنید:

```xml
<extensions>
    <extensionID>ir.tapsell.ane</extensionID>
</extensions>
```

در `asconfig.json`:

```json
{
  "compilerOptions": {
    "library-path": ["lib/TapsellANE.ane"]
  },
  "airOptions": {
    "android": {
      "extdir": ["lib"]
    }
  }
}
```

### Manifest و کلید برنامه

در اتصال کلاسیک، کلید برنامه به `TapsellANE.initialize(appKey)` داده می‌شود و نیازی به meta-data مربوط به Mediation نیست. در `manifestAdditions` حداقل موارد زیر لازم است:

```xml
<manifest>
    <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="34" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="com.google.android.gms.permission.AD_ID" />
    <application android:hardwareAccelerated="true" />
</manifest>
```

## API اکشن‌اسکریپت

```actionscript
import ir.tapsell.ane.TapsellANE;
import ir.tapsell.ane.TapsellEvent;

TapsellANE.addEventListener(TapsellEvent.INIT_SUCCESS, onEvent);
TapsellANE.addEventListener(TapsellEvent.INIT_FAILED, onEvent);
TapsellANE.addEventListener(TapsellEvent.AD_LOADED, onEvent);
TapsellANE.addEventListener(TapsellEvent.AD_LOAD_FAILED, onEvent);
TapsellANE.addEventListener(TapsellEvent.AD_OPENED, onEvent);
TapsellANE.addEventListener(TapsellEvent.AD_CLOSED, onEvent);
TapsellANE.addEventListener(TapsellEvent.AD_SHOW_FAILED, onEvent);
TapsellANE.addEventListener(TapsellEvent.REWARD_EARNED, onEvent);

TapsellANE.initialize("YOUR_CLASSIC_TAPSELL_APP_KEY");

function onEvent(event:TapsellEvent):void {
    trace(event.type, event.rawData);

    if (event.type == TapsellEvent.INIT_SUCCESS) {
        TapsellANE.loadRewardedAd("YOUR_REWARDED_ZONE_ID");
    } else if (event.type == TapsellEvent.AD_LOADED) {
        TapsellANE.showRewardedAd(event.zoneId);
    } else if (event.type == TapsellEvent.REWARD_EARNED) {
        // تنها محل مجاز برای دادن جایزه
        grantCoins();
    }
}
```

متدها:

- `initialize(appKey:String)` مقداردهی اولیه SDK رسمی با کلید کلاسیک تپسل.
- `loadRewardedAd(zoneId:String)` درخواست تبلیغ و نگهداری `adId` متناظر با zone.
- `showRewardedAd(zoneId:String)` نمایش همان `adId` یک‌بارمصرف.
- `isRewardedAdReady(zoneId:String):Boolean` بررسی cache محلی.
- `setUserConsent(consent:Boolean)` ارسال انتخاب واقعی کاربر برای GDPR.
- `dispose()` آزادسازی context و state محلی.

رویداد `AD_OPENED` به callback رسمی `onOpened()` نگاشت شده است. `AD_CLOSED` فقط بسته‌شدن رابط تبلیغ را گزارش می‌کند و هرگز جایزه نمی‌دهد. فقط callback رسمی `onRewarded(true)` باعث `REWARD_EARNED` می‌شود.

## اجرای نمونهٔ مستقل

برای build خط فرمان لازم نیست credentialها را داخل سورس ذخیره کنید؛ App ID و Zone ID به نسخهٔ موقت سورس/descriptor تزریق می‌شوند:

```powershell
.\scripts\build-example.ps1 `
  -AirSdk "C:\path\to\AIRSDK_51.4" `
  -AppKey "YOUR_CLASSIC_TAPSELL_APP_KEY" `
  -ZoneId "YOUR_REWARDED_ZONE_ID"
```

برای APK امضاشده، `-AndroidSdk`, `-Certificate` و `-StorePassword` را نیز بدهید. اسکریپت credential را فقط در نسخهٔ موقت سورس قرار می‌دهد.

## عیب‌یابی

- `AD_NOT_READY`: قبل از `AD_LOADED` نمایش درخواست شده یا تبلیغ قبلاً مصرف شده است.
- `SDK_LOAD_FAILED`: پیام اصلی SDK در `event.message` و `event.rawData` قرار دارد؛ Zone ID و تنظیمات پنل را بررسی کنید.
- خطای resolve شدن dependency: دسترسی به Maven Central، Google Maven و `maven.tapsell.ir` را بررسی کنید.
- خطاهای AndroidX یا duplicate class: نسخه‌های قدیمی SDK تپسل یا AARهای دستی را هم‌زمان وارد نکنید. این ANE وابستگی‌های لازم را از `platform.xml` می‌آورد.
- نبود تبلیغ در زمان تست لزوماً ایراد ANE نیست؛ از App ID و Zone تست رسمی صفحهٔ Test Keys استفاده کنید.

## توسعهٔ آینده

State و dispatch مرکزی طوری جدا شده‌اند که interstitial، banner و native با function/eventهای جدید افزوده شوند. برای banner/native باید lifecycle مربوط به View و destroy callbackهای رسمی نیز اضافه شود؛ در Phase 1 عمداً فقط rewarded پیاده‌سازی شده است.
