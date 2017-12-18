# frozen_string_literal: true

require "open3"

module Chipmunk::Validatable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def validators
      @validators ||= []
    end

    def validates(precondition: ->{}, condition:, error:)
      validators << lambda do
        precond_result = instance_exec(&precondition)
        if instance_exec(*precond_result, &condition)
          true
        else
          @errors.push(instance_exec(*precond_result, &error))
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

class BagMoveJob < ApplicationJob

  def perform(queue_item)
    @queue_item = queue_item
    @src_path = queue_item.bag.src_path
    @dest_path = queue_item.bag.dest_path
    @errors = []

    begin
      @bag = ChipmunkBag.new(src_path) if File.exist?(src_path)
      # TODO
      #  - if all validation succeeds:
      #    - start a transaction that updates the request to complete
      #    - move the bag into place
      #    - success: commit the transaction
      #    - failure (exception) - transaction automatically rolls back
      if valid?
        FileUtils.mkdir_p(File.dirname(dest_path))
        File.rename(src_path, dest_path)
        record_success
      else
        record_failure
      end
    rescue StandardError => exception
      @errors.push(exception.to_s)
      record_failure
      raise exception
    end
  end

  private

  attr_accessor :queue_item, :src_path, :dest_path, :bag

  include Chipmunk::Validatable

  def record_failure
    queue_item.transaction do
      queue_item.error = @errors.join("\n\n")
      queue_item.status = :failed
      queue_item.save!
    end
  end

  validates condition: -> { File.exist?(src_path) },
      error: -> { "Bag does not exist at upload location #{src_path}" }

  validates condition: -> { File.exist?(src_path) },
      error: -> { "Bag does not exist at upload location #{src_path}" }

  validates condition: -> { bag.valid? },
      error: -> { "Error validating bag:\n" + indent_array(bag.errors.full_messages) }

  ["Metadata-URL", "Metadata-Type", "Metadata-Tagfile"].each do |tag|
    validates condition: -> { bag.chipmunk_info.key?(tag) },
        error: -> { "Missing required tag #{tag} in chipmunk-info.txt" }
  end

  validates condition: -> { bag.tag_files
                           .map {|f| File.basename(f) }
                           .include?(bag.chipmunk_info["Metadata-Tagfile"]) },
      error: -> { "Missing referenced metadata #{bag.chipmunk_info["Metadata-Tagfile"]}" }

  validates precondition: -> { Open3.capture3(queue_item.bag.external_validation_cmd) },
      condition: ->(_, _, status) { status == 0 },
      error: ->(_, stderr, _) { "Error validating content\n" + stderr }

  validates condition:  -> { bag.chipmunk_info["External-Identifier"] == queue_item.bag.external_id },
      error: -> { "uploaded External-Identifier '#{bag.chipmunk_info["External-Identifier"]}'" +
                  " does not match intended ID '#{queue_item.bag.external_id}'" }

  def record_success
    queue_item.transaction do
      queue_item.status = :done
      queue_item.save!
      queue_item.bag.storage_location = dest_path
      queue_item.bag.save!
    end
  end

  def indent_array(array, width = 2)
    array.map {|s| " " * width + s }.join("\n")
  end

end
