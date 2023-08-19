defmodule Sin.Repo do
  use Ecto.Repo,
    otp_app: :sin,
    adapter: Ecto.Adapters.Postgres
end
