package ir.tapsell.ane {
    import flash.events.Event;

    /** Event dispatched by TapsellANE. Native payloads are JSON objects. */
    public final class TapsellEvent extends Event {
        public static const INIT_SUCCESS:String = "INIT_SUCCESS";
        public static const INIT_FAILED:String = "INIT_FAILED";
        public static const AD_LOADED:String = "AD_LOADED";
        public static const AD_LOAD_FAILED:String = "AD_LOAD_FAILED";
        public static const AD_OPENED:String = "AD_OPENED";
        public static const AD_CLICKED:String = "AD_CLICKED";
        public static const AD_CLOSED:String = "AD_CLOSED";
        public static const AD_SHOW_FAILED:String = "AD_SHOW_FAILED";
        public static const REWARD_EARNED:String = "REWARD_EARNED";

        public var data:Object;
        public var rawData:String;

        public function TapsellEvent(type:String, rawData:String = "{}",
                                     bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
            this.rawData = rawData || "{}";
            try {
                this.data = JSON.parse(this.rawData);
            } catch (error:Error) {
                this.data = { message: this.rawData };
            }
        }

        public function get zoneId():String {
            return data && data.zoneId != null ? String(data.zoneId) : null;
        }

        public function get adId():String {
            return data && data.adId != null ? String(data.adId) : null;
        }

        public function get message():String {
            return data && data.message != null ? String(data.message) : null;
        }

        public function get errorCode():String {
            return data && data.errorCode != null ? String(data.errorCode) : null;
        }

        public function get completionState():String {
            return data && data.completionState != null ? String(data.completionState) : null;
        }

        override public function clone():Event {
            return new TapsellEvent(type, rawData, bubbles, cancelable);
        }

        override public function toString():String {
            return formatToString("TapsellEvent", "type", "data", "bubbles", "cancelable");
        }
    }
}

