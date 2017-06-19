require "pathname"

module RsyncSteps

  step "I rsync a test bag to :location" do |location|
    bag_dir = Pathname.new(__FILE__)
      .expand_path
      .dirname
      .parent
      + "fixtures"
      + "test_bag"
    puts "rsyncing #{bag_dir.to_s} to #{location}"
    @rsync_result = system('rsync','-avzq', bag_dir.to_s, location)
  end

  step "rsync finishes successfully" do
    expect(@rsync_result).to be true
  end

end

RSpec.configure {|config| config.include RsyncSteps}

