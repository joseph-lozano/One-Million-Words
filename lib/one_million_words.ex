defmodule OneMillionWords do
  alias OneMillionWords.{HTML, RSS}

  def word_count(rss_url) do
    with {:ok, links} <- RSS.get(rss_url) do
      count =
        Enum.map(links, &HTML.word_count(&1))
        |> Enum.reduce(&(&1 + &2))

      {:ok, count}
    end
  end
end
