defmodule DesafioTecnicoWeb.PageController do
  use DesafioTecnicoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
