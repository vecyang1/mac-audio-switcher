# Direct Sales Quick Start Guide - Launch in 7 Days! 🚀

## Day 1-2: Payment Setup

### Option 1: Gumroad (Fastest - 2 hours)
1. Sign up at gumroad.com
2. Create product:
   - Name: AudioSwitch Pro
   - Price: $9.99
   - File: Upload AudioSwitchPro.zip
   - Enable "Generate license keys"
3. Get your product link
4. Done! You can start selling immediately

### Option 2: Paddle (Better for taxes - 1-2 days)
1. Sign up at paddle.com
2. Wait for approval (usually 24 hours)
3. Create product with Mac app SDK
4. More complex but handles VAT/taxes

## Day 3-4: Simple License Implementation

```swift
// Add to AudioSwitchProApp.swift
import CryptoKit

class LicenseManager {
    static let shared = LicenseManager()
    
    @AppStorage("licenseKey") private var storedKey = ""
    @AppStorage("isLicensed") private var isLicensed = false
    
    var trialDaysRemaining: Int {
        let installDate = UserDefaults.standard.object(forKey: "installDate") as? Date ?? Date()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return max(0, 14 - daysSinceInstall) // 14-day trial
    }
    
    func validateLicense(_ key: String) -> Bool {
        // Simple validation: Check if key matches pattern
        // Format: ASP-XXXX-XXXX-XXXX
        let pattern = #"^ASP-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"#
        let isValid = key.range(of: pattern, options: .regularExpression) != nil
        
        if isValid {
            storedKey = key
            isLicensed = true
        }
        
        return isValid
    }
}

// Add trial/license check to ContentView
struct ContentView: View {
    @StateObject private var licenseManager = LicenseManager.shared
    @State private var showLicenseWindow = false
    
    var body: some View {
        VStack {
            // Your existing content
            
            if !licenseManager.isLicensed && licenseManager.trialDaysRemaining == 0 {
                TrialExpiredBanner()
            }
        }
    }
}
```

## Day 5: Create Simple Website

### Using Carrd (1 hour, $19/year)
```
audioswitch-pro.carrd.co

# Sections:
1. Hero: Logo + "Instant Audio Switching for Mac"
2. Video demo (record with CleanShot)
3. Features list (6 key features)
4. Screenshots (3-4)
5. Price: $9.99 (Gumroad button)
6. FAQ (5 questions)
7. Contact: support@yourdomain.com
```

### Or GitHub Pages (Free)
```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>AudioSwitch Pro - Instant Audio Switching for Mac</title>
    <style>
        /* Simple, clean CSS */
    </style>
</head>
<body>
    <h1>AudioSwitch Pro</h1>
    <p>Switch audio devices instantly with keyboard shortcuts</p>
    <a href="https://gum.co/audioswitchpro" class="gumroad-button">Buy for $9.99</a>
    <script src="https://gumroad.com/js/gumroad.js"></script>
</body>
</html>
```

## Day 6: Prepare Launch Materials

### Screenshots (Already have)
- Main window
- Settings
- Device switching
- Menu bar

### Feature List
```
✓ Instant audio device switching
✓ Custom keyboard shortcuts per device
✓ Background operation
✓ Start hidden on login
✓ Menu bar control
✓ Native Apple Silicon + Intel support
```

### Launch Tweets/Posts
```
🎉 Just launched AudioSwitch Pro!

Tired of clicking through System Settings to change audio devices?

Switch instantly with keyboard shortcuts:
⌘⌥1 → AirPods
⌘⌥2 → Mac Speakers
⌘⌥3 → External Display

$9.99 - No subscription
audioswitch-pro.com
```

## Day 7: Launch!

### Where to Post
1. **Twitter/X**: Tag @MacStoriesNet, @9to5mac
2. **Reddit**:
   - r/macapps (Sunday for Self-Promo)
   - r/MacOS
   - r/apple (be subtle)
3. **ProductHunt**: Schedule for Tuesday
4. **Hacker News**: "Show HN: AudioSwitch Pro"
5. **MacUpdate.com**: Submit your app
6. **AlternativeTo.net**: Add your app

### Email Template for Bloggers
```
Subject: AudioSwitch Pro - Instant Audio Switching for Mac

Hi [Name],

I've just launched AudioSwitch Pro, a utility that lets Mac users switch audio devices instantly with keyboard shortcuts.

Key features:
- Custom shortcuts per device (e.g., ⌘⌥A for AirPods)
- Background operation
- Menu bar control
- Works on Apple Silicon & Intel

Price: $9.99 (one-time)
Link: audioswitch-pro.com

Would love your feedback!

Best,
[Your name]
```

## Revenue Tracking

### Simple Spreadsheet
```
Date | Sales | Revenue | Source
-----|-------|---------|--------
Day 1|   5   | $47.00  | Twitter
Day 2|   3   | $28.20  | Reddit
```

### First Month Goals
- 100 sales = $940 revenue (after fees)
- 200 sales = $1,880 revenue
- Break even on time: ~20 sales

## Support Setup

### FAQ Document
```markdown
# AudioSwitch Pro FAQ

Q: How do I set shortcuts?
A: Right-click any device → Set Shortcut

Q: Does it work with Bluetooth?
A: Yes! All audio devices supported

Q: Refund policy?
A: 30-day money back guarantee
```

### Support Email (Gmail)
- audioswitchpro@gmail.com
- Auto-responder with FAQ
- 24-hour response time

## Success Metrics

Week 1: 50 sales ($470)
Month 1: 200 sales ($1,880)
Month 3: 500 sales ($4,700)
Year 1: 2,000 sales ($18,800)

## Why This Works

1. **You solve a real problem** - People hate the audio switching hassle
2. **Fair price** - $9.99 is impulse buy territory  
3. **No subscription** - People love one-time purchases
4. **Quality app** - It actually works well
5. **Easy to explain** - "Switch audio devices with shortcuts"

## Start NOW!

1. Sign up for Gumroad (today)
2. Upload your app
3. Create basic website
4. Add license check (optional for week 1)
5. Launch and start making money!

Remember: You can always improve later. The best time to launch is now! 🚀