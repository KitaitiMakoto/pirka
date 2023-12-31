require "pathname"
require "yaml"
require "pirka/library"

module Pirka
  class Config
    FILE_NAME = "pirka.yaml"
    XDG_CONFIG_HOME = Pathname.new(".config")
    CONFIG_FILE= XDG_CONFIG_HOME/FILE_NAME
    XDG_CONFIG_DIRS = [Pathname.new("/etc/xdg")]
    CONFIG_DIRS = XDG_CONFIG_DIRS.collect {|dir| dir/FILE_NAME}

    @config_home = nil
    @additional_directories = []

    class << self
      attr_accessor :config_home, :additional_directories

      def directories(user = nil)
        config_dirs = ENV["XDG_CONFIG_DIRS"] ?
                        ENX["XDG_CONFIG_DIR"].split(":").collect {|dir| Pathname.new(dir)} :
                        CONFIG_DIRS
        config_home = ENV["XDG_CONFIG_HOME"] ?
                        Pathname.new(ENV["XDG_CONFIG_HOME"]) :
                        Pathname.new(Dir.home(user))/XDG_CONFIG_HOME
        ([@config_home, config_home] + @additional_directories + config_dirs).compact
      end

      def config_directory(user = nil)
        directories.first
      end

      def load_file(path)
        load_hash(
          YAML.load_file(path).each_with_object({}) {|(key, value), h|
            h[key] = case key
                     when "data_home"
                       Pathname(value)
                     when "additional_directories"
                       value.collect {|val| Pathname(val)}
                     when "library_repositories"
                       value.collect {|val| URI(val)}
                     else
                       value
                     end
          })
      end

      def load_hash(h)
        config = new
        %w[data_home additional_directories library_repositories].each do |attr|
          config.__send__("#{attr}=", h[attr]) if h[attr]
        end
        config
      end

      def filepath
        config_directory/FILE_NAME
      end
    end

    attr_accessor :data_home, :additional_directories, :library_repositories

    # @todo Consider login user
    def initialize
      @data_home = nil
      @additional_directories = []
      @library_repositories = []
    end

    # @todo Consider login user
    def path_from_repository(repository_uri)
      Library.data_directory/dirname_from_repository(repository_uri)
    end

    # @todo Consider URIs other than Git HTTPS URI
    def dirname_from_repository(repository_uri)
      repository_uri.host/repository_uri.path[1..-1].sub_ext("")
    end

    def config_directory(user = nil)
      self.class.config_directory(user)
    end

    def filepath
      self.class.filepath
    end

    def save(path = nil)
      path = Pathname(path || filepath)
      path.dirname.mkpath unless path.dirname.directory?
      path.write to_yaml
      path
    end

    def to_h
      h = {}
      h["data_home"] = @data_home.to_path if @data_home
      %w[additional_directories library_repositories].each do |key|
        value = __send__(key)
        h[key] = value.collect(&:to_s) unless value.empty?
      end
      h
    end

    def to_yaml
      to_h.to_yaml
    end
  end
end
