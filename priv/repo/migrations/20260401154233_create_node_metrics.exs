defmodule DesafioTecnico.Repo.Migrations.CreateNodeMetrics do
  use Ecto.Migration

  def change do
    create table(:node_metrics) do
      add :status, :string, default: "off"
      add :total_events_processed, :integer, default: 0
      add :last_payload, :map, default: %{}
      add :last_seen_at, :utc_datetime
      add :node_id, references(:nodes, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:node_metrics, [:user_id])

    create index(:node_metrics, [:node_id])

    create unique_index(:node_metrics, [:node_id], name: :node_metrics_node_id_index)
  end
end
