require "spec_helper"

feature "Beta Pages" do
  scenario "Should display beta page", js: true do
    visit root_path
    current_path.should eql beta_path
    page.should have_content "Make us happy"
  end
  
  scenario "Should display error when password is wrong", js: true do
    visit root_path
    current_path.should eql beta_path
    fill_in "password", with: "invalid"
    find("[type='submit']").click
    page.should have_content "No, not really."
  end
  
  scenario "Should sign in with correct password", js: true do
    visit root_path
    current_path.should eql beta_path
    fill_in "password", with: "sayonara555"
    find("[type='submit']").click
    page.should have_content "structure your organisation in seconds"
  end
end
