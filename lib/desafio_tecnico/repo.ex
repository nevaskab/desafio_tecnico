defmodule DesafioTecnico.Repo do
  use Ecto.Repo,
    otp_app: :desafio_tecnico,
    adapter: Ecto.Adapters.SQLite3
end
