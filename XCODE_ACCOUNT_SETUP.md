# Setting Up Xcode with Your Team Account

## You have Admin access! ✅
- Account: viviscallers@gmail.com  
- Role: Admin
- Access: All Apps

## Now connect it to Xcode:

### Step 1: Open Xcode Preferences
1. In Xcode, go to **Xcode → Settings** (or press ⌘,)
2. Click the **Accounts** tab

### Step 2: Add Your Account
1. Click the **"+"** button at the bottom left
2. Select **"Apple ID"**
3. Sign in with **viviscallers@gmail.com**
4. Use your Apple ID password (for viviscallers@gmail.com)

### Step 3: Check Account Status
After signing in, you should see:
- viviscallers@gmail.com
- Under it should show the team name (your friend's organization)
- It should say "Apple Developer Program" (not just "Personal Team")

### Step 4: Go Back to Project Settings
1. Click on **AudioSwitchPro** in the project navigator
2. Select the **AudioSwitchPro** target
3. Go to **Signing & Capabilities** tab
4. In the **Team** dropdown, you should now see:
   - Your friend's team name (not "Personal Team")
   - Select it!

## If You Still Don't See the Team:

1. **Sign out and sign in again** in Xcode Accounts
2. **Restart Xcode** after adding the account
3. Make sure you're using the exact email: viviscallers@gmail.com

## Important Note:
The team name in Xcode might show as:
- Your friend's name (baobao)
- A company name
- Something like "baobao (XXXXXXXXX)" where X is the Team ID

Select whichever option is NOT "Personal Team".