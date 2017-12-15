# frozen_string_literal: true

class QueueItemPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    user&.admin? || record&.user == user
  end

  def create?(request)
    user&.admin? || request&.user == user
  end

  def destroy?
    show?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.joins(:bag).where(bags: { user_id: user.id })
      end
    end
  end
end
