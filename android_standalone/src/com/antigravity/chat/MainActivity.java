package com.antigravity.chat;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetSocketAddress;
import java.net.Socket;
import org.json.JSONObject;

public class MainActivity extends Activity {
    private WebView webView;
    private Socket socket;
    private BufferedWriter writer;
    private BufferedReader reader;
    private Thread listenThread;
    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private boolean isConnected = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setUseWideViewPort(true);
        settings.setLoadWithOverviewMode(true);

        webView.setWebViewClient(new WebViewClient());
        webView.addJavascriptInterface(new WebAppInterface(), "AndroidBridge");

        setContentView(webView);
        webView.loadUrl("file:///android_asset/index.html");
    }

    public class WebAppInterface {
        @JavascriptInterface
        public void connect(final String host, final int port, final String username, final String room) {
            new Thread(new Runnable() {
                @Override
                public void run() {
                    disconnectInternal();
                    try {
                        socket = new Socket();
                        socket.connect(new InetSocketAddress(host, port), 4000);
                        writer = new BufferedWriter(new OutputStreamWriter(socket.getOutputStream(), "UTF-8"));
                        reader = new BufferedReader(new InputStreamReader(socket.getInputStream(), "UTF-8"));
                        isConnected = true;

                        // Send join packet
                        JSONObject join = new JSONObject();
                        join.put("type", "join");
                        join.put("username", username);
                        join.put("room", room);
                        writer.write(join.toString() + "\n");
                        writer.flush();

                        // Send history request
                        JSONObject hist = new JSONObject();
                        hist.put("type", "history_req");
                        hist.put("limit", 20);
                        writer.write(hist.toString() + "\n");
                        writer.flush();

                        notifyStatus(true);

                        // Listen loop
                        String line;
                        while (isConnected && (line = reader.readLine()) != null) {
                            final String raw = line;
                            mainHandler.post(new Runnable() {
                                @Override
                                public void run() {
                                    webView.evaluateJavascript("onMessageReceived(" + JSONObject.quote(raw) + ");", null);
                                }
                            });
                        }
                    } catch (Exception e) {
                        notifyStatus(false);
                    } finally {
                        disconnectInternal();
                        notifyStatus(false);
                    }
                }
            }).start();
        }

        @JavascriptInterface
        public void sendMessage(final String text) {
            new Thread(new Runnable() {
                @Override
                public void run() {
                    try {
                        if (writer != null && isConnected) {
                            JSONObject msg = new JSONObject();
                            msg.put("type", "msg");
                            msg.put("text", text);
                            writer.write(msg.toString() + "\n");
                            writer.flush();
                        }
                    } catch (Exception e) {
                        notifyStatus(false);
                    }
                }
            }).start();
        }

        @JavascriptInterface
        public void disconnect() {
            disconnectInternal();
            notifyStatus(false);
        }
    }

    private void notifyStatus(final boolean online) {
        isConnected = online;
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                webView.evaluateJavascript("onConnectionStatus(" + online + ");", null);
            }
        });
    }

    private synchronized void disconnectInternal() {
        isConnected = false;
        try {
            if (writer != null) { writer.close(); writer = null; }
            if (reader != null) { reader.close(); reader = null; }
            if (socket != null && !socket.isClosed()) { socket.close(); socket = null; }
        } catch (Exception ignored) {}
    }

    @Override
    protected void onDestroy() {
        disconnectInternal();
        super.onDestroy();
    }
}
