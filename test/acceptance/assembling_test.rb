
require_relative "helper"

# All the tests for when we are assembling files
feature "Assembling", :js => true do
  # Load the app
  background do
    visit "/"
  end

  scenario "Displays the disassembly dump" do
    # Click the assemble button
    click_button 'assemble'

    # Assert that it goes to the "Run" tab
    assert page.has_css?('li#run-panel.tab-panel.active')

    # Assert that the assembly dump has content
    assert page.has_css?('table.instructions tbody tr td')
  end
end
