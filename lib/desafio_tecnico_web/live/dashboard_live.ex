defmodule DesafioTecnicoWeb.DashboardLive do
  use DesafioTecnicoWeb, :live_view

  @topic "telemetry:nodes"
  @table :w_core_telemetry_cache

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Planta42.PubSub, @topic)
    nodes =
      :ets.tab2list(@table)
      |> Enum.map(fn {id, status, count, _payload, _ts} ->
        %{id: id, status: status, count: count}
      end)

    {:ok, assign(socket, nodes: nodes)}
  end

  @impl true
  def handle_info({:status_changed, node_id, new_status}, socket) do
    updated_nodes = Enum.map(socket.assigns.nodes, fn node ->
      if node.id == node_id, do: %{node | status: new_status}, else: node
    end)
    {:noreply, assign(socket, nodes: updated_nodes)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h1 class="text-2xl font-bold mb-4">Dashboard Planta 42</h1>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">

        <div :for={node <- @nodes} class={[
          "p-4 border rounded-lg transition-all duration-500",
          node.status == "error" && "bg-red-100 border-red-500 animate-pulse",
          node.status == "online" && "bg-green-50 border-green-500"
        ]}>
          <div class="flex justify-between items-center">
            <span class="font-mono font-bold text-lg"><%= node.id %></span>

            <span class={[
              "px-2 py-1 rounded text-xs uppercase font-bold",
              node.status == "error" && "bg-red-500 text-white",
              node.status == "online" && "bg-green-500 text-white"
            ]}>
              <%= node.status %>
            </span>

          </div>
          <div class="mt-2 text-sm text-gray-600">
            Eventos processados: <span class="font-bold"><%= node.count %></span>
          </div>
        </div>

      </div>
    </div>
    """
  end
end
