# frozen_string_literal: true
require 'dato/site/repo/base'

module Dato
  module Site
    module Repo
      class User < Base
        def create(resource_attributes)
          body = JsonApiSerializer.new(
            type: :user,
            attributes: %i(email first_name last_name),
            relationships: { role: { collection: false, type: :role } },
            required_attributes: %i(email first_name last_name),
            required_relationships: %i(role)
          ).serialize(resource_attributes)

          post_request '/users', body
        end

        def all
          get_request '/users'
        end

        def find(user_id)
          get_request "/users/#{user_id}"
        end

        def reset_password(resource_attributes)
          body = JsonApiSerializer.new(
            type: :user,
            attributes: %i(email),
            required_attributes: %i(email)
          ).serialize(resource_attributes)

          post_request '/users/reset_password', body
        end

        def destroy(user_id)
          delete_request "/users/#{user_id}"
        end
      end
    end
  end
end
