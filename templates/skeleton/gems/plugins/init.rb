"""
Gems are plugins. As long as they follow the gemspec you should be able to use them no problem.

To queue a plugin to be loaded during the boot process, follow these examples.

To load the following plugins:
  gems/plugins
              /plugin1
                      /init.rb
              /plugin2
                      /init.rb

You would place the following method calls in this file:
  
Doozer.plugin('plugin1', 'init')
Doozer.plugin('plugin2', 'init')
"""