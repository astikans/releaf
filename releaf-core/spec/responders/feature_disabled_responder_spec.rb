require "spec_helper"

describe Releaf::Responders::FeatureDisabledResponder, type: :controller do
  controller{}
  subject{ described_class.new(controller, []) }

  describe "#status_code" do
    it "returns 404" do
      expect(subject.status_code).to eq(403)
    end
  end
end
