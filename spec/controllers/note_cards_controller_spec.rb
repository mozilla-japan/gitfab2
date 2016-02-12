require "spec_helper"

describe NoteCardsController, type: :controller do
  disconnect_sunspot
  render_views

  let(:project){FactoryGirl.create :user_project}
  let(:note_card){project.note.note_cards.create title: "foo", description: "bar"}
  let(:new_note_card){project.note.note_cards.build title: "foo", description: "bar"}
  let(:user){project.owner}

  subject{response}

  describe "GET new" do
    before do
      xhr :get, :new, owner_name: user.id, project_id: project.id
    end
    it{should render_template :new}
  end

  describe "GET edit" do
    before do
      xhr :get, :edit, owner_name: user.id, project_id: project.id,
        id: note_card.id
    end
    it{should render_template :edit}
  end

  describe "POST create" do
    context "without attachments" do
      before do
        xhr :post, :create, user_id: user.id, project_id: project.id,
          note_card: new_note_card.attributes
        project.reload
      end
      it{should render_template :create}
      it{expect(project.note).to have(1).note_cards}
    end
    context "with attachments" do
      before do
        xhr :post, :create, user_id: user.id, project_id: project.id,
          note_card: new_note_card.attributes.merge({
            attachments_attributes: [{_type: Attachment::Material, content: UploadFileHelper.upload_file}]})
        project.reload
      end
      it{expect(project.note.note_cards.first).to have(1).attachments}
      it do
        expect(project.note.note_cards.first.attachments.first)
          .to be_a Attachment::Material
      end
    end
    context "with incorrect params" do
      before do
        xhr :post, :create, user_id: user.id, project_id: project.id, note_card: {incorrect: "params"}
      end
      it{expect render_template 'error/failed', status: 400}
    end
  end

  describe "PATCH update" do
    context "with correct params" do
      let(:title_to_change){"_foo"}
      before do
        xhr :patch, :update, user_id: user.id, project_id: project.id,
          id: note_card.id, note_card: {title: title_to_change}
        note_card.reload
      end
      it{should render_template :update}
      it{expect(project.note.note_cards.first.title).to eq title_to_change}
    end

    context "with incorrect params" do
      before do
        xhr :patch, :update, user_id: user.id, project_id: project.id,
          id: note_card.id, note_card: {title: "", description: ""}
      end
      it{expect render_template 'error/failed', status: 400}
    end
  end

  describe "DELETE destroy" do
    before do
      xhr :delete, :destroy, owner_name: user.id, project_id: project.id,
        id: note_card.id
      project.reload
    end
    it{should render_template :destroy}
    it{expect(project.note.note_cards).to have(0).note_cards}
  end
end
