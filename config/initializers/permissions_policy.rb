# Backport of the upstream we-promise/sure Permissions-Policy initializer
# (first shipped in v0.7.7-alpha.10) to the v0.7.6-hotfix.2 stable image.

# The app never uses camera/microphone/usb/geolocation/payment/fullscreen
# APIs, so those are locked to :none.
#
# WebAuthn/passkeys are deliberately NOT restricted here: this Rails version's
# PermissionsPolicy DIRECTIVES list doesn't include
# publickey-credentials-get/-create, and Rails raises NoMethodError for any
# symbol outside its fixed DIRECTIVES map. Leaving it unlisted keeps the
# browser default (allowed), which is what passkey login/registration needs.
#
# Rails only sends this policy as the legacy Feature-Policy header, which
# Firefox and Safari ignore, so the same list also goes out as
# Permissions-Policy (each feature disabled with an empty allowlist).
disabled_features = %i[camera microphone geolocation usb payment fullscreen]

Rails.application.config.permissions_policy do |policy|
  disabled_features.each { |feature| policy.public_send(feature, :none) }
end

Rails.application.config.action_dispatch.default_headers["Permissions-Policy"] =
  disabled_features.map { |feature| "#{feature}=()" }.join(", ")
