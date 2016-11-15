require_relative '../lib/magma/server'

describe Magma::Server do
  describe ".route" do
    it "adds a route to the server" do
      block = Proc.new do
        :hello
      end
      Magma::Server.route '/test', &block
      expect(Magma::Server.routes['/test']).to eq(block)
    end
  end
  describe "#initialize" do
    it "connects to a magma instance" do
      config = {
        test: :ok
      }

      magma = double(Magma, configure: true)
      allow(Magma).to receive(:instance).and_return(magma)
      server = Magma::Server.new(config)

      expect(magma).to have_received(:configure).with(config)
    end
  end

  describe "#call" do
    it "responds to the appropriate route" do

      controller = double("controller")
      allow(controller).to receive(:invoked)
      Magma::Server.route '/test2' do
        controller.invoked
      end

      magma = double(Magma, configure: true)
      allow(Magma).to receive(:instance).and_return(magma)
      server = Magma::Server.new({})

      server.call({
        'PATH_INFO' => '/test2'
      })

      expect(controller).to have_received(:invoked)
    end
  end
end

describe Magma::Server::Controller do
  it "should generate an invalid response by default" do
    c = Magma::Server::Controller.new(nil)

    expect(c.response.first).to eq(501)
  end
end

describe Magma::Server::Retrieve do
  before :each do
    @request = double("rack::request")
  end

  it "should require a model_name" do
    allow(@request).to receive(:env).and_return(
      "rack.request.json" => {
        "record_names" => ["some_record"],
        "model_name" => nil
      }
    )
    retrieve = Magma::Server::Retrieve.new(@request)

    expect(retrieve.response.first).to eq(422)
  end
  it "should require record_names" do
    allow(@request).to receive(:env).and_return(
      "rack.request.json" => {
        "record_names" => nil,
        "model_name" => "some_model"
      }
    )
    retrieve = Magma::Server::Retrieve.new(@request)

    expect(retrieve.response.first).to eq(422)
  end
  it "attempts to retrieve records" do
    retrieval = double("magma::retrieval")
    allow(retrieval).to receive(:perform)
    allow(retrieval).to receive(:success?).and_return(true)
    allow(retrieval).to receive(:payload)
    allow(Magma::Retrieval).to receive(:new).and_return(retrieval)

    allow(@request).to receive(:env).and_return(
      "rack.request.json" => {
        "record_names" => ["some_record"],
        "model_name" => "some_model"
      }
    )

    retrieve = Magma::Server::Retrieve.new(@request)
    response = retrieve.response

    expect(retrieval).to have_received(:payload)
    expect(response.first).to eq(200)
  end
end