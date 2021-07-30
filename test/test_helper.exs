ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Linear.Repo, :manual)

Mox.defmock(Linear.LinearAPIMock, for: Linear.LinearAPI.Behaviour)
