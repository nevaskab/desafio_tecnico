defmodule DesafioTecnico.Telemetry.NodeMetric do
  use Ecto.Schema
  import Ecto.Changeset

  schema "node_metrics" do
    field :status, :string
    field :total_events_processed, :integer
    field :last_payload, :map
    field :last_seen_at, :utc_datetime

    belongs_to :node, DesafioTecnico.Telemetry.Node

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(node_metric, attrs, users_scope) do
    node_metric
    |> cast(attrs, [:status, :total_events_processed, :last_payload, :last_seen_at])
    |> validate_required([:status, :total_events_processed, :last_seen_at])
    |> put_change(:users_id, users_scope.users.id)
  end
end
