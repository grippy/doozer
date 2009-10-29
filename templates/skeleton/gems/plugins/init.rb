"""
There are a few different methods you can call to load plugins and gems from this file.

1. Doozer.plugin('folder', 'init_file') - Instantly loads the plugin during the boot process.
2. Doozer.plugin_after_orm('folder', 'init_file') - Delays loading the plugin until after the ORM is initialized.
3. Doozer.require_gem('gem_name', 'version') - Instantly loads the gem during the boot process.
4. Doozer.require_gem_after_orm('gem_name', 'version') - Delays loading the gem until after the ORM is initialized.

To queue a plugin or gem to be loaded, follow these examples.

  To load the following plugins:
    gems/plugins
                /plugin1
                        /init.rb
                /plugin2
                        /init.rb

    You would place the following method calls in this file:
      Doozer.plugin('plugin1', 'init')
      Doozer.plugin_after_orm('plugin2', 'init')

  To load the following gems, follow these examples:
    Doozer.require_gem('example', '= 0.1.0')
    Doozer.require_gem_after_orm('example', '>= 0.1.0')

"""