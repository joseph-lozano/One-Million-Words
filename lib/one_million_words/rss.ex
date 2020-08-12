defmodule OneMillionWords.RSS do
  alias OneMillionWords.HTTP
  @moduledoc "Fetches RSS"

  def get(url) do
    HTTP.get!(url)
    |> Map.get(:body)
    |> FastRSS.parse()
    |> get_ok()
    |> Map.get("items")
    |> Enum.map(&Map.get(&1, "link"))
  end

  defp get_ok({:ok, rss}), do: rss
end
