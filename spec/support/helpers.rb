def sign_in_beta_user
  visit root_path
  fill_in "password", with: "sayonara555"
  find("[type='submit']").click
end

def create_chart
  find(".create[href='/charts']").click
end
