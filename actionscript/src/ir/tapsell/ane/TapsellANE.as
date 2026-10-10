package ir.tapsell.ane {
    import flash.events.EventDispatcher;
    import flash.events.IEventDispatcher;
    import flash.events.StatusEvent;
    import flash.external.ExtensionContext;

    /** Static, framework-independent ActionScript API for the Tapsell ANE. */
    public final class TapsellANE {
        public static const EXTENSION_ID:String = "ir.tapsell.ane";
        public static const NATIVE_SDK_VERSION:String = "4.9.15";

        private static var _context:ExtensionContext;
        private static const dispatcher:EventDispatcher = new EventDispatcher();

        public static function get isSupported():Boolean {
            return ensureContext() != null;
        }

        public static function initialize(appKey:String):void {
            if (!appKey || appKey.replace(/^\s+|\s+$/g, "").length == 0) {
                dispatchLocalError(TapsellEvent.INIT_FAILED, "INVALID_APP_KEY", "appKey must not be empty.");
                return;
            }
            callNative("initialize", appKey);
        }

        public static function loadRewardedAd(zoneId:String):void {
            if (!zoneId || zoneId.replace(/^\s+|\s+$/g, "").length == 0) {
                dispatchLocalError(TapsellEvent.AD_LOAD_FAILED, "INVALID_ZONE_ID", "zoneId must not be empty.");
                return;
            }
            callNative("loadRewardedAd", zoneId);
        }

        public static function showRewardedAd(zoneId:String):void {
            if (!zoneId || zoneId.replace(/^\s+|\s+$/g, "").length == 0) {
                dispatchLocalError(TapsellEvent.AD_SHOW_FAILED, "INVALID_ZONE_ID", "zoneId must not be empty.");
                return;
            }
            callNative("showRewardedAd", zoneId);
        }

        /** Pass the user's real privacy choice; do not assume consent. */
        public static function setUserConsent(consent:Boolean):void {
            callNative("setUserConsent", consent);
        }

        public static function isRewardedAdReady(zoneId:String):Boolean {
            var context:ExtensionContext = ensureContext();
            return context != null && Boolean(context.call("isRewardedAdReady", zoneId));
        }

        public static function get nativeSdkVersion():String {
            var context:ExtensionContext = ensureContext();
            return context ? String(context.call("getNativeSdkVersion")) : NATIVE_SDK_VERSION;
        }

        public static function addEventListener(type:String, listener:Function,
                                                useCapture:Boolean = false, priority:int = 0,
                                                useWeakReference:Boolean = false):void {
            dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
        }

        public static function removeEventListener(type:String, listener:Function,
                                                   useCapture:Boolean = false):void {
            dispatcher.removeEventListener(type, listener, useCapture);
        }

        public static function hasEventListener(type:String):Boolean {
            return dispatcher.hasEventListener(type);
        }

        public static function dispose():void {
            if (_context == null) return;
            _context.removeEventListener(StatusEvent.STATUS, onStatus);
            _context.dispose();
            _context = null;
        }

        private static function ensureContext():ExtensionContext {
            if (_context != null) return _context;
            try {
                _context = ExtensionContext.createExtensionContext(EXTENSION_ID, null);
                if (_context != null) {
                    _context.addEventListener(StatusEvent.STATUS, onStatus);
                }
            } catch (error:Error) {
                trace("[TapsellANE] Unable to create extension context:", error.message);
            }
            return _context;
        }

        private static function callNative(functionName:String, ...args):* {
            var context:ExtensionContext = ensureContext();
            if (context == null) {
                dispatchLocalError(failureEventFor(functionName), "ANE_NOT_AVAILABLE",
                        "The native extension is not available.");
                return null;
            }
            try {
                args.unshift(functionName);
                return context.call.apply(context, args);
            } catch (error:Error) {
                dispatchLocalError(failureEventFor(functionName), "NATIVE_CALL_FAILED", error.message);
            }
            return null;
        }

        private static function failureEventFor(functionName:String):String {
            if (functionName == "loadRewardedAd") return TapsellEvent.AD_LOAD_FAILED;
            if (functionName == "showRewardedAd") return TapsellEvent.AD_SHOW_FAILED;
            return TapsellEvent.INIT_FAILED;
        }

        private static function onStatus(event:StatusEvent):void {
            if (event.code == "TRACE") {
                try {
                    var traceData:Object = JSON.parse(event.level);
                    trace("[TapsellANE]", traceData.message);
                } catch (error:Error) {
                    trace("[TapsellANE]", event.level);
                }
                return;
            }
            dispatcher.dispatchEvent(new TapsellEvent(event.code, event.level));
        }

        private static function dispatchLocalError(type:String, code:String, message:String):void {
            dispatcher.dispatchEvent(new TapsellEvent(type, JSON.stringify({
                errorCode: code,
                message: message
            })));
        }
    }
}
