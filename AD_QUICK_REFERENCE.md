# Ad Management Quick Reference

## 🎯 Quick Start

### Banner Ad

```dart
const BannerAdWidget(
  screenId: 'your_screen_name',
  refreshInterval: Duration(seconds: 90), // Optional: 60-120s
  enableAutoRefresh: true, // Optional: default true
)
```

### Native Ad

```dart
const NativeAdWidget(
  screenId: 'your_screen_or_list_name',
)
```

## 📋 Naming Convention

Use descriptive, unique screen IDs:

```dart
// ✅ Good
'home_screen'
'category_screen_top'
'category_screen_bottom'
'product_list_feed'
'settings_screen'

// ❌ Bad
'banner' // Too generic
'ad1' // Not descriptive
'screen' // Reused across screens
```

## 🔢 Key Metrics

### Impression Reduction (vs old implementation)

| Scenario                   | Old             | New             | Savings    |
| -------------------------- | --------------- | --------------- | ---------- |
| User navigates 5 times     | 5 impressions   | 1-2 impressions | **60-80%** |
| User scrolls feed 10 times | 10 impressions  | 1 impression    | **90%**    |
| 10 min session (banner)    | 3-5 impressions | 1-2 impressions | **40-60%** |

## ⚙️ Recommended Settings

### By Screen Type

| Screen Type   | Ad Type | Refresh  | screenId Example     |
| ------------- | ------- | -------- | -------------------- |
| Home          | Banner  | 90s      | `home_screen`        |
| Category List | Native  | Never    | `category_list_feed` |
| Detail View   | Banner  | 120s     | `detail_screen`      |
| Settings      | Banner  | Disabled | `settings_screen`    |
| Feed/List     | Native  | Never    | `feed_screen`        |

## 🚀 Implementation Steps

1. **Import the service**

   ```dart
   import '../../services/ad_manager.dart';
   ```

2. **Replace old widget**

   ```dart
   // Old
   const BannerAdWidget()

   // New
   const BannerAdWidget(screenId: 'home_screen')
   ```

3. **Test navigation**
   - Navigate away and back
   - Ad should NOT reload
   - Check debug logs for confirmation

## 🐛 Debug Logs

Look for these messages:

```
✅ BannerAdController[home_screen]: Loading ad...
✅ BannerAdController[home_screen]: Ad loaded successfully
✅ BannerAdController[home_screen]: Ad already loaded/loading, skipping
```

## 📊 AdMob Policy Compliance

✅ **Banner refresh**: 60-120 seconds (default: 90s)  
✅ **Native refresh**: Disabled (user-initiated only)  
✅ **Ad lifecycle**: Proper disposal on screen exit  
✅ **Ad labeling**: AdChoices placement configured

## 🎓 Common Patterns

### Multiple Banners on Same Screen

```dart
Column(
  children: [
    BannerAdWidget(screenId: 'screen_top'),
    // Content
    BannerAdWidget(screenId: 'screen_bottom'),
  ],
)
```

### Native Ad in ListView

```dart
ListView.builder(
  itemCount: items.length + 1,
  itemBuilder: (context, index) {
    if (index == 4) {
      return NativeAdWidget(screenId: 'list_feed');
    }
    final itemIndex = index > 4 ? index - 1 : index;
    return ItemWidget(items[itemIndex]);
  },
)
```

### Conditional Ad Display

```dart
if (isPremiumUser) {
  return Content();
} else {
  return Column(
    children: [
      Content(),
      BannerAdWidget(screenId: 'screen_id'),
    ],
  );
}
```

## 🔍 Troubleshooting

| Issue                    | Solution                            |
| ------------------------ | ----------------------------------- |
| Ad reloads on navigation | Check if `screenId` is unique       |
| Ad doesn't show          | Verify `AdService.isAdsSupported`   |
| Multiple impressions     | Use same `screenId` for same screen |
| Ad not refreshing        | Check `enableAutoRefresh` setting   |

## 📱 Testing Checklist

- [ ] Ad loads on first screen visit
- [ ] Ad persists when navigating away and back
- [ ] Auto-refresh works (wait 90+ seconds)
- [ ] Multiple screens have unique IDs
- [ ] No errors in debug logs
- [ ] Impressions are reasonable in AdMob console

---

**See full documentation**: `AD_MANAGEMENT_GUIDE.md`
