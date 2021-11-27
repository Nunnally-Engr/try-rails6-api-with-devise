# Rails 6.0 + Docker + MySQL5x + devise-token-auth での環境構築

## 各種バージョン

- Ruby 2.7
- Rails 6.0.0
- mysql 5.7.21

---

## 前提条件

- Dockerを使える環境が整っていること

---

## できること

- Rails 6.0 + Docker + MySQL5x + devise-token-auth での環境構築
- devise-token-authを使った、サインアップ、サインイン、サインアウトができる
- ユーザがサインインしていることを確認し、サインインしていたらuser情報を取得する

## できないこと（やらないこと）

- コピペで環境構築できるように作った記事なので、各項目の詳しい説明は割愛

---

## 環境構築手順

### 1. [try-rails6-api](https://github.com/Nunnally-Engr/) のテンプレートを使用し、リポジトリを作成する

- リポジトリ名は `try-rails6-api-with-devise` とする
- 必要に応じて、 `try-rails6-api` と記載している箇所を自分で作成したリポジトリ名に変更する(当記事であれば `try-rails6-api-with-devise` に変更)

### 2. try-rails6-apiの[README.md](https://github.com/Nunnally-Engr/try-rails6-api#readme) に沿って環境構築する

### 3. 必要なGemを追加する

#### Gemfile

```Gemfile:Gemfile
・
・
・

# 認証
gem "devise"
gem "devise_token_auth"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# ※ 疎通確認をPostmanでする場合、必要となる場合があるので追加しておく
gem 'rack-cors' 
```

### 4. ビルド＆追加したGemをインストールする

```sh
docker-compose build --no-cache
```

```sh
docker-compose run back bundle exec rails g devise:install
```

```sh
docker-compose run back bundle exec rails g devise_token_auth:install User auth
```

### 5. `devise_token_auth` の設定

#### config/initializers/devise_token_auth.rb

```Ruby:config/initializers/devise_token_auth.rb
# frozen_string_literal: true

DeviseTokenAuth.setup do |config|
  # By default the authorization headers will change after each request. The
  # client is responsible for keeping track of the changing tokens. Change
  # this to false to prevent the Authorization header from changing after
  # each request.
  config.change_headers_on_each_request = false

  # By default, users will need to re-authenticate after 2 weeks. This setting
  # determines how long tokens will remain valid after they are issued.
  # config.token_lifespan = 2.weeks

  # Limiting the token_cost to just 4 in testing will increase the performance of
  # your test suite dramatically. The possible cost value is within range from 4
  # to 31. It is recommended to not use a value more than 10 in other environments.
  config.token_cost = Rails.env.test? ? 4 : 10

  # Sets the max number of concurrent devices per user, which is 10 by default.
  # After this limit is reached, the oldest tokens will be removed.
  # config.max_number_of_devices = 10

  # Sometimes it's necessary to make several requests to the API at the same
  # time. In this case, each request in the batch will need to share the same
  # auth token. This setting determines how far apart the requests can be while
  # still using the same auth token.
  # config.batch_request_buffer_throttle = 5.seconds

  # This route will be the prefix for all oauth2 redirect callbacks. For
  # example, using the default '/omniauth', the github oauth2 provider will
  # redirect successful authentications to '/omniauth/github/callback'
  # config.omniauth_prefix = "/omniauth"

  # By default sending current password is not needed for the password update.
  # Uncomment to enforce current_password param to be checked before all
  # attribute updates. Set it to :password if you want it to be checked only if
  # password is updated.
  # config.check_current_password_before_update = :attributes

  # By default we will use callbacks for single omniauth.
  # It depends on fields like email, provider and uid.
  # config.default_callbacks = true

  # Makes it possible to change the headers names
  config.headers_names = {:'access-token' => 'access-token',
                         :'client' => 'client',
                         :'expiry' => 'expiry',
                         :'uid' => 'uid',
                         :'token-type' => 'token-type' }

  # By default, only Bearer Token authentication is implemented out of the box.
  # If, however, you wish to integrate with legacy Devise authentication, you can
  # do so by enabling this flag. NOTE: This feature is highly experimental!
  # config.enable_standard_devise_support = false

  # By default DeviseTokenAuth will not send confirmation email, even when including
  # devise confirmable module. If you want to use devise confirmable module and
  # send email, set it to true. (This is a setting for compatibility)
  # config.send_confirmation_email = true
end
```

### 6. `rack-cors` の設定

#### rack-cors がインストールされていることを確認する

```sh
docker-compose run --rm back bundle info rack-cors
```

#### 設定ファイル作成

```sh
touch config/initializers/core.rb
```

#### config/initializers/core.rb

```Ruby:config/initializers/core.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:3000" # フロント側のポート番号を指定

    resource "*",
      headers: :any,
      expose: ["access-token", "expiry", "token-type", "uid", "client"],
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```

### 7. Modelの設定

#### app/models/user.rb

```Ruby:app/models/user.rb
# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :rememberable, :validatable
  include DeviseTokenAuth::Concerns::User
end
```

### 8. Controllerの設定

#### (01) Registrations Controller

##### コントローラ作成

```sh
docker-compose run back rails g controller v1/registrations --no-assets --no-helper
```

##### app/controllers/v1/registrations_controller.rb

```Ruby:app/controllers/v1/registrations_controller.rb
module V1
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    private
      def sign_up_params
        params.permit(:email, :password, :password_confirmation, :name)
      end
  end
end
```

#### (02) Users Controller

##### コントローラ作成

```sh
docker-compose run back rails g controller v1/users --no-assets --no-helper
```

##### app/controllers/v1/users_controller.rb

```Ruby:app/controllers/v1/users_controller.rb
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
```
#### (03) Application Controller

##### app/controllers/application_controller.rb

```Ruby:app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  before_action :configure_permitted_parameters, if: :devise_controller?
    
  def render_404
    render status: 404, json: { message: "record not found." }
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end
end
```

### 9. Routingの設定

#### config/routes.rb

```Ruby:config/routes.rb
Rails.application.routes.draw do
  mount_devise_token_auth_for 'User', at: 'auth'
  namespace :v1, defaults: { format: :json } do
    get :healthcheck, to: 'sessions#healthcheck'
    mount_devise_token_auth_for 'User', at: 'auth', controllers: {
      registrations: 'v1/registrations',
      sessions: "devise_token_auth/sessions"
    }
    resources :users
  end
end
```

### 10. マイグレーション実行

```sh
docker-compose run --rm back  bundle exec rake db:migrate
```

---

## 疎通確認

### 1. コンテナ起動

```sh
docker-compose up
```

### 2. サインアップ ※ Postmanを使用

#### URL

[POST] http://localhost:4000/v1/auth

#### Body: raw(JSON)

```json
{"email": "sample@test.com", "password": "xxxxxxxx", "name": "サンプル 太郎"}
```

### 3. サインイン ※ Postmanを使用

#### URL

[POST] http://localhost:4000/v1/auth/sign_in

#### Body: raw(JSON)

```json
{"email": "sample@test.com", "password": "xxxxxxxx"}
```

### 4. サインアウト ※ Postmanを使用

#### URL

[DELETE] http://localhost:4000/v1/auth/sign_out

#### Headers

- サインインで取得した、以下の項目を設定する
  - access-token
  - uid
  - client
  - expiry
  - content-type
  - token-type

### 5. ユーザ情報取得(サインインしていないと取得できない) ※ Postmanを使用

#### URL

[GET] http://localhost:4000/v1/users

#### Headers

- サインインで取得した、以下の項目を設定する
  - access-token
  - uid
  - client
  - expiry
  - content-type
  - token-type
