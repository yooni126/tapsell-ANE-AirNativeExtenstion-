package ir.tapsell.ane;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

import java.util.HashMap;
import java.util.Map;

/** Maps the public ActionScript function names to the native controller. */
public final class TapsellContext extends FREContext {
    private final TapsellController controller = new TapsellController(this);

    @Override
    public Map<String, FREFunction> getFunctions() {
        Map<String, FREFunction> functions = new HashMap<>();

        functions.put("initialize", (context, args) -> {
            controller.initialize(readString(args, 0));
            return null;
        });

        functions.put("loadRewardedAd", (context, args) -> {
            controller.loadRewardedAd(readString(args, 0));
            return null;
        });

        functions.put("showRewardedAd", (context, args) -> {
            controller.showRewardedAd(readString(args, 0));
            return null;
        });

        functions.put("setUserConsent", (context, args) -> {
            controller.setUserConsent(readBoolean(args, 0));
            return null;
        });

        functions.put("isRewardedAdReady", (context, args) ->
                newBoolean(controller.isRewardedAdReady(readString(args, 0))));

        functions.put("getNativeSdkVersion", (context, args) -> newString("4.9.15"));
        return functions;
    }

    @Override
    public void dispose() {
        controller.dispose();
    }

    private static String readString(FREObject[] args, int index) {
        if (args == null || index >= args.length || args[index] == null) {
            return null;
        }
        try {
            return args[index].getAsString();
        } catch (Throwable ignored) {
            return null;
        }
    }

    private static boolean readBoolean(FREObject[] args, int index) {
        if (args == null || index >= args.length || args[index] == null) {
            return false;
        }
        try {
            return args[index].getAsBool();
        } catch (Throwable ignored) {
            return false;
        }
    }

    private static FREObject newBoolean(boolean value) {
        try {
            return FREObject.newObject(value);
        } catch (Throwable ignored) {
            return null;
        }
    }

    private static FREObject newString(String value) {
        try {
            return FREObject.newObject(value);
        } catch (Throwable ignored) {
            return null;
        }
    }
}
