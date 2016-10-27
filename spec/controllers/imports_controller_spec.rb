require 'rails_helper'

describe NfgCsvImporter::ImportsController do
  let(:entity) { create(:entity) }
  let(:user) { create(:user) }
  let(:import_type) { 'user' }
  let(:file_name) {"spec/fixtures/subscribers.csv"}
  let(:import) { assigns(:import) }
  let(:params) { { import_type: import_type, use_route: :nfg_csv_importer } }
  let(:file) do
    extend ActionDispatch::TestProcess
    fixture_file_upload(file_name, 'text/csv')
  end

  before { controller.stubs(:current_user).returns(user) }

  render_views

  it "should assign subscriber import service" do
    get :new, params
    expect(import.import_type).to eq(import_type)
  end

  it "should assign import status" do
    get :new, params
    expect(import.status).to eq("queued")
  end

  it "new action should render new template" do
    get :new, params
    expect(response).to render_template(:new)
  end

  it "create action should render new template on import error" do
    post :create, params
    expect(response).to render_template(:new)
  end


  describe "#create" do
    before do
      NfgCsvImporter::Import.any_instance.stubs(:valid?).returns(true)
      NfgCsvImporter::ProcessImportJob.stubs(:perform_later).returns(mock)
    end
    let(:import) { Import.last }

    subject { post :create, params }

    it { expect(subject).to change(Import, :count).by(1) }

    it "should redirect when import is successfully placed in queue" do
      subject
      expect(response).to redirect_to(edit_import_path(import))
    end

    it "should add import job to queue" do
      NfgCsvImporter::ProcessImportJob.expects(:perform_later).once
      subject
    end

    it "should display success message" do
      subject
      expect(flash[:notice]).to eq I18n.t('import.create.notice')
    end
  end

  describe "#destroy" do
    let!(:import) { create(:import, imported_for: entity) }
    let(:params) { { id: import.id, use_route: :nfg_csv_importer } }
    let!(:imported_records) { create_list(:imported_record, 3, import: import) }

    before do
      NfgCsvImporter::ImportedRecord.stubs(:batch_size).returns(2)
      NfgCsvImporter::DestroyImportJob.stubs(:perform_later).returns(mock)
      controller.stubs(:entity).returns(entity)
    end

    subject { delete :destroy, params }

    it "adds the job to the queue" do
      NfgCsvImporter::DestroyImportJob.expects(:perform_later).twice
      subject
    end

    it "does not delete the imported records" do
      NfgCsvImporter::ImportedRecord.any_instance.expects(:destroy).never
      subject
    end

    it "sets the import's status to deleting" do
      subject
      expect(import.reload.status).to eql("deleting")
    end
  end
end
