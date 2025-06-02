# OAuth Configuration Template
# Copy this file to .env-oauth and fill in your actual values
# NEVER commit the .env-oauth file to version control

# Sensitive OAuth credentials for OpenWebUI
# These values will be stored securely in AWS Secrets Manager

# Microsoft Azure AD OAuth Configuration
MICROSOFT_CLIENT_SECRET=your-microsoft-client-secret-here

# General OAuth Configuration
OAUTH_CLIENT_SECRET=your-oauth-client-secret-here

# OpenID Provider Configuration
OPENID_PROVIDER_URL=https://your-openid-provider-url/openid-configuration

# Example values for reference:
# MICROSOFT_CLIENT_SECRET=abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
# OAUTH_CLIENT_SECRET=your-oauth-application-secret-key
# OPENID_PROVIDER_URL=https://login.microsoftonline.com/your-tenant-id/v2.0/.well-known/openid-configuration
