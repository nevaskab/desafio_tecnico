defmodule DesafioTecnico.Telemetry.NodeMetric do
  use Ecto.Schema
  import Ecto.Changeset

  schema "node_metrics" do
    field :status, :string, default: "off"
    field :total_events_processed, :integer, default: 0
    field :last_payload, :map, default: %{}
    field :last_seen_at, :utc_datetime
    field :user_id, :id

    # associação com o nó
    belongs_to :node, DesafioTecnico.Telemetry.Node

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(node_metric, attrs, user_scope) do
    node_metric
    |> cast(attrs, [:status, :total_events_processed, :last_payload, :last_seen_at])
    |> validate_required([:status, :total_events_processed, :last_seen_at])
    |> put_change(:user_id, user_scope.user.id)
  end
end
