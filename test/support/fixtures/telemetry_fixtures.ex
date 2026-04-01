defmodule DesafioTecnico.TelemetryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DesafioTecnico.Telemetry` context.
  """

  @doc """
  Generate a unique node machine_identifier.
  """
  def unique_node_machine_identifier, do: "some machine_identifier#{System.unique_integer([:positive])}"

  @doc """
  Generate a node.
  """
  def node_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        location: "some location",
        machine_identifier: unique_node_machine_identifier()
      })

    {:ok, node} = DesafioTecnico.Telemetry.create_node(scope, attrs)
    node
  end

  @doc """
  Generate a node_metric.
  """
  def node_metric_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        last_payload: %{},
        last_seen_at: ~U[2026-03-31 14:57:00Z],
        status: "some status",
        total_events_processed: 42
      })

    {:ok, node_metric} = DesafioTecnico.Telemetry.create_node_metric(scope, attrs)
    node_metric
  end
end
