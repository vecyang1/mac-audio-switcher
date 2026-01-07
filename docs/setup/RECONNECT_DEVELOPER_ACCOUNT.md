# Reconnecting to Paid Developer Account

Since your friend has the $99/year Apple Developer Program, let's fix the connection:

## Step 1: Remove Current Account
1. In Xcode Accounts (where you are now)
2. Select viviscallers@gmail.com
3. Click the "-" button to remove it completely

## Step 2: Create App-Specific Password
You need an app-specific password for Xcode:

1. Go to https://appleid.apple.com/account/manage
2. Sign in with viviscallers@gmail.com
3. In "Sign-In and Security" section
4. Click "App-Specific Passwords"
5. Click "+" to generate a new password
6. Name it "Xcode"
7. Copy the generated password (looks like: xxxx-xxxx-xxxx-xxxx)

## Step 3: Add Account Back
1. In Xcode Accounts, click "+"
2. Choose "Apple ID"
3. Enter: viviscallers@gmail.com
4. For password, use the app-specific password you just created
5. Click "Sign In"

## Step 4: Wait for Teams to Load
After signing in:
- Wait a few seconds for teams to sync
- You should see TWO teams:
  - ve cs (Personal Team) - your free personal team
  - Your friend's team name (with Team ID) - the paid team

## Step 5: Select Correct Team
1. Go back to your project settings
2. In Signing & Capabilities
3. The Team dropdown should now show both teams
4. Select your friend's team (NOT "Personal Team")

## If Still Not Working:

Ask your friend for:
1. **Team Name** (exactly as it appears in their developer account)
2. **Team ID** (10 character code like ABC123DEFG)

Then we can try manual configuration.