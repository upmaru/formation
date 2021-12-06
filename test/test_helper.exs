Mox.defmock(Formation.LexdeeMock, for: Formation.Clients.Lexdee.Behaviour)
Application.put_env(:formation, :lexdee, Formation.LexdeeMock)

ExUnit.start()
