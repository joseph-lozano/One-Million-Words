defmodule OneMillionWordsWeb.PageLive do
  use OneMillionWordsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, url: "", count: nil, disabled: false)}
  end

  @impl true
  def handle_event("count_words", %{"url" => url}, socket) do
    IO.inspect(url, label: "count words")
    count = count_words(url)
    socket = assign(socket, :count, count)
    {:noreply, socket}
  end

  defp count_words(url) do
    OneMillionWords.word_count(url) |> format_results()
  end

  defp format_results({:ok, count}) do
    count
  end

  defp format_results({:error, reason}) do
    inspect(reason)
  end

  defp format_results(x) do
    IO.inspect x
  end
end
