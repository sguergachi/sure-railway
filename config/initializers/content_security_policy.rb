# Backport of the upstream we-promise/sure Content-Security-Policy initializer
# (first shipped in v0.7.7-alpha.10) to the v0.7.6-hotfix.2 stable image.
#
# Adapted for the stable codebase: v0.7.6 has no config/initializers/00_posthog.rb,
# so the PostHog host allowlist is omitted. Everything else matches upstream.
#
# The view templates that carry inline <script> tags were given the matching
# nonce by this image as well (see app/views/** in this repository).
#
# Set CSP_REPORT_ONLY=true to send the policy as
# Content-Security-Policy-Report-Only instead of enforcing it.

csp_origin = lambda do |url|
  uri = URI.parse(url.to_s.strip)
  next unless %w[http https].include?(uri.scheme) && uri.host.present?

  port = uri.port == uri.default_port ? "" : ":#{uri.port}"
  "#{uri.scheme}://#{uri.host}#{port}"
rescue URI::InvalidURIError
  nil
end

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data

    # blob: is required for the profile-picture upload preview
    # (URL.createObjectURL in app/javascript/controllers/profile_image_preview_controller.js).
    #
    # A generic_s3 endpoint can be plain http (e.g. a local MinIO), so its
    # origin is allowed explicitly when configured.
    s3_image_origins = lambda do
      s3_origin = csp_origin.call(ENV["GENERIC_S3_ENDPOINT"])
      next [] unless s3_origin

      bucket = ENV["GENERIC_S3_BUCKET"].to_s.strip
      path_style = ActiveModel::Type::Boolean.new.cast(ENV.fetch("GENERIC_S3_FORCE_PATH_STYLE", "false"))
      origins = [ s3_origin ]
      origins << s3_origin.sub("://", "://#{bucket}.") if bucket.match?(/\A[a-z0-9.-]+\z/i) && !path_style
      origins
    end
    policy.img_src :self, :https, :data, :blob, s3_image_origins

    # Plaid Link loads its widget from cdn.plaid.com at runtime via a
    # dynamically inserted <script> tag, which bypasses the nonce, so the
    # origin is allowlisted directly. The widget then opens an iframe from the
    # same host and talks to the Plaid API host of the active environment.
    plaid_api_hosts = %w[sandbox development production].map { |env| "https://#{env}.plaid.com" }
    plaid_cdn_host = "https://cdn.plaid.com"
    policy.frame_src :self, plaid_cdn_host

    policy.script_src  :self, plaid_cdn_host
    policy.connect_src :self, *plaid_api_hosts
    # unsafe-inline is scoped to styles only, never scripts.
    policy.style_src :self, :unsafe_inline
    policy.object_src :none
    # Blocks an injected <base href="..."> from redirecting relative asset URLs.
    policy.base_uri :self
    # Modern replacement for X-Frame-Options (kept by Rails' default headers).
    policy.frame_ancestors :self
  end

  # Every <script> element must carry this nonce to execute. Rails ties it to
  # the session id; injected markup cannot predict or read it.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src]

  config.content_security_policy_report_only = ActiveModel::Type::Boolean.new.cast(ENV.fetch("CSP_REPORT_ONLY", "false"))
end
