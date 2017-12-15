# frozen_string_literal: true

require "timecop"

module TimeSteps

  def travel_to(time, &block)
    Timecop.travel Time.parse(time), &block
  end

  def freeze_time_at(time, &block)
    Timecop.freeze Time.parse(time), &block
  end

  step "it is currently :time" do |time|
    travel_to time
  end

  step "time is frozen at :time" do |time|
    freeze_time_at time
  end

  step "it is the present" do
    Timecop.return
  end

  RSpec.configure do |config|
    config.after(type: feature) do
      Timecop.return
    end
  end

end

RSpec.configure {|config| config.include TimeSteps }
