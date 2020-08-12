defmodule OneMillionWordsWeb.PageLive do
  use OneMillionWordsWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, url: "", error: false, page_counts: [], count: nil, disabled: false)}
  end

  @impl true
  def handle_event("count_words", %{"url" => url}, socket) do
    pid = self()

    socket =
      socket
      |> assign(:disabled, true)
      |> assign(:page_counts, [])
      |> assign(:error, false)
      |> assign(:count, 0)

    Task.async(fn ->
      count_words(url, pid)
    end)

    {:noreply, socket}
  end

  # Happy Path
  @impl Phoenix.LiveView
  def handle_info({:page_count, {url, count}}, socket) do
    page_counts = [{url, count} | socket.assigns.page_counts]
    count = socket.assigns.count + count

    socket =
      socket
      |> assign(:page_counts, page_counts)
      |> assign(:count, count)

    {:noreply, socket}
  end


  def handle_info({_ref, x}, socket) when is_integer(x) do
    socket =
      socket
      |> assign(:disabled, false)
    {:noreply, socket}
  end

  # Sad path
  def handle_info({_ref, x}, socket) when not is_integer(x) do
    IO.inspect(x, label: "BBBBBBBBBB")

    socket =
      socket
      |> assign(:count, x)
      |> assign(:disabled, false)
      |> assign(:error, true)

    {:noreply, socket}
  end
  def handle_info({_ref, _count}, socket) do
    {:noreply, socket}
  end

  # Normal shutdown after task is done
  def handle_info({:DOWN, _ref, _, _, :normal}, socket) do
    {:noreply, socket}
  end

  defp count_words(url, from) do
    OneMillionWords.word_count(url, from) |> format_results()
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
