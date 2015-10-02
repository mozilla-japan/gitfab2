require "spec_helper"

describe GlobalProjectsController, type: :controller do
  disconnect_sunspot
  render_views

  describe 'GET index' do
    context 'without queries' do
      before{xhr :get, :index}
      it{expect(response).to render_template :index}
    end
    context 'with a querie' do
      before{xhr :get, :index, q: 'foo'}
      it{expect(response).to render_template :index}
    end

    context 'with multi queries' do
      before{xhr :get, :index, q: 'foo bar'}
      it{expect(response).to render_template :index}
    end

    context 'with empty queries' do
      before{xhr :get, :index, q: ''}
      it{expect(response).to render_template :index}
    end
  end
end
