defmodule ComparisonApp.Repo do
  use Ecto.Repo,
    otp_app: :comparison_app,
    adapter: Ecto.Adapters.Postgres
end
