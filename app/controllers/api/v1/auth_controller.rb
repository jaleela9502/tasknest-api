# frozen_string_literal: true

module Api
  module V1
    # AuthController handles register, login, logout, and password reset.
    # Skip JWT auth for public actions (register / login / password reset).
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [
        :register, :login, :forgot_password, :reset_password
      ]

      # POST /api/v1/auth/register
      # Body: { name, email, password, password_confirmation }
      def register
        user = User.new(register_params)

        if user.save
          token = JwtService.encode(user.id)
          render_success(
            { user: serialize_resource(user, serializer: UserSerializer), token: token },
            "Registration successful",
            status: :created
          )
        else
          render_error("Registration failed", user.errors.full_messages)
        end
      end

      # POST /api/v1/auth/login
      # Body: { email, password }
      def login
        email = params[:email].to_s.strip.downcase
        user = User.find_by(email: email)

        if user&.authenticate(params[:password])
          token = JwtService.encode(user.id)
          render_success(
            { user: serialize_resource(user, serializer: UserSerializer), token: token },
            "Login successful"
          )
        else
          render_error("Invalid email or password", nil, status: :unauthorized)
        end
      end

      # DELETE /api/v1/auth/logout
      # Blacklists the current JWT so it cannot be reused.
      def logout
        header = request.headers["Authorization"]
        token = header.to_s.split(" ").last
        payload = JwtService.decode(token)

        if payload
          TokenBlacklist.create!(
            jti: payload["jti"],
            expires_at: Time.at(payload["exp"])
          )
        end

        render_success(nil, "Logout successful")
      end

      # POST /api/v1/auth/forgot_password
      # Body: { email }
      # Always returns success (even if email is unknown) to avoid leaking accounts.
      def forgot_password
        email = params[:email].to_s.strip.downcase
        user = User.find_by(email: email)

        if user
          raw_token = user.generate_password_reset_token!
          # For learning: log the token instead of sending a real email.
          Rails.logger.info("Password reset token for #{user.email}: #{raw_token}")
        end

        render_success(
          nil,
          "If that email exists, a password reset token has been generated. Check the server logs in development."
        )
      end

      # POST /api/v1/auth/reset_password
      # Body: { token, password, password_confirmation }
      def reset_password
        user = User.find_by_valid_reset_token(params[:token])

        if user.nil?
          return render_error("Invalid or expired reset token", nil, status: :unprocessable_content)
        end

        if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
          user.clear_password_reset_token!
          render_success(nil, "Password has been reset successfully")
        else
          render_error("Password reset failed", user.errors.full_messages)
        end
      end

      private

      def register_params
        params.permit(:name, :email, :password, :password_confirmation)
      end
    end
  end
end
