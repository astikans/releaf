require 'spec_helper'

describe Releaf::Builders, type: :class do
  module Admin::Advanced
    class SickBuilder
    end
    class AuthorsController
    end
  end

  class Admin::Advanced::Builders < Releaf::Builders; end

  describe ".builder_class" do
    it "returns returns first resolved builder class" do
      allow(described_class).to receive(:scopes).with(Releaf::Permissions::UsersController).and_return(["a", "b", "c"])
      allow(described_class).to receive(:scoped_builder_class).with("a", :form).and_return(nil)
      allow(described_class).to receive(:scoped_builder_class).with("b", :form).and_return("x")
      allow(described_class).to receive(:scoped_builder_class).with("c", :form).and_return("y")

      expect(described_class.builder_class(Releaf::Permissions::UsersController, :form)).to eq("x")

      allow(described_class).to receive(:scoped_builder_class).with("b", :form).and_return(nil)
      expect(described_class.builder_class(Releaf::Permissions::UsersController, :form)).to eq("y")
    end
  end

  describe ".ignorable_error_pattern" do
    it "returns regexp pattern for matchin errors against scope and builder class name resolvation" do
      expect(described_class.ignorable_error_pattern("_some_scope_", "_some_class_name_"))
        .to eq(/uninitialized constant (_some_scope_|_some_class_name_)$/)
    end
  end

  describe ".scoped_builder_class" do
    context "when builder class for given scope and type exists" do
      it "returns resolved class" do
        expect(described_class.scoped_builder_class("Releaf::Permissions::Users", :form))
          .to eq(Releaf::Permissions::Users::FormBuilder)
      end
    end

    context "when NameError throwed while resolving builder class" do
      before do
        allow(Object).to receive(:const_get).with("Admin::Authors::FormBuilder")
          .and_raise(NameError, "uninitialized constant asdasd")
      end

      context "when ignorable NameError" do
        it "returns nil" do
          allow(described_class).to receive(:ignorable_error?)
            .with("uninitialized constant asdasd", "Admin::Authors", "Admin::Authors::FormBuilder")
            .and_return(true)

          expect(described_class.scoped_builder_class("Admin::Authors", :form)).to be nil
        end
      end

      context "when non ignorable NameError" do
        it "reraises it" do
          allow(described_class).to receive(:ignorable_error?)
            .with("uninitialized constant asdasd", "Admin::Authors", "Admin::Authors::FormBuilder")
            .and_return(false)

          expect{ described_class.scoped_builder_class("Admin::Authors", :form) }
            .to raise_error(NameError, "uninitialized constant asdasd")
        end
      end
    end

    it "does not catch errors other than NameError" do
      allow(Object).to receive(:const_get).and_call_original
      allow(Object).to receive(:const_get).with("Admin::Authors::FormBuilder").and_raise(ArgumentError, "xx")
      expect(described_class).to_not receive(:ignorable_error?)
      expect{ described_class.scoped_builder_class("Admin::Authors", :form) }
        .to raise_error(ArgumentError, "xx")
    end
  end

  describe ".ignorable_error?" do
    before do
      allow(described_class).to receive(:ignorable_error_pattern)
        .with("a", "b").and_return(/some ignorable error/)
    end

    context "when given error message matches against ingorable error pattern" do
      it "returns true" do
        expect(described_class.ignorable_error?("some ignorable error", "a", "b")).to be true
      end
    end

    context "when given error message does not match against ingorable error pattern" do
      it "returns false" do
        expect(described_class.ignorable_error?("some critical error", "a", "b")).to be false
      end
    end
  end

  describe ".scopes" do
    it "returns given controller scope merged with inherited builder scopes" do
      expect(described_class.scopes(Admin::Advanced::AuthorsController))
        .to eq(["Admin::Advanced::Authors", "Releaf::Builders"])
      expect(Admin::Advanced::Builders.scopes(Admin::Advanced::AuthorsController))
        .to eq(["Admin::Advanced::Authors", "Admin::Advanced::Builders", "Releaf::Builders"])
    end
  end

  describe ".inherited_builder_scopes" do
    it "returns inherited classes except Object and BasicObject" do
      expect(described_class.inherited_builder_scopes).to eq(["Releaf::Builders"])
      expect(Admin::Advanced::Builders.inherited_builder_scopes).to eq(["Admin::Advanced::Builders", "Releaf::Builders"])
    end
  end
end