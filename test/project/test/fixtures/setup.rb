Doozer::Configs.logger.info("==  Loading Fixtures ==========================================================")
@root = Dir.pwd
Dir.glob(File.join(@root,'/test/fixtures/*_fixture.rb')).each { | file |
  require file
}

