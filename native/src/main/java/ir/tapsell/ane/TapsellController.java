package ir.tapsell.ane;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.json.JSONObject;

import java.util.Collections;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

import ir.tapsell.sdk.Tapsell;
import ir.tapsell.sdk.TapsellAdRequestListener;
import ir.tapsell.sdk.TapsellAdRequestOptions;
import ir.tapsell.sdk.TapsellAdShowListener;
import ir.tapsell.sdk.TapsellShowOptions;

/** Owns native state and all communication back to ActionScript. */
final class TapsellController {
    static final String INIT_SUCCESS = "INIT_SUCCESS";
    static final String INIT_FAILED = "INIT_FAILED";
    static final String AD_LOADED = "AD_LOADED";
    static final String AD_LOAD_FAILED = "AD_LOAD_FAILED";
    static final String AD_OPENED = "AD_OPENED";
    static final String AD_CLICKED = "AD_CLICKED";
    static final String AD_CLOSED = "AD_CLOSED";
    static final String AD_SHOW_FAILED = "AD_SHOW_FAILED";
    static final String REWARD_EARNED = "REWARD_EARNED";
    static final String TRACE = "TRACE";

    private static final String TAG = "TapsellANE";

    private final TapsellContext context;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final Map<String, String> loadedRewardedAds = new ConcurrentHashMap<>();
    private final Set<String> loadingZones = Collections.newSetFromMap(new ConcurrentHashMap<>());
    private final AtomicBoolean adShowing = new AtomicBoolean(false);

    private volatile boolean disposed;
    private volatile boolean initializationPending;
    private volatile boolean initialized;

    TapsellController(TapsellContext context) {
        this.context = context;
    }

    void initialize(final String appKey) {
        runOnMain(() -> {
            if (disposed) return;
            final Activity activity = context.getActivity();
            if (activity == null) {
                dispatchError(INIT_FAILED, "NO_ACTIVITY", "AIR activity is not available.", null);
                return;
            }
            if (isBlank(appKey)) {
                dispatchError(INIT_FAILED, "INVALID_APP_KEY", "appKey must not be empty.", null);
                return;
            }
            if (initialized) {
                dispatch(INIT_SUCCESS, payload(
                        "appKeyConfigured", true,
                        "alreadyInitialized", true,
                        "sdkVersion", Tapsell.getVersion()));
                return;
            }
            if (initializationPending) {
                trace("Initialization is already pending");
                return;
            }

            try {
                // Duel uses classic Tapsell credentials (a long application key
                // and a 24-character zone ID). SDK 4.9.15 is also the official
                // SDK embedded by Tapsell's maintained legacy mediation adapter.
                // It has no initialization-completion callback, so request
                // callbacks remain authoritative for network/ad availability.
                initializationPending = true;
                Tapsell.initialize(activity.getApplication(), appKey);
                // The classic SDK initializes asynchronously but exposes no public
                // completion listener. Give its GAID/user bootstrap time to finish
                // before allowing the first request; otherwise it reports
                // "Tapsell must be initialized before requesting ad".
                mainHandler.postDelayed(() -> {
                    if (disposed) return;
                    initializationPending = false;
                    initialized = true;
                    dispatch(INIT_SUCCESS, payload(
                            "appKeyConfigured", true,
                            "alreadyInitialized", false,
                            "sdkVersion", Tapsell.getVersion()));
                }, 1_500L);
            } catch (Throwable error) {
                initializationPending = false;
                dispatchError(INIT_FAILED, "SDK_EXCEPTION", errorMessage(error), null, null, error);
            }
        });
    }

    void loadRewardedAd(final String zoneId) {
        runOnMain(() -> {
            if (disposed) return;
            if (!initialized) {
                dispatchError(AD_LOAD_FAILED, "NOT_INITIALIZED",
                        "Call initialize() and wait for INIT_SUCCESS first.", zoneId);
                return;
            }
            if (isBlank(zoneId)) {
                dispatchError(AD_LOAD_FAILED, "INVALID_ZONE_ID", "zoneId must not be empty.", zoneId);
                return;
            }
            if (!loadingZones.add(zoneId)) {
                dispatchError(AD_LOAD_FAILED, "REQUEST_IN_PROGRESS",
                        "A rewarded ad request is already in progress for this zone.", zoneId);
                return;
            }
            final Activity activity = context.getActivity();
            if (activity == null) {
                loadingZones.remove(zoneId);
                dispatchError(AD_LOAD_FAILED, "NO_ACTIVITY", "AIR activity is not available.", zoneId);
                return;
            }

            trace("Requesting rewarded ad for zone " + zoneId);
            try {
                Tapsell.requestAd(activity, zoneId, new TapsellAdRequestOptions(),
                        new TapsellAdRequestListener() {
                            @Override
                            public void onAdAvailable(String adId) {
                                if (disposed) return;
                                loadingZones.remove(zoneId);
                                loadedRewardedAds.put(zoneId, adId);
                                dispatch(AD_LOADED, payload("zoneId", zoneId, "adId", adId));
                            }

                            @Override
                            public void onError(String message) {
                                if (disposed) return;
                                loadingZones.remove(zoneId);
                                dispatchError(AD_LOAD_FAILED, "SDK_LOAD_FAILED", message, zoneId);
                            }

                        });
            } catch (Throwable error) {
                loadingZones.remove(zoneId);
                dispatchError(AD_LOAD_FAILED, "SDK_EXCEPTION", errorMessage(error), zoneId, error);
            }
        });
    }

