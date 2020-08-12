defmodule OneMillionWords do
  alias OneMillionWords.{HTML, RSS}

  def word_count(rss_url) do
    rss_url
    |> RSS.get()
    |> Enum.map(&HTML.word_count(&1))
    |> Enum.reduce(&(&1 + &2))
  end
end
