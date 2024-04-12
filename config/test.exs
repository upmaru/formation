import Config

config :tesla, Formation.Client, adapter: Tesla.Mock

config :exvcr,
  vcr_cassette_library_dir: "test/fixture/vcr_cassettes"
