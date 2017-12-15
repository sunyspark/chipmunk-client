# frozen_string_literal: true

require "pathname"

module CopyBagSteps

  step "I copy a test bag to :location" do |location|
    bag_dir = Pathname.new(__FILE__)
      .expand_path
      .dirname
      .parent + "fixtures" + "test_bag"
    puts "copying #{bag_dir} to #{location}"
    @copy_result = system("cp", "-rp", bag_dir.to_s, location)
  end

  step "copy finishes successfully" do
    expect(@copy_result).to be true
  end

end

RSpec.configure {|config| config.include CopyBagSteps }
