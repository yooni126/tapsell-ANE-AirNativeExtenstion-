package {
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    import ir.tapsell.ane.TapsellANE;
    import ir.tapsell.ane.TapsellEvent;

    /** Pure display-list sample: no Starling or Feathers dependency. */
    public final class Main extends Sprite {
        private static const APP_KEY:String = "YOUR_TAPSELL_APP_ID";
        private static const REWARDED_ZONE_ID:String = "YOUR_REWARDED_ZONE_ID";

        private var statusField:TextField;
        private var loadButton:Sprite;
        private var showButton:Sprite;

        public function Main() {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function onAddedToStage(event:Event):void {
            removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            buildUi();
            registerEvents();
            log("Initializing Tapsell SDK...");
            TapsellANE.initialize(APP_KEY);
        }

        private function registerEvents():void {
            TapsellANE.addEventListener(TapsellEvent.INIT_SUCCESS, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.INIT_FAILED, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.AD_LOADED, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.AD_LOAD_FAILED, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.AD_OPENED, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.AD_CLICKED, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.AD_CLOSED, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.AD_SHOW_FAILED, onTapsellEvent);
            TapsellANE.addEventListener(TapsellEvent.REWARD_EARNED, onTapsellEvent);
        }

        private function onTapsellEvent(event:TapsellEvent):void {
            log(event.type + "  " + event.rawData);
            if (event.type == TapsellEvent.REWARD_EARNED) {
                // Grant coins/credit ONLY here. AD_CLOSED must never grant a reward.
                log("REWARD CONFIRMED BY NATIVE SDK");
            }
        }

        private function onLoad(event:MouseEvent):void {
            TapsellANE.loadRewardedAd(REWARDED_ZONE_ID);
        }

        private function onShow(event:MouseEvent):void {
            TapsellANE.showRewardedAd(REWARDED_ZONE_ID);
        }

        private function buildUi():void {
            statusField = new TextField();
            statusField.defaultTextFormat = new TextFormat("_sans", 18, 0xFFFFFF);
            statusField.background = true;
            statusField.backgroundColor = 0x18212B;
            statusField.wordWrap = true;
            statusField.multiline = true;
            statusField.width = 440;
            statusField.height = 430;
            statusField.x = 20;
            statusField.y = 20;
            addChild(statusField);

            loadButton = createButton("Load rewarded ad", 20, 480);
            showButton = createButton("Show rewarded ad", 20, 550);
            loadButton.addEventListener(MouseEvent.CLICK, onLoad);
            showButton.addEventListener(MouseEvent.CLICK, onShow);
        }

        private function createButton(label:String, x:Number, y:Number):Sprite {
            var button:Sprite = new Sprite();
            button.graphics.beginFill(0x0E8A74);
            button.graphics.drawRoundRect(0, 0, 440, 54, 12, 12);
            button.graphics.endFill();
            button.x = x;
            button.y = y;
            button.buttonMode = true;

            var field:TextField = new TextField();
            field.defaultTextFormat = new TextFormat("_sans", 20, 0xFFFFFF, true);
            field.autoSize = TextFieldAutoSize.CENTER;
            field.mouseEnabled = false;
            field.text = label;
            field.x = (440 - field.width) * 0.5;
            field.y = (54 - field.height) * 0.5;
            button.addChild(field);
            addChild(button);
            return button;
        }

        private function log(message:String):void {
            statusField.appendText(message + "\n");
            statusField.scrollV = statusField.maxScrollV;
            trace("[TapsellExample]", message);
        }
    }
}
