module Releaf
  # Releaf::TestHelpers provides a facility to simplify admin functionality testing
  module TestHelpers
    def auth_as_user(full_login = false, factory = :user)
      if factory.is_a? Releaf::Permissions::User
        user = factory
      else
        user = create(factory)
      end
      if full_login
        visit "/"
        within("form.login") do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: user.password
        end

        click_button 'Sign in'
      else
        login_as user
      end

      return user
    end

    def stub_settings(values)
      unless @releaf_settings_default_stubbed
        allow(Releaf::Settings).to receive(:[]).and_call_original
        @releaf_settings_default_stubbed = true
      end

      values.each_pair do|key, value|
        allow(Releaf::Settings).to receive(:[]).with(key).and_return(value)
      end
    end

    def update_resource(&block)
      within "form.edit-resource" do
        yield
      end
      save_and_check_response "Update succeeded"
    end

    def create_resource(&block)
      click_link "Create new resource" unless first("form.new-resource")
      within "form.new-resource" do
        yield
      end
      save_and_check_response "Create succeeded"
    end

    def within_search(&block)
      within("form.search") do
        yield
      end
    end

    def search(text)
      within_search do
        fill_in 'search', with: text
      end
    end

    def within_dialog(&block)
      if find(".dialog") && first('.dialog form[data-remote-validation=true]')
        find('.dialog form[data-remote-validation-initialized=true]') # wait for validation to initialize
      end
      within(".dialog") do
        yield
      end
    end

    def save_and_check_response(status_text)
      click_button 'Save'
      expect(page).to have_css('body > .notifications .notification[data-id="resource_status"][data-type="success"]', text: status_text)
    end

    # As there is no visual UI for settings update being successful
    # do check against database
    def wait_for_settings_update(key, value = true)
      safety = 5
      while !(@user.settings.try(:[], key) == value) && (safety > 0)
        safety -= 1
        sleep 0.5
      end
    end

    def open_toolbox_dialog(item_name, resource = nil)
      open_toolbox(item_name, resource)
      expect(page).to have_css('.dialog form[data-remote-validation=true][data-remote-validation-initialized=true]')
    end

    def open_toolbox(item_name, resource = nil, resource_selector_scope = ".view-index .table tr")
      if resource
        find(resource_selector_scope + '[data-id="' + resource.id.to_s  + '"] .toolbox button.trigger:not([disabled])').click
      else
        find('main section header .toolbox-wrap .toolbox button.trigger:not([disabled])').click
      end

      click_link item_name
    end

    def fill_in_richtext(locator, options = {} )
      # locator can be anything that is normally accepted by fill_in
      # e.g., the label text or the id of the textarea

      expect(page).to have_css('.field.type-richtext label')

      # locate possibly hidden textarea among active/visible richtext fields ignoring hidden localization versions
      textareas = []
      richtext_boxes = all(".field.type-richtext:not(.i18n), .field.type-richtext.i18n .localization.active")
      richtext_boxes.each do |richtext_box|
        textarea = richtext_box.first(:field, locator, visible: false)
        textareas << textarea if textarea.present?
      end

      if textareas.count > 1
        raise Capybara::Ambiguous.new("Ambiguous match, found #{target_textareas.count} richtext boxes matching #{locator}")
      elsif textareas.count < 1
        raise Capybara::ElementNotFound.new("Unable to find richtext box #{locator}")
      end

      textarea_id = textareas.first[:id].to_s
      expect(page).to have_css("##{textarea_id}.ckeditor-initialized", visible: false) # wait for ckeditor appearance
      html = options[:with].to_s
      page.execute_script("jQuery('##{textarea_id}').val(#{html.to_json})")

    end


  end
end
