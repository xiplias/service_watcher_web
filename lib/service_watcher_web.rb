class Service_watcher_web
  attr_reader :appserver, :args, :db, :ob
  
  def initialize(args)
    @args = args
    
    require "#{@args[:knjrbfw_path]}knjrbfw" if !Kernel.const_defined?(:Knj)
    require "#{@args[:hayabusa_path]}hayabusa" if !Kernel.const_defined?(:Hayabusa)
    require "#{@args[:service_watcher_path]}service_watcher"
    require "#{Service_watcher.path}/../include/client.rb"
    require "json"
    require "http2"
    
    if @args[:db]
      @db = @args[:db]
    elsif @args[:db_args]
      @db = Knj::Db.new(@args[:db_args])
    else
      raise "Could not figure out of database."
    end
    
    @ob = Knj::Objects.new(
      :class_path => "#{Service_watcher.path}/../models_client",
      :class_pre => "model_",
      :require_all => true,
      :custom => true,
      :db => @db,
      :module => Service_watcher::Client::Model
    )
    
    if args[:hayabusa]
      @appserver = args[:hayabusa]
    else
      appserver_args = {
        :port => @args[:port],
        :db_args => @args[:db_args],
        :doc_root => "#{File.dirname(__FILE__)}/../www",
        :locales_root => "#{File.dirname(__FILE__)}/../locales",
        :locales_gettext_funcs => true,
        :locale_default => "en_GB",
      }
      appserver_args[:knjrbfw_path] = @args[:knjrbfw_path] if @args.key?(:knjrbfw_path)
      appserver_args.merge!(@args[:hayabusa_args]) if @args.key?(:hayabusa_args)
      
      @appserver = Hayabusa.new(appserver_args)
    end
    
    @appserver.define_magic_var(:_site, self)
    @appserver.define_magic_var(:_ob, @ob)
    
    @appserver.define_magic_proc(:_sw) do |d|
      raise "Could not figure out the service-watcher-client-object." if !_session_hash[:sw]
      _session_hash[:sw]
    end
    
    @appserver.start if !args[:hayabusa]
  end
  
  def join
    @appserver.join
  end
  
  def stop
    @appserver.stop
  end
  
  def connect_client
    _session_hash[:sw] = Service_watcher::Client.new(
      :host => _session[:host],
      :port => _session[:port],
      :ssl => _session[:ssl]
    )
    res = _session_hash[:sw].login(:username => _session[:user], :password =>_session[:pass])
    
    raise _("You could not be logged in with that username and/or password.") if res["user_id"].to_i <= 0
  end
  
  def load_request
    if _session[:host] and !_session_hash[:sw]
      begin
        self.connect_client
      rescue Errno::ECONNREFUSED
        _session_hash.delete(:sw)
        _session.delete(:host)
        _session.delete(:port)
        _session.delete(:ssl)
      end
    elsif !_session_hash[:sw] and _get["s"] != "connect"
      @appserver.redirect("/?s=connect")
    end
  end
  
  def header(title)
    return "<h1>#{title}</h1>"
  end
  
  def boxt(title, width = "100%")
    if width.is_a?(Fixnum) or width.is_a?(Integer)
      width = "#{width}px"
    end
    
    html = "<div style=\"width: #{width};\">"
    html << "<div class=\"box\">"
    
    if title
      html << "<div class=\"box_title\">#{title}</div>"
    end
    
    return html
  end
  
  def boxb
    return "</div></div>"
  end
end