package ir.tapsell.ane;

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

/** Entry point loaded by Adobe AIR. */
public final class TapsellExtension implements FREExtension {
    private static final String TAG = "TapsellANE";
    private TapsellContext context;

    @Override
    public void initialize() {
        Log.d(TAG, "Extension initialized");
    }

    @Override
    public synchronized FREContext createContext(String contextType) {
        if (context != null) {
            context.dispose();
        }
        context = new TapsellContext();
        return context;
    }

    @Override
    public synchronized void dispose() {
        if (context != null) {
            context.dispose();
            context = null;
        }
        Log.d(TAG, "Extension disposed");
    }
}

