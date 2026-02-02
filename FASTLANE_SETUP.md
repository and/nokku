# Fastlane Setup Guide for Nokku

This guide will help you set up Fastlane to automate app deployments to Google Play Store.

## Prerequisites

✅ Already completed:
- Fastlane files created in `android/fastlane/`
- App bundle built at `build/app/outputs/bundle/release/app-release.aab`

## Step 1: Install Fastlane

Choose one of the following methods:

### Option A: Using Homebrew (Recommended for Mac)
```bash
# Fix permissions first
sudo chown -R $(whoami) /opt/homebrew/share/zsh /opt/homebrew/share/zsh/site-functions

# Install Fastlane
brew install fastlane
```

### Option B: Using RubyGems
```bash
gem install fastlane --user-install

# Add to PATH (add this to your ~/.zshrc or ~/.bash_profile)
export PATH="$HOME/.gem/ruby/2.6.0/bin:$PATH"
source ~/.zshrc
```

### Option C: Using Bundler (Project-specific)
```bash
# Create Gemfile in project root
cd /Users/anand_temp/Code_p/safe_gallery

echo "source 'https://rubygems.org'" > Gemfile
echo "" >> Gemfile
echo "gem 'fastlane'" >> Gemfile

# Install
bundle install

# Run fastlane via bundle
bundle exec fastlane --version
```

Verify installation:
```bash
fastlane --version
```

---

## Step 2: Create Google Play Service Account

1. **Go to Google Play Console**
   - Visit https://play.google.com/console
   - Select your app

2. **Enable Google Play Developer API**
   - Go to https://console.cloud.google.com/apis/library
   - Search for "Google Play Android Developer API"
   - Click **Enable**

3. **Create Service Account**
   - Go to https://console.cloud.google.com/iam-admin/serviceaccounts
   - Click **Create Service Account**
   - Name: `fastlane-deployer`
   - Click **Create and Continue**

4. **Grant Permissions**
   - Click **Select a role**
   - Search and select: **Service Account User**
   - Click **Continue** → **Done**

5. **Create JSON Key**
   - Click on the service account you just created
   - Go to **Keys** tab
   - Click **Add Key** → **Create new key**
   - Choose **JSON** format
   - Click **Create**
   - Save the downloaded JSON file securely

6. **Grant Play Console Access**
   - Go back to Google Play Console
   - Go to **Setup** → **API access**
   - Find your service account and click **Grant access**
   - Permissions needed:
     - ✅ View app information and download bulk reports
     - ✅ Manage production releases
     - ✅ Manage testing track releases
   - Click **Invite user** → **Send invite**

---

## Step 3: Configure Fastlane

1. **Copy the JSON key file**
   ```bash
   # Create a secure directory for credentials
   mkdir -p android/fastlane/keys

   # Copy your downloaded JSON file there
   cp ~/Downloads/your-service-account-key.json android/fastlane/keys/google-play-api.json

   # Add to .gitignore to keep it secure
   echo "android/fastlane/keys/" >> .gitignore
   ```

2. **Update Appfile**
   ```bash
   # Edit android/fastlane/Appfile
   # Change the json_key_file line to:
   json_key_file("keys/google-play-api.json")
   ```

---

## Step 4: Available Fastlane Commands

Once setup is complete, you can use these commands:

### Upload Existing Bundle to Production
```bash
cd android
fastlane upload_bundle
```

### Build and Deploy to Production
```bash
cd android
fastlane deploy
```

### Deploy to Internal Testing
```bash
cd android
fastlane internal
```

### Deploy to Beta Testing
```bash
cd android
fastlane beta
```

### Promote Internal to Production
```bash
cd android
fastlane promote_to_production
```

---

## Step 5: First Deployment

To upload your current bundle (v1.0.1+2):

```bash
cd /Users/anand_temp/Code_p/safe_gallery/android
fastlane upload_bundle
```

This will upload: `build/app/outputs/bundle/release/app-release.aab`

---

## Troubleshooting

### Error: "No json_key_file specified"
- Make sure you've updated the `Appfile` with the correct path to your JSON key

### Error: "The caller does not have permission"
- Wait a few minutes after granting Play Console access
- Verify the service account has the correct permissions in Play Console

### Error: "Google Api Error: forbidden"
- Make sure you've enabled the "Google Play Android Developer API"
- Check that the service account is linked in Play Console API access

### Error: "No valid auth token"
- The JSON key file path is incorrect or file is missing
- Check the path in `Appfile` is relative to the `fastlane` directory

---

## Security Best Practices

✅ **DO:**
- Keep JSON key files in a secure location
- Add `keys/` directory to `.gitignore`
- Use environment variables for sensitive data
- Rotate service account keys periodically

❌ **DON'T:**
- Commit JSON keys to Git
- Share keys in plain text
- Use production keys in development

---

## Quick Start Summary

1. Install Fastlane: `brew install fastlane`
2. Create service account and download JSON key
3. Copy JSON to `android/fastlane/keys/google-play-api.json`
4. Update `Appfile` with key path
5. Grant Play Console access to service account
6. Run: `cd android && fastlane upload_bundle`

---

## Current Configuration

**App Package:** `com.safegallery`
**Current Version:** 1.0.1 (Build 2)
**Bundle Location:** `../build/app/outputs/bundle/release/app-release.aab`

**Available Lanes:**
- `fastlane deploy` - Build + deploy to production
- `fastlane internal` - Build + deploy to internal
- `fastlane beta` - Build + deploy to beta
- `fastlane upload_bundle` - Upload existing bundle to production
- `fastlane promote_to_production` - Promote internal to production

For more information: https://docs.fastlane.tools/
