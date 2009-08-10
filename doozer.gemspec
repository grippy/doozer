# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{doozer}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["grippy"]
  s.date = %q{2009-08-10}
  s.default_executable = %q{doozer}
  s.description = %q{This GEM provides a small, barebones framework for creating MVC Rack applications.}
  s.email = %q{gmelton@whorde.com}
  s.executables = ["doozer"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/doozer",
     "doozer.gemspec",
     "lib/doozer.rb",
     "lib/doozer/README.rb",
     "lib/doozer/active_support/array.rb",
     "lib/doozer/active_support/class.rb",
     "lib/doozer/active_support/date_time.rb",
     "lib/doozer/active_support/object.rb",
     "lib/doozer/active_support/time.rb",
     "lib/doozer/app.rb",
     "lib/doozer/configs.rb",
     "lib/doozer/controller.rb",
     "lib/doozer/extend.rb",
     "lib/doozer/initializer.rb",
     "lib/doozer/lib.rb",
     "lib/doozer/logger.rb",
     "lib/doozer/orm/active_record.rb",
     "lib/doozer/orm/data_mapper.rb",
     "lib/doozer/orm/sequel.rb",
     "lib/doozer/partial.rb",
     "lib/doozer/plugins/paginate/init.rb",
     "lib/doozer/plugins/paginate/lib/paginate.rb",
     "lib/doozer/plugins/paginate/lib/paginate/collection.rb",
     "lib/doozer/plugins/paginate/lib/paginate/finder.rb",
     "lib/doozer/plugins/paginate/lib/paginate/view_helpers.rb",
     "lib/doozer/rackup/server.ru",
     "lib/doozer/rackup/test.rb",
     "lib/doozer/redirect.rb",
     "lib/doozer/route.rb",
     "lib/doozer/scripts/cluster.rb",
     "lib/doozer/scripts/migrate.rb",
     "lib/doozer/scripts/task.rb",
     "lib/doozer/scripts/test.rb",
     "lib/doozer/version.rb",
     "lib/doozer/view_helpers.rb",
     "lib/doozer/watcher.rb",
     "lib/generator/generator.rb",
     "templates/skeleton/Rakefile",
     "templates/skeleton/app/controllers/application_controller.rb",
     "templates/skeleton/app/controllers/index_controller.rb",
     "templates/skeleton/app/helpers/application_helper.rb",
     "templates/skeleton/app/views/global/_header.html.erb",
     "templates/skeleton/app/views/global/_navigation.html.erb",
     "templates/skeleton/app/views/index/index.html.erb",
     "templates/skeleton/app/views/layouts/default.html.erb",
     "templates/skeleton/config/app.yml",
     "templates/skeleton/config/database.yml",
     "templates/skeleton/config/environment.rb",
     "templates/skeleton/config/rack.rb",
     "templates/skeleton/config/routes.rb",
     "templates/skeleton/script/cluster",
     "templates/skeleton/script/migrate",
     "templates/skeleton/script/task",
     "templates/skeleton/script/test",
     "templates/skeleton/static/404.html",
     "templates/skeleton/static/500.html",
     "templates/skeleton/static/css/style.css",
     "templates/skeleton/static/favicon.ico",
     "templates/skeleton/static/js/application.js",
     "templates/skeleton/static/js/jquery-1.3.min.js",
     "templates/skeleton/static/robots.txt",
     "templates/skeleton/test/fixtures/setup.rb",
     "templates/skeleton/test/setup.rb",
     "test/doozer_test.rb",
     "test/test_helper.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/grippy/doozer}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A little MVC framework for Rack applications.}
  s.test_files = [
    "test/doozer_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
