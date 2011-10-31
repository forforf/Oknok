require_relative "../lib/oknok/store_factory"
require 'fileutils'
require 'psych'

#Module providing accessibility of the store (exists, readable, writable, etc)
#require_relative 'store_status'
module YourConfigData
  #Default location of config file (must be manually set)
  DatastoreConfig = File.join( File.dirname(__FILE__),
    "../sample_store_config")
end

describe Oknok::StoreBase, "Setting configuration file" do
  include Oknok

  before :each do
    @config_file = YourConfigData::DatastoreConfig
  end

  it "raises error if config file is set to non-existant file" do
    expect{ StoreBase.set_config_file_location('/bar/foo/baz') }.to 
      raise_error IOError
  end

  it "can set the config file location" do
    StoreBase.get_config_file_location.should == nil
    StoreBase.set_config_file_location(@config_file)
    StoreBase.get_config_file_location.should == @config_file
  end

  it "raises error if config file disappears" do
    #set initial conditions
    tmp_config = "/tmp/data_store_config"
    FileUtils.cp @config_file, tmp_config
    StoreBase.set_config_file_location(tmp_config)
    #test
    FileUtils.rm tmp_config
    #validate
    expect{ StoreBase.read_config_data }.to raise_error IOError
    #clean up
    StoreBase.set_config_file_location(@config_file)
  end

  it "can read the config file without blowing up" do
    config_data = StoreBase.read_config_data
    config_data.should_not == nil
    config_data.empty?.should_not == true
  end
end

describe Oknok::StoreBase, "Creates the store from config data" do
  include Oknok

  before :each do
    @oknok_name = "test_name"
    @config_data = StoreBase.read_config_data
  end

  it "reads the config data" do
    @config_data.keys.should include "avail_stores"
  end

  it "creates stores of the right type from config file with oknok name" do
    all_store_data = @config_data["avail_stores"]
    store_names = all_store_data.keys
    store_names.each do |store_name|
      store_data = all_store_data[store_name]
      config_file_type = store_data['type']
      store_obj = StoreBase.make(store_name, @oknok_name)
      store_obj.kind_of?(StoreBase).should == true
      store_obj.class.store_type.should == config_file_type
    end
  end
end

describe Oknok::StoreBase, "common initialization tasks" do
  include Oknok

  before :each do
    @oknok_name = "test_name"
    config_data = StoreBase.read_config_data
    @all_store_data = config_data["avail_stores"]
    @store_names = @all_store_data.keys
    @store_objs = @store_names.map do |name| 
      StoreBase.make(name, @oknok_name)
    end
  end

  it "has a store name" do
    @store_objs.each_with_index do |sto, idx|
      sto.store_name.should == @store_names[idx]
    end
  end

  it "has an oknok name" do
    @store_objs.each_with_index do |sto, idx|
      sto.oknok_name.should == @oknok_name
    end
  end

  it "has host data" do
    @store_objs.each do |sto|
      sto_data = @all_store_data[sto.store_name]
      sto.host.should == StoreNameLookup.config_reader(sto_data)
    end
  end

  it "has StoreAccess methods included" do
    @store_objs.each do |sto|
      sto.kind_of?(StoreAccess).should == true
    end
  end


  it "has StoreAccess extended (class methods)" do
    @store_objs.each do |sto|
      sto.class.include?(StoreAccess).should == true
    end
  end

  it "collects instances" do
    num_stores_in_config = @store_names.size
    num_objs_made = @store_objs.size
    num_objs_made.should == num_stores_in_config
    collected_instances = StoreBase.get_my_instances
    collected_instances.size.should == num_objs_made
  end
end


##include StoreAccess shared tests
#require_relative 'store_access_shared_spec'

#describe "included module behavior" do
#  include Oknok
  
#  shared_examples_for "StoreAccess" do
#    #StoreBase.set_config_file_location(YourConfigData::DatastoreConfig)
#    #p Oknok::StoreBase.read_config_data
#    let(:objs) = [1,2,3,4]
#    it "dummy" do
#      p "dummy"
#    end
#  end
  #test module behavior
  #oknok_name = "test_name"
  #config_data = Oknok::StoreBase.read_config_data
  #all_store_data = config_data["avail_stores"]
  #store_names = all_store_data.keys
  #store_objs = store_names.map{|name| StoreBase.make(name, oknok_name)}
#end



describe Oknok::StoreBase, "Factory" do
  include Oknok

  before :each do
    @oknok_name = "test_name"
    config_data = StoreBase.read_config_data
    @all_store_data = config_data["avail_stores"]
    @store_names = @all_store_data.keys
    @store_objs = @store_names.map{|name| StoreBase.make(name, @oknok_name)}
    @reach_map = {}
    @store_objs.each do |sto|
    end
  end


  it "intializes with a reachability status " do
    @store_objs.each do |sto|
      StoreAccess::Reachable::Levels.should include sto.status
    end
  end

  #Mock this out for testing
  it "should have a collection by reachability status" do
    reach = StoreBase.all_reachability
    reach.each do |reach, stores|
      puts "#{reach} => #{stores.map{|sto| sto.store_name}}.inspect"
    end
  end

end

