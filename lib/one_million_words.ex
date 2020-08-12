defmodule OneMillionWords do
  alias OneMillionWords.{HTML, RSS}

  def word_count(rss_url, from \\ nil) do
    with {:ok, links} <- RSS.get(rss_url) do
      count =
        Enum.map(links, &HTML.word_count(&1, from))
        |> Enum.reduce(0, fn {_url, count}, acc ->
          acc + count
        end)

      {:ok, count}
    end
  end
end
