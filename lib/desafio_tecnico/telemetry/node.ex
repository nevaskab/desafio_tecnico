defmodule DesafioTecnico.Telemetry.Node do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nodes" do
    field :machine_identifier, :string
    field :location, :string
    field :users_id, :id

    has_one :metric, DesafioTecnico.Telemetry.NodeMetric

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(node, attrs, users_scope) do
    node
    |> cast(attrs, [:machine_identifier, :location])
    |> validate_required([:machine_identifier, :location])
    |> unique_constraint(:machine_identifier)
    |> put_change(:users_id, users_scope.users.id)
  end
end
