defmodule DesafioTecnico.Telemetry.Node do
  use Ecto.Schema
  import Ecto.Changeset

  schema "nodes" do
    field :machine_identifier, :string
    field :location, :string
    field :user_id, :id

    # associação com as métricas do nó
    has_one :node_metric, DesafioTecnico.Telemetry.NodeMetric

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(node, attrs, user_scope) do
    node
    |> cast(attrs, [:machine_identifier, :location])
    |> validate_required([:machine_identifier, :location])
    |> unique_constraint(:machine_identifier)
    |> put_change(:user_id, user_scope.user.id)
  end
end
