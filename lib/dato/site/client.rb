# frozen_string_literal: true
require 'faraday'
require 'faraday_middleware'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'

require 'dato/version'

require 'dato/site/repo/field'
require 'dato/site/repo/item_type'
require 'dato/site/repo/menu_item'
require 'dato/site/repo/site'
require 'dato/site/repo/upload_request'
require 'dato/site/repo/user'
require 'dato/site/repo/item'
require 'dato/site/repo/role'
require 'dato/site/repo/access_token'
require 'dato/site/repo/upload'

require 'dato/upload/file'
require 'dato/upload/image'
require 'dato/api_error'

require 'cacert'

module Dato
  module Site
    class Client
      REPOS = {
        fields: Repo::Field,
        item_types: Repo::ItemType,
        menu_items: Repo::MenuItem,
        site: Repo::Site,
        upload_requests: Repo::UploadRequest,
        users: Repo::User,
        items: Repo::Item,
        roles: Repo::Role,
        access_tokens: Repo::AccessToken,
        uploads: Repo::Upload
      }.freeze

      attr_reader :token, :base_url, :schema, :extra_headers

      def initialize(token, options = {})
        @token = token
        @base_url = options[:base_url] || 'https://site-api.datocms.com'
        @extra_headers = options[:extra_headers] || {}
      end

      def upload_file(path_or_url)
        file = Upload::File.new(self, path_or_url)
        file.upload
      end

      def upload_image(path_or_url)
        file = Upload::Image.new(self, path_or_url)
        file.upload
      end

      REPOS.each do |method_name, repo_klass|
        define_method method_name do
          instance_variable_set(
            "@#{method_name}",
            instance_variable_get("@#{method_name}") ||
            repo_klass.new(self)
          )
        end
      end

      def request(*args)
        connection.send(*args).body.with_indifferent_access
      rescue Faraday::SSLError => e
        raise e if ENV['SSL_CERT_FILE'] == Cacert.pem

        Cacert.set_in_env
        request(*args)
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
        puts e.message
        raise e
      rescue Faraday::ClientError => e
        error = ApiError.new(e)
        puts '===='
        puts error.message
        puts '===='
        raise error
      end

      private

      def connection
        options = {
          url: base_url,
          headers: extra_headers.merge(
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@token}",
            'User-Agent' => "ruby-client v#{Dato::VERSION}"
          )
        }

        @connection ||= Faraday.new(options) do |c|
          c.request :json
          c.response :json, content_type: /\bjson$/
          c.response :raise_error
          c.use FaradayMiddleware::FollowRedirects
          c.adapter :net_http
        end
      end
    end
  end
end
