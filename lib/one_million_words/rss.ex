defmodule OneMillionWords.RSS do
  alias OneMillionWords.HTTP
  @moduledoc "Fetches RSS"

  def get(url) do
    with {:ok, response} <- HTTP.get(url),
         {:ok, body} <- Map.fetch(response, :body),
         {:ok, parsed} <- FastRSS.parse(body),
         {:ok, items} <- Map.fetch(parsed, "items") do
      {:ok, Enum.map(items, &Map.get(&1, "link"))}
    end
  end
end
