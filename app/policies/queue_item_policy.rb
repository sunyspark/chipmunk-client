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
        scope.joins(:request).where(requests: {user_id: user.id })
      end
    end
  end
end
