Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:3000" # フロント側のポート番号を指定

    resource "*",
      headers: :any,
      expose: ["access-token", "expiry", "token-type", "uid", "client"],
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
