import re, pathlib, shutil
a = pathlib.Path("android/app")

# 1) manifest: permissions, notification receivers, app label
m = a / "src/main/AndroidManifest.xml"
s = m.read_text(encoding="utf-8")
perms = '''    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
'''
recv = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
'''
s = s.replace("<application", perms + "    <application", 1)
s = s.replace("</application>", recv + "    </application>", 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="H ❤ R"', s, count=1)
m.write_text(s, encoding="utf-8")

# 2) notification icon
d = a / "src/main/res/drawable"; d.mkdir(parents=True, exist_ok=True)
shutil.copy("android_additions/res/drawable/ic_heart_notif.xml", d / "ic_heart_notif.xml")

# 3) core library desugaring (needed by flutter_local_notifications)
kts = (a / "build.gradle.kts").exists()
g = a / ("build.gradle.kts" if kts else "build.gradle")
t = g.read_text(encoding="utf-8")
flag = "isCoreLibraryDesugaringEnabled = true" if kts else "coreLibraryDesugaringEnabled true"
t, n = re.subn(r"compileOptions\s*\{", "compileOptions {\n        " + flag, t, count=1)
assert n == 1, "compileOptions block not found in " + g.name
dep = ('coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' if kts
       else "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'")
t += "\ndependencies {\n    " + dep + "\n}\n"
g.write_text(t, encoding="utf-8")
print("patched", g)
