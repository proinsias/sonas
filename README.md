# sonas
Sonas (SUN-əs, from the Irish for happiness) is a Family Command Center, showing everyone's location, upcoming events, and other family matters.

When I get a paid Apple Developer account, re-add to Sonas the following entitlements:

```
<key>com.apple.developer.weatherkit</key>
<true/>
<key>com.apple.developer.icloud-services</key>
<array><string>CloudKit</string></array>
<key>com.apple.developer.icloud-container-identifiers</key>
<array><string>iCloud.com.anindependentmind.sonas</string></array>
```

And uncomment the capabilities in `project.yml`.