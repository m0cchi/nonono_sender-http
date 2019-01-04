require "nonono_sender/http/version"
require "nonono_sender"
require "sinatra/base"

module NononoSender
  module Http
    extend NononoSender

    EVENT_STACK = []

    class Error < StandardError; end
    class App < Sinatra::Base
      set :environment, :production
      set :bind, '0.0.0.0'
      helpers do
        def protected!
          unless authorized?
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n"])
          end
        end

        def authorized?
          @auth ||=  Rack::Auth::Basic::Request.new(request.env)
          @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV['NONONO_HTTP_USER'], ENV['NONONO_HTTP_PASSWORD']]
        end
      end

      post '/' do
        protected!
        text = params[:text]
        NononoSender::Http.send(text) if text
        ''
      end
    end

    def invalid?(env)
      ENV[env].nil? || ENV[env].empty?
    end

    def init
      raise Error if invalid?('NONONO_HTTP_PORT') || invalid?('NONONO_HTTP_USER') || invalid?('NONONO_HTTP_PASSWORD')
      EVENT_STACK.clear
    end

    def run
      App.run! port: ENV['NONONO_HTTP_PORT'].to_i
    end

    NononoSender::S << self
    extend self
  end
end
