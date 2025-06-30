# Connecting Your Friend's Paid Developer Account

## Quick Check First
Ask your friend:
1. Do they have a PAID Apple Developer account ($99/year)?
2. Can they confirm they see "Apple Developer Program" (not "Personal Team") in their Xcode?

## If They Have a Paid Account:

### Option A: Add You as Team Member (Recommended)
Your friend needs to:
1. Log into https://appstoreconnect.apple.com
2. Go to Users and Access
3. Add you with "Developer" role
4. You'll receive an invitation email

### Option B: Use Their Credentials (Less Secure)
1. In Xcode, click "Add an Account..."
2. Sign in with their Apple ID
3. Select their team (should show company name, not "Personal Team")

### Option C: Build on Their Computer
Send them the project and have them build/notarize it

## If They DON'T Have a Paid Account:

You cannot notarize the app. Your options are:

1. **Get Your Own Developer Account** ($99/year)
   - Sign up at https://developer.apple.com
   - Takes 24-48 hours to activate

2. **Distribute Unsigned** (Users get warnings)
   - Build the app without notarization
   - Users must manually approve in System Settings

3. **Use Alternative Platforms**
   - Gumroad, Paddle, or similar
   - Can distribute unsigned apps with payment processing

## Current Status
Right now you only have access to "ve cs (Personal Team)" which is a free account and cannot be used for distribution.