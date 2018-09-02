RSpec.describe Twib do
  it "has a version number" do
    expect(Twib::VERSION).not_to be nil
  end

  describe Twib::ResultError do
    it "has a properly formatted message" do
      expect(Twib::ResultError.new(0xf601).message).to eq "0xf601"
    end
  end

  describe Twib::Response do
    describe :assert_ok do
      it "throws ResultError when result_code is not OK" do
        expect do
          Twib::Response.new(0, 0, 0xf601, 0, String.new, []).assert_ok
        end.to raise_error(Twib::ResultError, "0xf601")
      end

      it "returns self when result_code is OK" do
        rs = Twib::Response.new(0, 0, 0, 0, String.new, [])
        expect(rs.assert_ok).to eq(rs)
      end
    end
  end

  describe Twib::ActiveRequest do
    describe :wait do
      it "synchronizes using tc.mutex" do
        tc = double("TwibConnection", :mutex => Mutex.new)
        rs = double("Response")

        expect(tc).to receive :mutex
        
        rq = Twib::ActiveRequest.new(tc, 0, 0, 0, 0, String.new)
        rq.respond(rs)
        expect(rq.wait).to eq(rs)
      end
      
      it "does not attempt to wait if there is already a response" do
        tc = double("TwibConnection", :mutex => Mutex.new)
        rs = double("Response")
        cv = double("CondVar")
        
        rq = Twib::ActiveRequest.new(tc, 0, 0, 0, 0, String.new)
        rq.respond(rs)
        rq.instance_variable_set(:@condvar, cv)
        expect(rq.wait).to eq(rs)
      end
    end
    
    describe :wait_ok do
      it "asserts that the response is OK" do
        tc = double("TwibConnection", :mutex => Mutex.new)
        rs = double("Response", :result_code => 0xf601)

        expect(tc).to receive :mutex
        expect(rs).to receive :assert_ok { rs }
        
        rq = Twib::ActiveRequest.new(tc, 0, 0, 0, 0, String.new)
        rq.respond(rs)
        expect(rq.wait_ok).to eq(rs)
      end
    end
  end

  describe Twib::TwibConnection do
    describe :send do
      it "serializes the request correctly and sends it over the socket" do
        socket = double("socket")

        expect(socket).to receive(:send).with([1, 2, 3, 4, 5, 0, 0, "abcde"].pack("L<L<L<L<Q<L<L<a*"), 0).and_return(32 + 5)
        allow(socket).to receive(:recv).with(32) do
          Thread.current.exit
        end
        
        tc = Twib::TwibConnection.new(socket)
        expect(tc).to receive(:rand).and_return(4) # tag
        tc.send(1, 2, 3, "abcde")

        expect(socket).to receive(:close)
        tc.close
      end
    end
  end
end
