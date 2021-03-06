require 'rails_helper'

describe "imports/index.html.haml" do
  include Capybara::RSpecMatchers
  before do
    assign(:imports, imports)
  end
  let(:imports) { [] }

  subject { render template: 'nfg_csv_importer/imports/index' }

  context 'when there are no previous imports' do
    it "should indicate there are no imports" do
      expect(subject).to match(/There are no Imports/)
    end
  end

  context 'when the ImportDefinition.import_types has values' do
    before do
      ImportDefinition.stubs(:import_types).returns([])
    end

    it "should not have any links to a new import" do
      expect(subject).not_to have_selector(".panel-heading a")
    end
  end

  context "when the ImportDefinition.import_types returns values" do
    before do
      ImportDefinition.stubs(:import_types).returns([:user, :donation])
    end

    it "should display a link to each of the types" do
      expect(subject).to have_selector(".panel-heading a[href$='/new?import_type=user']")
      expect(subject).to have_selector(".panel-heading a[href$='/new?import_type=donation']")
    end
  end
end
