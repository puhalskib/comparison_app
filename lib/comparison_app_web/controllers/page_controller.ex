defmodule ComparisonAppWeb.PageController do
  use ComparisonAppWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
