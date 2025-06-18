# Make GitHub Repository Private

## 🔒 Steps to Make Your Repository Private

### Option 1: Via GitHub Website
1. Go to your repository: https://github.com/vecyang1/mac-audio-switcher
2. Click **"Settings"** tab (on the right side of the repository navigation)
3. Scroll down to **"Danger Zone"** section at the bottom
4. Click **"Change repository visibility"**
5. Select **"Make private"**
6. Type your repository name to confirm: `mac-audio-switcher`
7. Click **"I understand, change repository visibility"**

### Option 2: Via GitHub CLI (if you have gh installed)
```bash
# Install GitHub CLI if not already installed
brew install gh

# Authenticate with GitHub
gh auth login

# Make repository private
gh repo edit vecyang1/mac-audio-switcher --visibility private
```

## ✅ Verification
After making it private:
- Only you will be able to see the repository
- The repository will show a "Private" badge
- Search engines won't index the content
- Public access will be denied

## 🎯 Current Status
Your repository is currently **public** and contains:
- Complete AudioSwitch Pro source code
- Documentation and build scripts
- No sensitive information (good!)

Making it private will protect your intellectual property while you continue development.