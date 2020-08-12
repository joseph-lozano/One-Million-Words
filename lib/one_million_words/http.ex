defmodule OneMillionWords.HTTP do
  require Logger

  def get(url) do
    Logger.info("GET: #{url}")
    HTTPoison.get(url, [], follow_redirect: true)
  end
end
