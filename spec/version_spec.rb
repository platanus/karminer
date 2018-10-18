require 'spec_helper'

describe Karminer::VERSION do
  it "contains a valid version" do
    expect(Karminer::VERSION).to match /^\d+\.\d+\.\d+$/
  end
end
