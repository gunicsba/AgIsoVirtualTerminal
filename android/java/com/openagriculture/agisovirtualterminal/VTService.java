package com.openagriculture.agisovirtualterminal;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ServiceInfo;
import android.net.wifi.WifiManager;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;

/**
 * A foreground service, so the VT's process keeps foreground priority, and is not frozen, while
 * another app is in front. It also holds a WiFi lock, so WiFi power saving does not delay the link
 * to the CANlink, and a partial wake lock for when the screen goes off.
 */
public class VTService extends Service
{
    private static final String CHANNEL_ID = "vt";
    private static final int NOTIFICATION_ID = 1;
    private static final String LOCK_TAG = "AgIsoVT:CANlink";

    private WifiManager.WifiLock wifiLock;
    private PowerManager.WakeLock wakeLock;

    @Override
    public int onStartCommand (Intent intent, int flags, int startId)
    {
        startInForeground();
        acquireLocks();
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy()
    {
        if (wifiLock != null && wifiLock.isHeld())
            wifiLock.release();

        if (wakeLock != null && wakeLock.isHeld())
            wakeLock.release();

        super.onDestroy();
    }

    @Override
    public IBinder onBind (Intent intent)
    {
        return null;
    }

    private void startInForeground()
    {
        Notification.Builder builder;

        if (Build.VERSION.SDK_INT >= 26)
        {
            NotificationManager manager = (NotificationManager) getSystemService (Context.NOTIFICATION_SERVICE);
            manager.createNotificationChannel (new NotificationChannel (CHANNEL_ID, "Virtual Terminal", NotificationManager.IMPORTANCE_LOW));
            builder = new Notification.Builder (this, CHANNEL_ID);
        }
        else
        {
            builder = new Notification.Builder (this);
        }

        // Tapping the notification brings the VT back to the front
        Intent open = new Intent (this, VTActivity.class).setFlags (Intent.FLAG_ACTIVITY_SINGLE_TOP);
        PendingIntent openOnTap = PendingIntent.getActivity (this, 0, open, PendingIntent.FLAG_IMMUTABLE);

        Notification notification = builder.setContentTitle ("AgISOVirtualTerminal is running")
                                         .setContentText ("Stays connected to the implements while another app is in front")
                                         .setSmallIcon (android.R.drawable.stat_notify_sync)
                                         .setContentIntent (openOnTap)
                                         .setOngoing (true)
                                         .build();

        if (Build.VERSION.SDK_INT >= 29)
            startForeground (NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE);
        else
            startForeground (NOTIFICATION_ID, notification);
    }

    private void acquireLocks()
    {
        if (wifiLock == null)
        {
            WifiManager wifi = (WifiManager) getApplicationContext().getSystemService (Context.WIFI_SERVICE);
            int mode = Build.VERSION.SDK_INT >= 29 ? WifiManager.WIFI_MODE_FULL_LOW_LATENCY : WifiManager.WIFI_MODE_FULL_HIGH_PERF;
            wifiLock = wifi.createWifiLock (mode, LOCK_TAG);
            wifiLock.setReferenceCounted (false);
            wifiLock.acquire();
        }

        if (wakeLock == null)
        {
            PowerManager power = (PowerManager) getSystemService (Context.POWER_SERVICE);
            wakeLock = power.newWakeLock (PowerManager.PARTIAL_WAKE_LOCK, LOCK_TAG);
            wakeLock.setReferenceCounted (false);
            wakeLock.acquire();
        }
    }
}
