require 'test_helper'

class RoutingTest < RoutingHelper
  context "A route instance" do
    should "pass" do
    
      # test default route
      route = Doozer::Routing::Routes::match('/')
      assert_equal(route.name, :index)
      assert_equal(route.format, :html)
      assert_equal(route.status, 200) #test default status=200

      # test index_with_token
      path='/hello_world.how_are_yo;u,-Imnot%sure~'
      route = Doozer::Routing::Routes::match(path)
      assert_equal(route.name, :index_with_token)
      
        # test token parsing
        args = route.extra_params(path)
        assert_equal('hello_world.how_are_yo;u,-Imnot%sure~', args[:token])
      
      # test format
        path='/format_test/5/hello.xml'
        route = Doozer::Routing::Routes::match(path)
        assert_equal(route.name, :format_test_xml)
        assert_equal(route.format, :xml)

          # test token parsing
          args = route.extra_params(path)
          assert_equal('5', args[:id])
          assert_equal('hello', args[:name])

        path='/format_test/5/hello.json'
        route = Doozer::Routing::Routes::match(path)
        assert_equal(route.name, :format_test_json)
        assert_equal(route.format, :json)

        path='/recent.rss'
        route = Doozer::Routing::Routes::match(path)
        assert_equal(route.name, :recent_rss)
        assert_equal(route.format, :rss)
        
      # test for allowable route tokens
        # right now these are: [a-zA-Z0-9\,\-\.\%\_]*

    end
    
    should "raise an error if we try adding these routes" do
      # add route with a duplicate name
      assert_raise Doozer::Exceptions::Route do
        Doozer::Routing::Routes.add(:index, '/some_path', {:controller=>'index', :action=>'index', :status=>200})
      end
      
      # add route with a name of type string
      assert_raise Doozer::Exceptions::Route do
        Doozer::Routing::Routes.add('index', '/', {:controller=>'index', :action=>'index', :status=>200})
      end

      # add route with a duplicate path
      assert_raise Doozer::Exceptions::Route do
        Doozer::Routing::Routes.add(:duplicate_path_fail, '/', {:controller=>'index', :action=>'index', :status=>200})
      end
    end
    
  end
end
