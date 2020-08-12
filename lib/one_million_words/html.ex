defmodule OneMillionWords.HTML do
  @moduledoc "Deals with HTTP calls and parsing HTML"
  alias OneMillionWords.HTTP
  require Logger

  @spec get(url :: String.t()) :: list()
  def get(url) do
    HTTP.get!(url)
    |> Map.get(:body)
    |> Floki.parse_document!()
    |> Floki.find("main")
  end

  @spec text(list) :: String.t()
  def text(contents) when is_list(contents) do
    Enum.reduce(contents, "", fn inner, acc ->
      case inner do
        {_tag, _, content} -> acc <> text(content)
        x -> acc <> " " <> x
      end
    end)
  end

  def text({_tag, _, contents}) when is_list(contents) do
    text(contents)
  end

  def word_count(url) do
    wc =
      get(url)
      |> text()
      |> String.split(~r/\s+/)
      |> Enum.count()

    Logger.debug("word count: #{url} -> #{wc}")
    wc
  end
end
