require "spec_helper"

feature "Chart Autocomplete" do
  background do
    sign_in_beta_user
  end
  
  scenario "Should display autocomplete", js: true do
    create_chart
    # save_and_open_page
    page.should have_content "My chart"
    find(".overlay.persons").should_not be_visible
    
    # Trigger using symbol
    fill_in("chart_text", with: "@")
    find(".overlay.persons").should be_visible
    # Close using esc
    page.driver.browser.execute_script "Mousetrap.trigger('esc')"
    find(".overlay.persons").should_not be_visible
    
    # Using button
    find(".add-person").click
    find_field("chart_text").value.should eql("@")
    find(".overlay.persons").should be_visible
    # Close using backspace
    fill_in("person_q", with: "")
    find(".overlay.persons").should_not be_visible
  end
end
