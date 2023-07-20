import Config

config :logger,
  level: :info

config :versioce,
  post_hooks: [Versioce.PostHooks.Changelog]

config :versioce, :changelog,
  datagrabber: Versioce.Changelog.DataGrabber.Git,
  formatter: Versioce.Changelog.Formatter.Keepachangelog,
  anchors: %{
    added: ["add:", "build:"],
    changed: ["refactor:", "feat:", "docs:", "ci:"],
    deprecated: ["chore:"],
    removed: ["revert:"],
    fixed: ["fix:", "perf:"],
    security: []
  }
