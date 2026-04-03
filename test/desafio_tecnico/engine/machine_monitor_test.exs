defmodule DesafioTecnico.Engine.MachineMonitorTest do
  use DesafioTecnico.DataCase, async: false

  alias DesafioTecnico.Engine.MachineMonitor
  alias DesafioTecnico.Repo
  alias DesafioTecnico.Telemetry.Node
  alias DesafioTecnico.Telemetry.NodeMetric

  @table :w_core_telemetry_cache

  setup do
    if :ets.whereis(@table) != :undefined do
      :ets.delete_all_objects(@table)
    end

    :ok
  end

  @tag timeout: :infinity
  test "Prova de resiliência: 10.000 eventos concorrentes sem perda de dados" do
    machine_id = "Teste-1"
    total_events = 10000

    Repo.insert!(%Node{machine_identifier: machine_id})

    1..total_events
    |> Enum.map(fn _ ->
      Task.async(fn ->
        temp = Enum.random(40..100)
        MachineMonitor.ingest_event(machine_id, %{"temp" => temp})
      end)
    end)
    |> Task.await_many(:infinity)

    assert :ok = MachineMonitor.flush()

    [{^machine_id, status, count, _payload, _timestamp}] = :ets.lookup(@table, machine_id)
    assert count == total_events

    IO.puts(
      "\nStatus final da máquina #{machine_id}: #{status} com #{count} eventos processados."
    )

    db_node = Repo.get_by!(Node, machine_identifier: machine_id)
    db_metrics = Repo.get_by!(NodeMetric, node_id: db_node.id)

    assert db_metrics.total_events_processed == total_events
    assert db_metrics.status == status
    assert is_integer(db_metrics.last_payload["temp"])
    assert %DateTime{} = db_metrics.last_seen_at

    IO.puts(
      "Dados confirmados no banco de dados para #{machine_id}: #{db_metrics.total_events_processed} eventos e status '#{db_metrics.status}'."
    )
  end
end
