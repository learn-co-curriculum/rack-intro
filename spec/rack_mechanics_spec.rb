require 'spec_helper.rb'

describe "MyServer" do
  it "should say hello" do
    get "/"
    expect(last_response.body).to include ("Hello")
  end
end
