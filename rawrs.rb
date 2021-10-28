# RAWRS - RISC-V Assembler and Workable, Rewritable System
# Copyright (C) 2017-2019 wilkie
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'bundler'
Bundler.require

require_relative './lib/rouge/lexers/riscv.rb'

require 'rouge/plugins/redcarpet'

require 'base64'
require 'yaml'

class HTML < Redcarpet::Render::HTML
    include Rouge::Plugins::Redcarpet # yep, that's it. (Thanks Jeanine!!)

    def codespan(code)
      classes = ""
      if code.start_with?("{.")
        # Add class
        klass = code[2...code.index('}')]
        code = code[3 + klass.length..-1]
        classes = " class=\"#{klass}\""
      end

      "<code#{classes}>#{code}</code>"
    end
end

class RAWRS < Sinatra::Base
  # Use HTML5
  set :haml, :format => :html5

  # Use root directory as root
  set :app_file => '.'

  # Static Asset Management
  set :public_folder, "assets"
  set :static_cache_control, [:public, max_age: 60 * 60 * 24 * 365]

  # Markdown
  Tilt.register Tilt::RedcarpetTemplate, 'md'
  Tilt.prefer   Tilt::RedcarpetTemplate
  set :markdown, :renderer => HTML,
                 :layout_engine => :slim,
                 :layout => :"guidance/layout",
                 :tables => true,
                 :fenced_code_blocks => true

  # I18n
  I18n.load_path += Dir[File.join(File.dirname(__FILE__), 'locales', '**', '*.yml')]
  I18n.load_path += Dir[File.join(Gem::Specification.find_by_name('rails-i18n').gem_dir, 'rails', 'locale', '*.yml')]

  # Ensure wasm is seen with the correct mime type
  Rack::Mime::MIME_TYPES[".wasm"] = "application/wasm"

  # Helpers
  helpers do
    def partial(page, options={}, &block)
      if page.to_s.include? "/"
        page = page.to_s.sub(/[\/]([^\/]+)$/, "/_\\1")
      else
        page = "_#{page}"
      end

      render(:slim, page.to_sym, options.merge!(:layout => false), &block)
    end

    def no_cache
      headers "Expires"       => "Fri, 01 Jan 1980 00:00:00 GMT",
              "Pragma"        => "no-cache",
              "Cache-Control" => "no-cache, max-age=0, must-revalidate"
    end

    def forever_cache
      now = Time.now
      headers "Date" => now.to_s,
              "Expires" => (now + 31536000).httpdate,
              "Cache-Control" => "public, max-age=31536000"
    end

    # Renders the given markdown guidance page with or without the layout.
    def render_guidance(page, layout = true)
      # Get interpolated strings
      if !defined?(@@binutils_authors)
        begin
          @@binutils_authors = JSON.parse(`ruby scripts/parse_binutils_authors.rb`).join(", ")
        rescue
          @@binutils_authors = "various"
        end
      end

      lang = :en

      page = page.to_s

      if page.start_with?("/")
        page = page[1..-1]
      end

      filename = :"guidance/#{lang.to_s}/#{page}"
      if not File.exist?("views/#{filename}.md")
        # default to the english docs if we cannot find the requested language
        filename = :"guidance/en/#{page}"
      end

      if layout.nil?
        ret = render(:slim, :index, :locals => {
          :tab => :guidance,
          :guidance => page
        })
      else
        data = File.read("views/#{filename}.md")
        data.gsub!("{% binutils_authors %}", @@binutils_authors)
        ret = render(:markdown, data, :layout => layout)
        ret.gsub!(" href=\"http", " target=\"_blank\" href=\"http")
      end
      ret.gsub!("<p><img", "<p class=\"image\"><img")
      ret
    end
  end

  # Routes

  # index page
  get '/' do
    @basepath = ""
    render(:slim, :index)
  end

  # edit page
  get '/edit' do
    @basepath = ""
    render(:slim, :index, :locals => {
      :tab => :edit
    })
  end

  # run page
  get '/run' do
    @basepath = ""
    render(:slim, :index, :locals => {
      :tab => :run
    })
  end

  # guidance page index
  get '/guidance/:page' do
    @basepath = "../"
    if params[:page].end_with?('_ajax')
      params[:page] = params[:page][0...-5]
      if params[:page] == "instructions"
        ret = render(:slim, :"guidance/_instructions", :layout => :"guidance/layout")
        ret.gsub!("<p><img", "<p class=\"image\"><img")
        ret
      else
        render_guidance(params[:page])
      end
    else
      render_guidance(params[:page], nil)
    end
  end

  # stylesheets
  get '/css/highlight.css' do
    content_type 'text/css', :charset => 'utf-8'
    Rouge::Themes::Base16.mode(:dark).render(scope: '.highlight')
  end

  get '/css/:filename.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss "css/#{params[:filename]}".intern
  end

  # kernel source
  get '/kernel/:file.s' do
    send_file "kernel/#{params[:file]}.s"
  end

  # Allow dynamic colors for any arbitrary svg files
  # TODO: shouldn't assume <?xml ... ?> is the first line
  def recolor_svg()
    content_type "image/svg+xml"
    forever_cache

    params["name"] = params["splat"].join

    if not File.exist?("assets/images/#{params[:name]}.svg")
      status 404
      return
    end

    if params["hex"]
      params["color"] = "##{params["hex"]}"
    elsif params["hue"] and params["sat"] and params["light"]
      params["color"] = "hsl(#{params["hue"]}, #{params["sat"]}%, #{params["light"]}%)"
    end

    if params["color"]
      require 'base64'

      headers 'Content-Type' => "image/svg+xml"
      css = "path, rect, circle { fill: #{params["color"]} !important; stroke: transparent !important }"
      embed = Base64.encode64(css)

      stream do |out|
        # We need to write out the <svg> tab and then the stylesheet
        File.open("assets/images/#{params[:name]}.svg") do |f|
          stylesheet_line = "<?xml-stylesheet type=\"text/css\" href=\"data:text/css;charset=utf-8;base64,#{embed.strip}\" ?>"
          line = f.readline
          if line.include?("<?xml")
            parts = line.split("?>", 2)
            out << parts[0]
            out << "?>"
            out << stylesheet_line
            out << parts[1]
          else
            out << stylesheet_line
            out << line
          end
          out << f.read
        end
      end
    else
      send_file "assets/images/#{params[:name]}.svg"
    end
  rescue
    status 404
  end

  get "/images/dynamic/hue/:hue/sat/:sat/light/:light/*.svg" do
    recolor_svg()
  end

  get "/images/dynamic/hex/:hex/*.svg" do
    recolor_svg()
  end

  get "/images/dynamic/color/:color/*.svg" do
    recolor_svg()
  end
end
