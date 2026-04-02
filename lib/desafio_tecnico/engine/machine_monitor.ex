defmodule DesafioTecnico.Engine.MachineMonitor do
  use GenServer
  alias DesafioTecnico.Telemetry
  require Logger

  @table :w_core_telemetry_cache
  @flush_interval :timer.seconds(5)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def ingest_event(node_id, payload) do
    GenServer.cast(__MODULE__, {:ingest, node_id, payload})
  end

  @impl true
  def init(_) do
    # tabela ETS de armazenamento rápido e concorrente
    :ets.new(@table, [:set, :public, :named_table])

    # agenda o flush periódico para o banco de dados
    :timer.send_interval(@flush_interval, :flush_to_sqlite)

    {:ok, %{dirty_nodes: MapSet.new()}}
  end

  @impl true
  def handle_cast({:ingest, node_id, payload}, state) do
    {current_count, last_status} =
      case :ets.lookup(@table, node_id) do
        [{^node_id, status, count, _, _}] -> {count, status}
        [] -> {0, "online"}
      end

    # grava o status da máquina no ETS e determina o status com base na temperatura
    new_status = if Map.get(payload, "temp", 0) > 80, do: "error", else: "online"
    new_count = current_count + 1
    timestamp = DateTime.utc_now()

    if new_status != last_status do
      Phoenix.PubSub.broadcast(
        Planta42.PubSub,
        "telemetry:nodes",
        {:status_changed, node_id, new_status}
      )
    end

    :ets.insert(@table, {node_id, new_status, new_count, payload, timestamp})
    {:noreply, %{state | dirty_nodes: MapSet.put(state.dirty_nodes, node_id)}}
  end

  @impl true
  def handle_info(:flush_to_db, state) do
    # Write-Behind: sincroniza os dados "sujos" do ETS para o banco de dados
    if MapSet.size(state.dirty_ids) > 0 do
      nodes_to_sync =
        Enum.map(state.dirty_ids, fn id ->
          [{_id, data}] = :ets.lookup(@table, id)
          data
        end)

      Logger.info("Sincronizando #{MapSet.size(state.dirty_ids)} máquinas com SQLite...")

      Enum.each(nodes_to_sync, fn node_data ->
        Telemetry.update_node_metric(node_data.status, node_data.last_seen, node_data.payload)
      end)
    end

    {:noreply, %{state | dirty_ids: MapSet.new()}}
  end
end
