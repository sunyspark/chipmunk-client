require 'spec_helper'
require 'chipmunk_bagger'

RSpec.describe ChipmunkBagger do
  TAGFILES = %w(bag-info.txt bagit.txt chipmunk-info.txt manifest-md5.txt
  manifest-sha1.txt marc.xml)
  TAGMANIFESTS = %w(tagmanifest-md5.txt tagmanifest-sha1.txt)
  DATAFILES = %w(am000001.wav pm000001.wav mets.xml) 
  FIXTURES_PATH = File.join(Rails.application.root,"spec","support","fixtures")

  def make_bag
    ChipmunkBagger.new('audio','12345',@bag_path).make_bag
  end

  before(:each) do
    # don't actually fetch marc
    allow(Kernel).to receive(:open)
      .with("https://mirlyn.lib.umich.edu/Record/011500592.xml")
      .and_return(File.open(File.join(FIXTURES_PATH,"marc.xml")))
  end

  # set up data in safe area
  around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      fixture_data = File.join(FIXTURES_PATH,"audio","upload","good","data")
      @bag_path = File.join(tmpdir,"testbag")
      FileUtils.cp_r(fixture_data,@bag_path)
      example.run
    end
  end

  context "with stubbed ChipmunkBag" do
    before(:each) do
      bag = double(:bag)
      allow(ChipmunkBag).to receive(:new).and_return(bag)
      allow(bag).to receive(:"manifest!")
      allow(bag).to receive(:write_chipmunk_info)
      allow(bag).to receive(:add_tag_file)
    end

    let(:bag_data) { File.join(@bag_path,"data") }
    context "when the data dir exists" do
      before(:each) do 
        FileUtils.mkdir(bag_data)
      end

      it "doesn't move anything" do 
        begin
          make_bag
        rescue Errno::ENOENT
          # expected - METS is not already present in data dir
        end

        expect(Dir.entries(File.join(@bag_path,"data"))).to contain_exactly(".","..")
      end
    end

    context "when data dir doesn't exist" do
      it "creates the data dir" do 
        make_bag
        expect(File).to exist(bag_data)
      end
     
      DATAFILES.each do |file|
        it "moves #{file} to the data dir" do 
          make_bag
          expect(File).to exist(File.join(bag_data,file))
        end
      end
    end

    context "when mets.xml doesn't exist" do
      before(:each) do
        File.unlink(File.join(@bag_path,"mets.xml"))
      end

      it "reports an error" do
        expect { make_bag }.to raise_error(Errno::ENOENT,/mets.xml/)
      end
    end

    context "when mets.xml doesn't have a MARC record" do
      before(:each) do
        FileUtils.copy(File.join(FIXTURES_PATH,"audio","mets-nomarc.xml"),
                            File.join(@bag_path,"mets.xml"))
      end

      it "reports an error" do
        expect { make_bag }.to raise_error(ArgumentError,/MARC/)
      end
    end

    context "when MARC link isn't to mirlyn" do
      before(:each) do
        FileUtils.copy(File.join(FIXTURES_PATH,"audio","mets-nonmirlyn.xml"),
                            File.join(@bag_path,"mets.xml"))
      end
      it "reports an error" do
        expect { make_bag }.to raise_error(ArgumentError,/does not match mirlyn/)
      end
    end
  end
    
  # move these tests to ChipmunkBag?
  it "creates the expected tag files" do
    make_bag
    TAGFILES.each do |tagfile|
      expect(File).to exist(File.join(@bag_path,tagfile))
    end
  end

  TAGMANIFESTS.each do |tagmanifest|
    it "includes all tag files in #{tagmanifest}" do 
      make_bag
      expect(File.readlines(File.join(@bag_path,tagmanifest))
        .map { |l| l.strip.split[1] }).to contain_exactly(*TAGFILES)
    end
  end

  it "creates a valid ChipmunkBag" do 
    make_bag
    expect(ChipmunkBag.new(@bag_path)).to be_valid
  end

end
