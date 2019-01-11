describe Moral::Config do
  describe "shared" do
    before(:each) do
      expect(File).to receive(:read).with("moral.yml").and_return(File.read("spec/moral01.yml"))
      @cfg = Moral::Config.new
    end
    it "loads config" do
      # Config loader
    end
    it "loads balancers" do
      expect(@cfg.balancers.length).to eq(1)
    end
    it "loads nodes" do
      expect(@cfg.balancers.first.nodes.length).to eq(2)
    end
  end
  describe "static" do
    it "static cfg instance" do
      expect(File).to receive(:read).once.with("moral.yml").and_return(File.read("spec/moral01.yml"))
      cfg1 = Moral::Config.instance
      cfg2 = Moral::Config.instance
      expect(cfg1).to be(cfg2)
    end

    describe "methods" do
      it "finds existing service" do
        cfg = Moral::Config.instance
        balancer = cfg.service?(address: "192.168.239.6", port: 8080)
        expect(balancer.name).to eq("balancer1")
        expect(balancer.scheduler).to eq("rr")
      end
      it "returns nil on non-found" do
        cfg = Moral::Config.instance
        balancer = cfg.service?(address: "192.168.139.6", port: 8080)
        expect(balancer).to eq(nil)
      end
    end
  end
end
