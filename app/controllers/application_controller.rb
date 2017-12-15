# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  # Use pundit for authz.  Ensure that we've either called 'authorize' or
  # 'policy_scope' in every controller action.
  # When someone is unauthorized, render nothing and return 403.
  include Pundit
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Add a before_action to authenticate all requests.
  # Move this to subclassed controllers if you only
  # want to authenticate certain methods.
  before_action :authenticate
  before_action :set_format_to_json

  attr_reader :current_user

  protected

  def user_not_authorized
    head 403
  end

  def set_format_to_json
    request.format = :json
  end

  # Authenticate the user with token based authentication
  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_with_http_token do |token, _options|
      @current_user = User.find_by(api_key: token)
    end
  end

  def render_unauthorized(realm = "Application")
    headers["WWW-Authenticate"] = %(Token realm="#{realm.delete('"')}")
    render json: "Bad credentials", status: :unauthorized
  end

end
