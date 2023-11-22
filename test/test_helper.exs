Mox.defmock(Formation.LexdeeMock, for: Lexdee.Behaviour)
Application.put_env(:formation, :lexdee, Formation.LexdeeMock)

Application.put_env(:lexdee, :environment, :test)
ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
ExUnit.start()
