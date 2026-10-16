class Admin::BaseController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    raise ActiveRecord::RecordNotFound unless admin?
  end

  def admin?
    current_user&.admin?
  end
end
