defmodule OneMillionWordsWeb.PageLive do
  use OneMillionWordsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, url: "", count: nil, disabled: false)}
  end

  @impl true
  def handle_event("count_words", %{"url" => url}, socket) do
    pid = self()

    Task.async(fn ->
      count_words(url)
    end)

    {:noreply, assign(socket, :disabled, true)}
  end

  # Happy Path
  def handle_info({_ref, {:total_count, count}}, socket) do
    socket
    |> assign(:count, count)
    |> assign(:disabled, false)

    {:noreply, socket}
  end

  # Sad path
  def handle_info({_ref, x}, socket) do
    socket = socket
    |> assign(:count, x)
    |> assign(:disabled, false)

    {:noreply, socket}
  end

  # Normal shutdown after task is done
  def handle_info({:DOWN, _ref, _, _, :normal}, socket) do
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
    IO.inspect(x)
  end
end
