require "spec_helper"

describe VacanciesController do
  before do
    @user = create :user
    sign_in @user
  end
  
  describe "search" do
    it "should return search results for title" do
      organization = create :organization_with_owner, user: @user
      vacancy = create :vacancy, organization: organization
      vacancy.index.refresh
      
      get :search, { format: :json, organization_id: organization.id, search: { query: vacancy.title } }
      body = parse_json(response.body)
      body.to_json.should be_json_eql({ vacancies: [vacancy] }.to_json)
      
      vacancy.destroy
    end
  end
end
