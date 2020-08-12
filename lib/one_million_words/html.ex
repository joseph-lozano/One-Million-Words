defmodule OneMillionWords.HTML do
  @moduledoc "Deals with HTTP calls and parsing HTML"
  alias OneMillionWords.HTTP
  require Logger

  @spec get(url :: String.t()) :: list()
  def get(url) do
    with {:ok, response} <- HTTP.get(url),
         {:ok, body} <- Map.fetch(response, :body),
         {:ok, parsed} <- Floki.parse_document(body) do
      Floki.find(parsed, "main")
    end
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

  def word_count(url, from) do
    wc =
      get(url)
      |> text()
      |> String.split(~r/\s+/)
      |> Enum.count()

    Logger.debug("word count: #{url} -> #{wc}")

    maybe_send({url, wc}, from)
  end

  defp maybe_send(result, nil) do
    result
  end

  defp maybe_send(result, pid) when is_pid(pid) do
    IO.puts("SENDING")
    send(pid, {:page_count, result})
    result
  end
end
