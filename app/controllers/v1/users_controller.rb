module V1
  class UsersController < ApplicationController
    
    # Sign inしてないと以下のMethodは実行できない
    before_action :authenticate_v1_user!
    
    # 全件検索
    def index
      user = User.all
      if user
        render json: { user: user}, status: :ok
      else
        render user
      end
    end

  end
end
