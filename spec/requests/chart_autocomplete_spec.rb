require "spec_helper"

feature "Chart Autocomplete" do
  background do
    sign_in_beta_user
  end
  
  scenario "Should be able to display and hide autocomplete", js: true do
    create_chart
    # save_and_open_page
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
    find("#person_q").set("")
    page.driver.browser.execute_script "$j('#person_q').trigger('keyup')"
    find(".overlay.persons").should_not be_visible
  end
  
  scenario "Should be able to select placeholder", js: true do
    create_chart
    
    find(".add-person").click
    find("#person_q").set("@Vasya")
    page.driver.browser.execute_script "$j('#person_q').trigger('keyup')"
    
    find(".holder h3").should have_content "@Vasya"
    find(".holder").click
    
    find_field("chart_text").value.should eql("@Vasya\n")
  end
end
