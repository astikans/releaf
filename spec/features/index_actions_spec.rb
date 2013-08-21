require 'spec_helper'
feature "Base controller index actions", js: true do
  background do
    auth_as_admin
    @good_book = FactoryGirl.create(:book, title: "good book")
    FactoryGirl.create(:book, title: "bad book")
  end

  scenario "keep search parameters when navigating to edit and back" do
    visit admin_books_path(search: "good")
    click_link("good book")
    click_link("Back to list")

    expect(page).to have_css('.main > .table > tbody .row', :count => 1)
  end


  scenario "keep search parameters after delete" do
    visit admin_books_path(search: "good")
    find('.toolbox button.trigger').click
    find('.toolbox-items li a.ajaxbox', text: "Delete").click
    find('.dialog.delete_dialog .footer button.danger', text: "Yes").click
    expect(page).to have_css('.main > .table th .nothing_found', :count => 1, :text => "Nothing found")
  end
end