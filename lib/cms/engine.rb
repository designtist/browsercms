# Load just enough dependencies for this file to be loadable.
require 'cms/module'

module Cms
  class Engine < Rails::Engine
    include Cms::Module
    isolate_namespace Cms

    config.cms = ActiveSupport::OrderedOptions.new
    config.cms.attachments = ActiveSupport::OrderedOptions.new

    # Allows additional menu items to be added to the 'Tools' menu on the Admin tab.
    config.cms.tools_menu = ActiveSupport::OrderedOptions.new

    # Define configuration for the CKEditor
    config.cms.ckeditor = ActiveSupport::OrderedOptions.new

    # Configuration for content types.
    config.cms.content_types = ActiveSupport::OrderedOptions.new

    # Configuration for working on BrowserCMS core.
    # We want these configuration for generators.
    config.generators do |g|
      g.test_framework :mini_test, :spec => true, :fixture => false
      g.stylesheets false
    end

    # Configuration for projects using BrowserCMS>
    # Need to use our rails model template (rather then its default) when `rails g cms:content_block` is run.
    config.app_generators do |g|
      path = File::expand_path('../../templates', __FILE__)
      g.templates.unshift path
    end

    # Ensure Attachments are configured:
    # 1. Before every request in development mode
    # 2. Once in production
    config.to_prepare do
      Attachments.configure
    end

    # Set reasonable defaults
    # These default values can be changed by developers in their projects in their application.rb or environment's files.
    config.before_configuration do |app|
      WillPaginate.per_page = 15

      # Default cache directories.
      app.config.cms.mobile_cache_directory = File.join(Rails.root, 'public', 'cache', 'mobile')
      app.config.cms.page_cache_directory = File.join(Rails.root, 'public', 'cache', 'full')

      # Default storage for uploaded files
      app.config.cms.attachments.storage = :filesystem
      app.config.cms.attachments.storage_directory = File.join(Rails.root, 'tmp', 'uploads')

      # Determines if a single domain will be used (i.e. www) or multiple subdomains (www and cms). Enabling this will
      # turn off page caching and not handle redirects between subdomains.
      app.config.cms.use_single_domain = false

      # Used to send emails with links back to the Cms Admin. In production, this should include the www. of the public site.
      # Matters less in development, as emails generally aren't sent.
      # I.e.
      #   config.cms.site_domain = "www.browsercms.org"
      app.config.cms.site_domain = "localhost:3000"

      # Determines what email sender will be applied to messages generated by the CMS.
      # By default, this is based on the site_domain, i.e. mailbot@example.com
      app.config.cms.mailbot = :default

      # Allows Addressable content types and Controllers to set which template will be used for page layouts.
      # This takes precedence over the :template attribute set on models/controllers.
      #    Keys are looked up based on Class.name.underscore
      # @example:
      #   config.cms.templates['cms/form'] = 'my-form-layout' # app/views/layouts/templates/my-form-layout
      #   config.cms.templates['cms/sites/sessions_controller'] = 'subpage' # For /login
      #
      app.config.cms.templates = {}

      # Determines which ckeditor file will be used to configure all instances.
      # There should be at most ONE of these, so use manifest files which require the below one to augement it.
      app.config.cms.ckeditor.configuration_file = 'bcms/ckeditor_standard_config.js'

      # Define menu items to be added dynamically to the CMS Admin tab.
      app.config.cms.tools_menu = []

      # Disable portlets so they don't appear in menus and can't be created. Existing portlets will not be deleted.
      app.config.cms.content_types.blacklist = [:login_portlet, :forgot_password_portlet, :dynamic_portlet]

      # Initialization
      require 'cms/configure_simple_form'
      require 'cms/configure_simple_form_bootstrap'
      require 'cms/configuration/devise'

      # Sets the default .css file that will be added to forms created via the Forms module.
      # Projects can override this as needed.
      app.config.cms.form_builder_css = 'cms/default-forms'
    end

    # Needed to ensure routes added to the main app by the Engine are available. (Since engine draws its routes after the main app)
    # Borrrow from Spree as documenented here: https://github.com/rails/rails/issues/11895
    config.after_initialize do
      Rails.application.routes_reloader.reload!
    end

    initializer 'browsercms.add_core_routes', :after => 'action_dispatch.prepare_dispatcher' do |app|
      ActionDispatch::Routing::Mapper.send :include, Cms::RouteExtensions
    end

    initializer 'browsercms.add_load_paths', :after => 'action_controller.deprecated_routes' do |app|

      ActiveSupport::Dependencies.autoload_paths += %W( #{self.root}/vendor #{self.root}/app/mailers #{self.root}/app/helpers)
      ActiveSupport::Dependencies.autoload_paths += %W( #{self.root}/app/controllers #{self.root}/app/models #{self.root}/app/portlets)
      ActiveSupport::Dependencies.autoload_paths += %W( #{Rails.root}/app/portlets )
      ActiveSupport::Dependencies.autoload_paths += %W( #{Rails.root}/app/presenters )
      ActiveSupport::Dependencies.autoload_paths += %W( #{Rails.root}/app/portlets/helpers )
      ActionController::Base.append_view_path DynamicView.base_path
      ActionController::Base.append_view_path %W( #{self.root}/app/views)
      ActionView::Base.default_form_builder = Cms::FormBuilder::ContentBlockFormBuilder
      require 'jdbc_adapter' if defined?(JRUBY_VERSION)
    end

    initializer "browsercms.precompile_assets" do |app|
      app.config.assets.precompile += ['cms/application.css']
    end

  end
end