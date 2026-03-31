defmodule DesafioTecnico.Telemetry do
  @moduledoc """
  The Telemetry context.
  """

  import Ecto.Query, warn: false
  alias DesafioTecnico.Repo

  alias DesafioTecnico.Telemetry.Node
  alias DesafioTecnico.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any node changes.

  The broadcasted messages match the pattern:

    * {:created, %Node{}}
    * {:updated, %Node{}}
    * {:deleted, %Node{}}

  """
  def subscribe_nodes(%Scope{} = scope) do
    key = scope.users.id

    Phoenix.PubSub.subscribe(DesafioTecnico.PubSub, "users:#{key}:nodes")
  end

  defp broadcast_node(%Scope{} = scope, message) do
    key = scope.users.id

    Phoenix.PubSub.broadcast(DesafioTecnico.PubSub, "users:#{key}:nodes", message)
  end

  @doc """
  Returns the list of nodes.

  ## Examples

      iex> list_nodes(scope)
      [%Node{}, ...]

  """
  def list_nodes(%Scope{} = scope) do
    Repo.all_by(Node, users_id: scope.users.id)
  end

  @doc """
  Gets a single node.

  Raises `Ecto.NoResultsError` if the Node does not exist.

  ## Examples

      iex> get_node!(scope, 123)
      %Node{}

      iex> get_node!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_node!(%Scope{} = scope, id) do
    Repo.get_by!(Node, id: id, users_id: scope.users.id)
  end

  @doc """
  Creates a node.

  ## Examples

      iex> create_node(scope, %{field: value})
      {:ok, %Node{}}

      iex> create_node(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_node(%Scope{} = scope, attrs) do
    with {:ok, node = %Node{}} <-
           %Node{}
           |> Node.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_node(scope, {:created, node})
      {:ok, node}
    end
  end

  @doc """
  Updates a node.

  ## Examples

      iex> update_node(scope, node, %{field: new_value})
      {:ok, %Node{}}

      iex> update_node(scope, node, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_node(%Scope{} = scope, %Node{} = node, attrs) do
    true = node.users_id == scope.users.id

    with {:ok, node = %Node{}} <-
           node
           |> Node.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_node(scope, {:updated, node})
      {:ok, node}
    end
  end

  @doc """
  Deletes a node.

  ## Examples

      iex> delete_node(scope, node)
      {:ok, %Node{}}

      iex> delete_node(scope, node)
      {:error, %Ecto.Changeset{}}

  """
  def delete_node(%Scope{} = scope, %Node{} = node) do
    true = node.users_id == scope.users.id

    with {:ok, node = %Node{}} <-
           Repo.delete(node) do
      broadcast_node(scope, {:deleted, node})
      {:ok, node}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking node changes.

  ## Examples

      iex> change_node(scope, node)
      %Ecto.Changeset{data: %Node{}}

  """
  def change_node(%Scope{} = scope, %Node{} = node, attrs \\ %{}) do
    true = node.users_id == scope.users.id

    Node.changeset(node, attrs, scope)
  end

  alias DesafioTecnico.Telemetry.NodeMetric
  alias DesafioTecnico.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any node_metric changes.

  The broadcasted messages match the pattern:

    * {:created, %NodeMetric{}}
    * {:updated, %NodeMetric{}}
    * {:deleted, %NodeMetric{}}

  """
  def subscribe_node_metrics(%Scope{} = scope) do
    key = scope.users.id

    Phoenix.PubSub.subscribe(DesafioTecnico.PubSub, "users:#{key}:node_metrics")
  end

  defp broadcast_node_metric(%Scope{} = scope, message) do
    key = scope.users.id

    Phoenix.PubSub.broadcast(DesafioTecnico.PubSub, "users:#{key}:node_metrics", message)
  end

  @doc """
  Returns the list of node_metrics.

  ## Examples

      iex> list_node_metrics(scope)
      [%NodeMetric{}, ...]

  """
  def list_node_metrics(%Scope{} = scope) do
    Repo.all_by(NodeMetric, users_id: scope.users.id)
  end

  @doc """
  Gets a single node_metric.

  Raises `Ecto.NoResultsError` if the Node metric does not exist.

  ## Examples

      iex> get_node_metric!(scope, 123)
      %NodeMetric{}

      iex> get_node_metric!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_node_metric!(%Scope{} = scope, id) do
    Repo.get_by!(NodeMetric, id: id, users_id: scope.users.id)
  end

  @doc """
  Creates a node_metric.

  ## Examples

      iex> create_node_metric(scope, %{field: value})
      {:ok, %NodeMetric{}}

      iex> create_node_metric(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_node_metric(%Scope{} = scope, attrs) do
    with {:ok, node_metric = %NodeMetric{}} <-
           %NodeMetric{}
           |> NodeMetric.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_node_metric(scope, {:created, node_metric})
      {:ok, node_metric}
    end
  end

  @doc """
  Updates a node_metric.

  ## Examples

      iex> update_node_metric(scope, node_metric, %{field: new_value})
      {:ok, %NodeMetric{}}

      iex> update_node_metric(scope, node_metric, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_node_metric(%Scope{} = scope, %NodeMetric{} = node_metric, attrs) do
    with {:ok, node_metric = %NodeMetric{}} <-
           node_metric
           |> NodeMetric.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_node_metric(scope, {:updated, node_metric})
      {:ok, node_metric}
    end
  end

  @doc """
  Deletes a node_metric.

  ## Examples

      iex> delete_node_metric(scope, node_metric)
      {:ok, %NodeMetric{}}

      iex> delete_node_metric(scope, node_metric)
      {:error, %Ecto.Changeset{}}

  """
  def delete_node_metric(%Scope{} = scope, %NodeMetric{} = node_metric) do

    with {:ok, node_metric = %NodeMetric{}} <-
           Repo.delete(node_metric) do
      broadcast_node_metric(scope, {:deleted, node_metric})
      {:ok, node_metric}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking node_metric changes.

  ## Examples

      iex> change_node_metric(scope, node_metric)
      %Ecto.Changeset{data: %NodeMetric{}}

  """
  def change_node_metric(%Scope{} = scope, %NodeMetric{} = node_metric, attrs \\ %{}) do
    NodeMetric.changeset(node_metric, attrs, scope)
  end
end
