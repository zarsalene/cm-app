# Browser preview

Run the app in Chrome with fake data. No Android SDK needed.

```
flutter run -d chrome -t lib/main_development.dart --dart-define=DEMO=true
```

Login: `demo` / `demo`. A corner banner reads `MODE DÉMO`.

Demo notes:
- Data lives in memory. A reply containing `fail` shows the send error.
- A new open escalation appears 25 s after start (shows list refresh).

The preview cannot show: push alerts, the launcher icon, the phone app name.

Live API: Chrome may block calls to n8n (CORS). For a local preview only:

```
flutter run -d chrome -t lib/main_development.dart --web-browser-flag "--disable-web-security"
```

Without `DEMO=true` the app is the normal build. Demo code is tree-shaken out.
