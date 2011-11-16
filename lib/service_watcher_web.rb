class Service_watcher_web
  attr_reader :appserver, :args, :db, :ob
  
  def initialize(args)
    @args = args
    
    require "#{@args[:knjrbfw_path]}knjrbfw"
    require "#{@args[:knjdbrevision_path]}knjdbrevision"
    require "#{@args[:knjappserver_path]}knjappserver"
    require "#{@args[:service_watcher_path]}service_watcher"
    require "#{Service_watcher.path}/../include/client.rb"
    
    require "knj/knjdb/libknjdb"
    @db = Knj::Db.new(@args[:db_args])
    
    require "knj/objects"
    @ob = Knj::Objects.new(
      :class_path => "#{Service_watcher.path}/../models_client",
      :class_pre => "model_",
      :require_all => true,
      :custom => true,
      :db => @db,
      :module => Service_watcher::Client::Model
    )
    
    appserver_args = {
      :port => @args[:port],
      :db_args => @args[:db_args],
      :doc_root => "#{File.dirname(__FILE__)}/../www",
      :locales_root => "#{File.dirname(__FILE__)}/../locales",
      :locales_gettext_funcs => true,
      :locale_default => "en_GB",
    }
    appserver_args[:knjrbfw_path] = @args[:knjrbfw_path] if @args.key?(:knjrbfw_path)
    appserver_args[:knjdbrevision_path] = @args[:knjdbrevision_path] if @args.key?(:knjdbrevision_path)
    appserver_args.merge!(@args[:knjappserver_args]) if @args.key?(:knjappserver_args)
    
    @appserver = Knjappserver.new(appserver_args)
    @appserver.define_magic_var(:_site, self)
    @appserver.define_magic_var(:_ob, @ob)
    
    @appserver.define_magic_proc(:_sw) do |d|
      raise "Could not figure out the service-watcher-client-object." if !_session_hash[:sw]
      _session_hash[:sw]
    end
    
    @appserver.start
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
  end
  
  def load_request
    if _session[:host] and !_session_hash[:sw]
      self.connect_client
    end
  end
  
  def header(title)
    return "<h1>#{title}</h1>"
  end
  
  def boxt(title, width = "100%")
    if width.is_a?(Fixnum) or width.is_a?(Integer)
      width = "#{width}px"
    end
    
    html = ""
    html += "<div class=\"box\" style=\"width: #{width};\">"
    
    if title
      html += "<div class=\"box_title\">#{title}</div>"
    end
    
    return html
  end
  
  def boxb
    return "</div>"
  end
end