defmodule DesafioTecnico.Repo do
  use Ecto.Repo,
    otp_app: :desafio_tecnico,
    adapter: Ecto.Adapters.Postgres
end
