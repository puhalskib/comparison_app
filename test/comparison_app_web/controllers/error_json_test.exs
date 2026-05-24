defmodule ComparisonAppWeb.ErrorJSONTest do
  use ComparisonAppWeb.ConnCase, async: true

  test "renders 404" do
    assert ComparisonAppWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert ComparisonAppWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
