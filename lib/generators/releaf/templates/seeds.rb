# encoding: UTF-8

Releaf::Role.delete_all
Releaf::Admin.delete_all

Settings.delete_all

# Role {{{

# build all roles list
roles = {
  administrator: {
    name:     'administrator',
    permissions: Releaf.available_admin_controllers
  },
  content_manager: {
    name:     'content manager',
    permissions: [
      'releaf/content'
    ]
  }
}

roles.each_value do |value|
  value[:id] = Releaf::Role.create!(value).id
end

# }}}
# Admin {{{

puts "Creating admins"
admins = {
  admin: {
    name: 'Admin',
    surname: 'User',
    password: 'password',
    password_confirmation: 'password',
    locale: "en",
    email: 'admin@example.com',
    role_id: roles[:administrator][:id],
  },
  content_admin: {
    name: 'Simple',
    surname: 'User',
    password: 'password',
    password_confirmation: 'password',
    locale: "en",
    email: 'user@example.com',
    role_id: roles[:content_manager][:id]
  }
}

admins.each_value do |value|
  value[:id] = Releaf::Admin.create!(value).id
end

# }}}
# Settings {{{

puts "Creating settings"
Settings.i18n_locales  = %w[en]
Settings.i18n_admin_locales  = %w[en]
Settings.email_from = "do_not_reply@example.com"

# }}}


# vim: set fdm=marker: