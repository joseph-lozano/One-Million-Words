# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :one_million_words,
  ecto_repos: [OneMillionWords.Repo]

# Configures the endpoint
config :one_million_words, OneMillionWordsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Kp7MVvLpdb0p3JOA9Uvthpk6DTGl/crA4jxEyTYUawaboDLqzLrB/iBBrV8okhSQ",
  render_errors: [view: OneMillionWordsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: OneMillionWords.PubSub,
  live_view: [signing_salt: "fBTHoRN8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
