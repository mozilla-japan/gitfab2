# frozen_string_literal: true

describe ProjectDecorator do
  it_behaves_like "OGP Interface Test", Project

  let(:project) do
    project = FactoryBot.create(:project, title: title, description: description, owner: owner)
    project.extend(ProjectDecorator)
  end
  let(:title) { "My Fabble Project Title" }
  let(:description) { "My Fabble Project Description" }
  let(:owner) { FactoryBot.create(:user, name: owner_name) }
  let(:owner_name) { "owner-name" }

  describe "#first_figure" do
    before do
      FactoryBot.create(:figure, figurable: project)
      FactoryBot.create(:figure, figurable: project)
    end
    it { expect(project.first_figure).to eq project.figures.first }
  end

  describe "#ogp_title" do
    context "when title exists" do
      it { expect(project.ogp_title).to eq "#{title} by #{owner_name}" }
    end

    context "when title does not exist" do
      let(:project) { Project.new.extend(ProjectDecorator) }
      it { expect(project.ogp_title).to be nil }
    end
  end

  describe "#ogp_description" do
    it { expect(project.ogp_description).to eq description }
  end

  describe "#ogp_image" do
    let(:base_url) { "https://fabble.cc" }
    let!(:figure) { FactoryBot.create(:content_figure, figurable: project) }
    it { expect(project.ogp_image(base_url)).to eq "#{base_url}#{figure.content.url}" }
  end

  describe "#ogp_video" do
    let!(:figure) { FactoryBot.create(:link_figure, figurable: project) }
    it { expect(project.ogp_video).to eq figure.link }
  end
end