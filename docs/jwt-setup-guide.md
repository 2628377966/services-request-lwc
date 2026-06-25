# CI/CI pipeline JWT Authentication Setup Guide for GitHub CI/CD Pipeline

This guide walks you through setting up JWT authentication between your Salesforce PlayGround org and GitHub Actions for automated CI/CD deployment.

## Overview

JWT (JSON Web Token) authentication provides secure, server-to-server authentication without storing passwords. It uses cryptographic key pairs to establish trust between Salesforce and your CI/CD pipeline.

## Prerequisites

- Admin access to your Salesforce PlayGround org
- GitHub repository with admin access
- Git Bash or OpenSSL installed (for key generation)
- Salesforce CLI installed locally (for testing)

---

## Step 1: Generate RSA Key Pair

### Option A: One-Command Method (Simplest - Works Fine)

```bash
# Open Git Bash or terminal and run(in windows you use \\ instead of \ //):
openssl req -x509 -newkey rsa:2048 -keyout private.key -out public.crt -days 3650 -nodes -subj "/CN=CICDPipeline"
```
This single command creates both files (private key + self-signed certificate).

### What You Get 

This process produces two files:
- **`private.key`** - Keep this secret! (Upload to GitHub)
- **`public.crt`** - Upload this to Salesforce

**Note**: The `-days 3650` (10 years) vs `-days 365` (1 year) only affects certificate validity. Salesforce doesn't reject certificates based on expiration for JWT auth, but longer periods mean less frequent rotation.

---

## Step 2: Create Connected App in Salesforce

1. **Login to your PlayGround org** as an administrator
2. **Navigate to Setup** → Search for "App Manager" → Click **"New Connected App"**

### Basic Information
- **Connected App Name**: `GitHub CI/CD Pipeline`
- **API Name**: `GitHub_CICD_Pipeline`
- **Contact Email**: Your email address

### API Settings
- ✅ Check **"Enable OAuth Settings"**
- **Callback URL**: `http://localhost:1717/oauth/callback`

### OAuth Scopes
Add these required scopes:
- **Manage** user data via APIs (api)
- **Manage** the user data via Web browsers (web)
- **Perform** requests at any time (refresh_token, offline_access)

### Enable JWT Bearer Flow
- ✅ Check **"Enable JWT Bearer Flow"**
- upload `public.crt`

### Security
- ✅ Check **"Require secret for Web Server Flow"**
- ✅ Check **"Require secret for Refresh Token Flow"**
- ✅ Check **"Issue JSON Web Token (JWT)-based access tokens for named users"**

### Policies
- Select Profiles: **System Administrator**
- Under Oauth Policies: 
    Plugin Policies
    ✅ Check **"Admin approved users are pre-authorized"**
- App Authorization
    ✅ Check **"Expire refresh token after specific time"**
    set Refresh Token Validity Period to 90 days


### Save and Note Values
Click **Save** and note down under OAuth Policies:
- **Consumer Key**: This becomes your `SALESFORCE_CLIENT_ID`
- **Username**: Your PlayGround org username

⚠️ **Important**: Wait 2-10 minutes for changes to propagate in Salesforce

---

## Step 3: Configure GitHub Secrets

1. Go to your **GitHub your repository**
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"** and add these three secrets:

### Secret 1: SALESFORCE_CLIENT_ID
- **Name**: `SALESFORCE_CLIENT_ID`
- **Value**: The **Consumer Key** from your Connected App
- **Example**: `3MVG9A2kN3Bn17huXxxxxxxx.xxxxxxxxx`

### Secret 2: SALESFORCE_USERNAME
- **Name**: `SALESFORCE_USERNAME`
- **Value**: Your PlayGround org login email/username
- **Example**: `admin@playground-org.example.com`

### Secret 3: SALESFORCE_JWT_KEY
- **Name**: `SALESFORCE_JWT_KEY`
- **Value**: The **entire contents of `private.key` file**
- **Important**: Include the full PEM format including headers:

```
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC7v8...
...rest of the base64-encoded key content...
-----END PRIVATE KEY-----
```

---

## Step 4: Test Authentication Locally

Before using in CI/CD, test JWT auth on your local machine:

### Install Salesforce CLI (if not already installed)
```bash
npm install -g @salesforce/cli
```

### Test Authentication
```bash
sf org login jwt \
    --username SALESFORCE_USERNAME \
    --jwt-key-file private.key \
    --client-id SALESFORCE_CLIENT_ID \
    --alias PlayGround \
    --set-default \
    --instance-url https://login.salesforce.com
```

If successful, you'll see connection details displayed.

### Verify Connection
```bash
sf org display
```

This should show your PlayGround org details.

---

## Quick Reference: Files Summary

| File | Purpose | Location |
|------|---------|----------|
| `private.key` | Private RSA key | Upload to GitHub Secret |
| `public.crt` | Public certificate | Upload to Salesforce Connected App |

## Quick Reference: GitHub Secrets Summary

| Secret Name | Source | Example Value |
|-------------|--------|---------------|
| `SALESFORCE_CLIENT_ID` | Connected App Consumer Key | `3MVG9A2kN3Bn17hu...` |
| `SALESFORCE_PLAYGROUND_USERNAME` | Org Login Email | `user@org.playground` |
| `SALESFORCE_JWT_KEY` | Contents of private.key | Full PEM format |

---

## Validation Checklist

Before running the pipeline, verify all items are complete:

- [ ] Generated RSA 2048-bit key pair
- [ ] Created Connected App in PlayGround org
- [ ] Approved Connected App in System Administrator profile
- [ ] Uploaded public.crt to Connected App
- [ ] Saved Consumer Key as SALESFORCE_CLIENT_ID
- [ ] Waited 10+ minutes for Salesforce propagation
- [ ] Added all 3 secrets to GitHub repository
- [ ] Tested authentication successfully using local test script
- [ ] Verified no errors in local authentication test

---

## Additional Resources

- [Salesforce Connected Apps Documentation](https://help.salesforce.com/articleView?id=connected_app_overview.htm&type=5)
- [Salesforce JWT Bearer Flow](https://help.salesforce.com/articleView?id=remoteaccess_oauth_jwt_flow.htm&type=5)
- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Salesforce CLI Auth Commands](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_auth.htm)

---

**Last Updated**: June 2026  
**Pipeline Version**: v1.0  
**Target Environment**: Salesforce PlayGround Org
