package com.openagriculture.agisovirtualterminal;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;

import com.rmsl.juce.JuceActivity;

/**
 * Starts VTService with the VT, so it keeps running while another app is in front. Android freezes
 * background apps, and a frozen VT stops answering its working sets, which then drop the connection
 * and upload their object pools again.
 */
public class VTActivity extends JuceActivity
{
    @Override
    protected void onCreate (Bundle savedInstanceState)
    {
        super.onCreate (savedInstanceState);

        // The service runs without it, but its notification is only shown with this permission
        if (Build.VERSION.SDK_INT >= 33
            && checkSelfPermission (Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED)
        {
            requestPermissions (new String[] { Manifest.permission.POST_NOTIFICATIONS }, 1);
        }

        Intent service = new Intent (this, VTService.class);

        if (Build.VERSION.SDK_INT >= 26)
            startForegroundService (service);
        else
            startService (service);
    }

    @Override
    protected void onResume()
    {
        super.onResume();
        hideSystemBars();
    }

    @Override
    public void onWindowFocusChanged (boolean hasFocus)
    {
        super.onWindowFocusChanged (hasFocus);

        // Android shows the bars again after another app was in front
        if (hasFocus)
            hideSystemBars();
    }

    /**
     * Hides the status and navigation bars, which Android draws over the VT's menu. A swipe from the
     * edge shows them for a moment. JUCE's window cannot take focus, so the bars follow this activity's
     * window. Android ignores the request in split screen and pop-up windows.
     */
    private void hideSystemBars()
    {
        if (Build.VERSION.SDK_INT >= 30)
        {
            WindowInsetsController controller = getWindow().getInsetsController();

            if (controller != null)
            {
                controller.setSystemBarsBehavior (WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
                controller.hide (WindowInsets.Type.statusBars() | WindowInsets.Type.navigationBars());
            }
        }
        else
        {
            getWindow().getDecorView().setSystemUiVisibility (View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                                                              | View.SYSTEM_UI_FLAG_FULLSCREEN
                                                              | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        }
    }

    @Override
    protected void onDestroy()
    {
        // Only when the VT is really closed, not when Android recreates the activity
        if (isFinishing())
            stopService (new Intent (this, VTService.class));

        super.onDestroy();
    }
}
