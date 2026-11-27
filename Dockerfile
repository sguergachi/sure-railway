# Sure (we-promise/sure) with the security headers backported from the next
# upstream release. Base image is pinned by digest so a moved :stable tag can
# never change what runs in production.
FROM ghcr.io/we-promise/sure:v0.7.6-hotfix.2@sha256:08f4fb26cedd0e5743792178ee744c1ea8b3ccd8cd9da1941ffc3ba7ef16ae6c

# Content-Security-Policy + Permissions-Policy (upstream v0.7.7-alpha.10).
COPY config/initializers/content_security_policy.rb /rails/config/initializers/content_security_policy.rb
COPY config/initializers/permissions_policy.rb /rails/config/initializers/permissions_policy.rb

# Inline <script> tags that upstream gave a CSP nonce in the same release.
COPY app/views/doorkeeper/authorizations/form_post.html.erb /rails/app/views/doorkeeper/authorizations/form_post.html.erb
COPY app/views/layouts/_dark_mode_check.html.erb /rails/app/views/layouts/_dark_mode_check.html.erb
COPY app/views/layouts/_privacy_mode_check.html.erb /rails/app/views/layouts/_privacy_mode_check.html.erb
COPY app/views/layouts/print.html.erb /rails/app/views/layouts/print.html.erb
COPY app/views/sessions/mobile_sso_start.html.erb /rails/app/views/sessions/mobile_sso_start.html.erb
