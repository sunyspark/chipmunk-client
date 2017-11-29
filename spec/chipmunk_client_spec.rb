require "spec_helper"

describe ChipmunkClient do
  let(:url) { "https://www.example.com" }
  let(:api_key) { 'mykey' }
  subject { ChipmunkClient.new(url: url, api_key: api_key) }

  shared_examples_for "a ChipmunkClient http method" do |method|
    it "parses the response" do 
      stub_request(method, "#{url}/something")
        .to_return({ body: '{"foo":"bar"}' })

      expect(subject.public_send(method,'/something')).to eql({ "foo" => "bar"})
    end

    it "follows 201 redirection" do
      stub_request(method, "#{url}/something")
        .to_return(status: 201, headers: { 'Location' => "#{url}/elsewhere" })
      stub_request(:get, "#{url}/elsewhere")
        .to_return({ body: '{}' })

      subject.public_send(method,'/something')

      expect(a_request(:get, "#{url}/elsewhere"))
        .to have_been_requested
    end

    it "handles errors by raising a ChipmunkClientError" do
      stub_request(method, "#{url}/error")
        .to_return(status: 500, body: '{}' )

      expect{subject.public_send(method,"/error")}
        .to raise_exception(ChipmunkClientError)
    end

    it "handles errors by raising an error that encapsulates the returned error" do
      stub_request(method, "#{url}/error")
        .to_return(status: 500, body: '{ "exception": "some problem" }' )

      expect{subject.public_send(method,"/error")}
        .to raise_exception do |error|
        expect(error.service_exception).to match(/some problem/)
      end
    end

    it "uses the provided auth header" do
      stub_request(method, url)
        .to_return({ body: '{}' })

      subject.public_send(method,'/')
      expect(a_request(method, url)
        .with(headers: { 'Authorization' => "Token token=#{api_key}" }))
        .to have_been_requested
    end
  end

  describe '#post' do
    it "makes the request with the given parameters" do
      stub_request(:post, url)
        .to_return({ body: '{}' })

      subject.post('/', { foo: "bar" })
      expect(a_request(:post, url)
        .with(body: { "foo" => "bar" }))
        .to have_been_requested
    end

    it_behaves_like "a ChipmunkClient http method", :post
  end

  describe '#get' do
    it "makes the request" do
      stub_request(:get, url)
        .to_return({ body: '{}' })

      subject.get('/')
      expect(a_request(:get, url))
        .to have_been_requested
    end

    it_behaves_like "a ChipmunkClient http method", :get
  end
end