    void showRewardedAd(final String zoneId) {
        runOnMain(() -> {
            if (disposed) return;
            if (!initialized) {
                dispatchError(AD_SHOW_FAILED, "NOT_INITIALIZED",
                        "Call initialize() and wait for INIT_SUCCESS first.", zoneId);
                return;
            }
            if (isBlank(zoneId)) {
                dispatchError(AD_SHOW_FAILED, "INVALID_ZONE_ID", "zoneId must not be empty.", zoneId);
                return;
            }
            if (!adShowing.compareAndSet(false, true)) {
                dispatchError(AD_SHOW_FAILED, "AD_ALREADY_SHOWING",
                        "Another full-screen rewarded ad is already showing.", zoneId);
                return;
            }

            final String adId = loadedRewardedAds.remove(zoneId);
            if (isBlank(adId)) {
                adShowing.set(false);
                dispatchError(AD_SHOW_FAILED, "AD_NOT_READY",
                        "No loaded rewarded ad is available for this zone.", zoneId);
                return;
            }

            final Activity activity = context.getActivity();
            if (activity == null) {
                adShowing.set(false);
                dispatchError(AD_SHOW_FAILED, "NO_ACTIVITY", "AIR activity is not available.", zoneId);
                return;
            }

            final AtomicBoolean openedSent = new AtomicBoolean(false);
            final AtomicBoolean rewardSent = new AtomicBoolean(false);
            try {
                TapsellShowOptions showOptions = new TapsellShowOptions();
                showOptions.setBackDisabled(true);
                showOptions.setImmersiveMode(true);
                showOptions.setRotationMode(TapsellShowOptions.ROTATION_UNLOCKED);
                showOptions.setShowDialog(false);

                Tapsell.showAd(activity, zoneId, adId, showOptions, new TapsellAdShowListener() {
                    @Override
                    public void onOpened() {
                        if (disposed || !openedSent.compareAndSet(false, true)) return;
                        dispatch(AD_OPENED, payload("zoneId", zoneId, "adId", adId));
                    }

                    @Override
                    public void onAdClicked() {
                        if (disposed) return;
                        dispatch(AD_CLICKED, payload("zoneId", zoneId, "adId", adId));
                    }

                    @Override
                    public void onClosed() {
                        if (disposed) return;
                        adShowing.set(false);
                        dispatch(AD_CLOSED, payload(
                                "zoneId", zoneId,
                                "adId", adId,
                                "completionState", rewardSent.get() ? "COMPLETED" : "SKIPPED",
                                "rewardEarned", rewardSent.get()));
                    }

                    @Override
                    public void onRewarded(boolean completed) {
                        if (!completed || disposed || !rewardSent.compareAndSet(false, true)) return;
                        // Closing never grants coins. Only this native callback
                        // with completed=true can dispatch REWARD_EARNED.
                        dispatch(REWARD_EARNED, payload("zoneId", zoneId, "adId", adId));
                    }

                    @Override
                    public void onError(String message) {
                        if (disposed) return;
                        adShowing.set(false);
                        dispatchError(AD_SHOW_FAILED, "SDK_SHOW_FAILED", message, zoneId, adId, null);
                    }
                });
            } catch (Throwable error) {
                adShowing.set(false);
                dispatchError(AD_SHOW_FAILED, "SDK_EXCEPTION", errorMessage(error), zoneId, adId, error);
            }
        });
    }

    void setUserConsent(final boolean consent) {
        runOnMain(() -> {
            if (disposed) return;
            try {
                Tapsell.setGDPRConsent(consent);
                trace("User consent updated: " + consent);
            } catch (Throwable error) {
                trace("Failed to update user consent: " + errorMessage(error));
            }
        });
    }

    boolean isRewardedAdReady(String zoneId) {
        return !isBlank(zoneId) && loadedRewardedAds.containsKey(zoneId);
    }

    void dispose() {
        disposed = true;
        initializationPending = false;
        mainHandler.removeCallbacksAndMessages(null);
        loadingZones.clear();
        loadedRewardedAds.clear();
        adShowing.set(false);
    }

    private void runOnMain(Runnable action) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action.run();
        } else {
            mainHandler.post(action);
        }
    }

    private void dispatch(String code, JSONObject data) {
        final String serialized = data == null ? "{}" : data.toString();
        runOnMain(() -> {
            if (disposed) return;
            Log.d(TAG, code + ": " + serialized);
            context.dispatchStatusEventAsync(code, serialized);
        });
    }

    private void trace(String message) {
        Log.d(TAG, message);
        dispatch(TRACE, payload("message", message));
    }

    private void dispatchError(String event, String errorCode, String message, String zoneId) {
        dispatchError(event, errorCode, message, zoneId, null);
    }

    private void dispatchError(String event, String errorCode, String message, String zoneId, Throwable error) {
        dispatchError(event, errorCode, message, zoneId, null, error);
    }

    private void dispatchError(String event, String errorCode, String message,
                               String zoneId, String adId, Throwable error) {
        if (error != null) {
            Log.e(TAG, event + ": " + message, error);
        } else {
            Log.e(TAG, event + ": " + message);
        }
        JSONObject data = payload("errorCode", errorCode, "message", safe(message));
        put(data, "zoneId", zoneId);
        put(data, "adId", adId);
        dispatch(event, data);
    }

    private static JSONObject payload(Object... values) {
        JSONObject result = new JSONObject();
        for (int index = 0; index + 1 < values.length; index += 2) {
            put(result, String.valueOf(values[index]), values[index + 1]);
        }
        return result;
    }

    private static void put(JSONObject object, String key, Object value) {
        if (value == null) return;
        try {
            object.put(key, value);
        } catch (Exception ignored) {
            // JSONObject only rejects non-finite numbers; none are emitted here.
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private static String safe(String value) {
        return value == null ? "Unknown error" : value;
    }

    private static String errorMessage(Throwable error) {
        if (error == null) return "Unknown error";
        String message = error.getMessage();
        return isBlank(message) ? error.getClass().getSimpleName() : message;
    }
}
