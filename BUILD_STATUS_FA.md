# وضعیت Build و اعتبارسنجی

تاریخ اجرا: ۱۱ اکتبر ۲۰۲۶

## موارد موفق

- کامپایل Java native bridge با Gradle 8.9 و Android Gradle Plugin 8.7.3: موفق
- تطبیق compile-time با API رسمی `ir.tapsell.sdk:tapsell-sdk-android:4.9.15`: موفق
- کامپایل wrapper اکشن‌اسکریپت به SWC با AIR SDK 51.3.4: موفق
- بسته‌بندی ANE برای Android ARM/ARM64/x86/x64: موفق
- کامپایل نمونهٔ مستقل به `example/bin/Main.swf`: موفق
- خروجی نهایی: `dist/TapsellANE.ane`
- SHA-256: `7AD5948FCA1D812F33AAE0D063432C9DF2DB4960F2EE80D762D26E436805E548`
- bytecode کلاس native: Java 8 (major version 52)

## محدودیت‌های محیط این build

- AIR SDK 51.4 روی سیستم موجود نبود؛ AIR SDK 51.3.4 موجود برای ساخت استفاده شد. descriptor حداقل 51.3 است و در 51.4 قابل بارگذاری است، اما build دوباره با خود AIR 51.4 در این سیستم انجام نشد.
- Android Platform 35 نصب نبود و این نسخه عمداً با Platform 34 ساخته شد.
- APK واقعی Duel ساخته و روی دستگاه ARM64 نصب شد.
- تست روی دستگاه واقعی موفق شد: `INIT_SUCCESS`، سپس `AD_LOADED` با adId واقعی و `AD_OPENED` ثبت شدند.
- callback جایزه فقط پس از مشاهدهٔ کامل ویدئو قابل تأیید است و در کد صرفاً `onRewarded(true)` به `REWARD_EARNED` نگاشت شده است.

فایل ANE، SWF و APK واقعاً ساخته شده‌اند. جایزه فقط از callback رسمی `onRewarded(true)` ارسال می‌شود.
