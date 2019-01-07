describe Moral::Config do
  it "loads config" do
    expect(YAML).to receive(:load_file).with("moral.yml").and_return({})
    #YAML.should_receive(:load_file).with("moral.yml").and_return({})
    cfg = Moral::Config.instance
  end
end
