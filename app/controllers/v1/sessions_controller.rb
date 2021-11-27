module V1
  class SessionsController < ApplicationController
    def healthcheck
      render json: { status: :success }
    end
  end
end
