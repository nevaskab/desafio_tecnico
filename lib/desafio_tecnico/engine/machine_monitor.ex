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

  def flush do
    GenServer.call(__MODULE__, :flush, :infinity)
  end

  @impl true
  def init(_) do
    # tabela ETS de armazenamento rápido e concorrente
    :ets.new(@table, [:set, :public, :named_table, {:read_concurrency, true}])

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
        DesafioTecnico.PubSub,
        "telemetry:nodes",
        {:status_changed, node_id, new_status}
      )
    end

    :ets.insert(@table, {node_id, new_status, new_count, payload, timestamp})
    {:noreply, %{state | dirty_nodes: MapSet.put(state.dirty_nodes, node_id)}}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    {:reply, :ok, flush_dirty_nodes(state)}
  end

  @impl true
  def handle_info(:flush_to_sqlite, state) do
    {:noreply, flush_dirty_nodes(state)}
  end

  defp flush_dirty_nodes(state) do
    dirty_count = MapSet.size(state.dirty_nodes)

    if dirty_count > 0 do
      Logger.info("Sincronizando #{dirty_count} maquinas com SQLite...")

      Enum.each(state.dirty_nodes, fn id ->
        case :ets.lookup(@table, id) do
          [{^id, status, count, payload, last_seen_at}] ->
            attrs = %{
              status: status,
              total_events_processed: count,
              last_payload: payload,
              last_seen_at: last_seen_at
            }

            case Telemetry.upsert_machine_metric(id, attrs) do
              {:ok, _node_metric} ->
                :ok

              {:error, reason} ->
                Logger.error("Falha ao sincronizar #{inspect(id)} com SQLite: #{inspect(reason)}")
            end

          [] ->
            Logger.warning(
              "Ignorando flush de #{inspect(id)} porque o cache ETS nao tem mais dados."
            )
        end
      end)
    end

    %{state | dirty_nodes: MapSet.new()}
  end
end
