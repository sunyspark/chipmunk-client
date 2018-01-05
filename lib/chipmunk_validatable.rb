# frozen_string_literal: true

module ChipmunkValidatable

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validators
      @validators ||= []
    end

    def validates(_description = "", only_if: ->{true}, precondition: ->{}, condition:, error:)
      validators << lambda do
        return true unless instance_exec(&only_if)

        precond_result = instance_exec(&precondition)
        if instance_exec(*precond_result, &condition)
          true
        else
          errors << instance_exec(*precond_result, &error)
          false
        end
      end
    end

  end

  def valid?
    self.class.validators.reduce(true) do |result, validator|
      result && instance_exec(&validator)
    end
  end

end
