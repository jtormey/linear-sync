# LinearSync

Syncs GitHub issues and comments with linear.app

The following data are synced:

| From | To | Notes |
| ---- | -- | ----- |
| **GitHub** issue open | **Linear** new issue with `[Open Status]` | Includes author, title, and description at creation. Select an `[Open Status]` on the web UI, and optionally a default assignee and label. |
| **GitHub** issue close | **Linear** issue status set to `[Closed Status]` | Select a `[Closed Status]` on the web UI |
| **GitHub** label | **Linear** label | A label with the same name must exist on Linear |
| **GitHub** comment | **Linear** comment | |
| **Linear** comment | **GitHub** comment | |

## Development

Environment requirements:

  * [Elixir](https://elixir-lang.org/)
  * [Postgres](https://www.postgresql.org/)
  * [ngrok](https://ngrok.com/)

---

Start local postgres service

```
$ docker-compose up
```

Setting up the application:

  * Start an ngrok session: `ngrok http 4000`
  * Copy `config/dev.secret.template.exs` to `config/dev.secret.exs`
  * Configure `ngrok_host` in `config/dev.secret.exs`
  * Configure `Linear.Repo` in `config/dev.secret.exs`
  * Configure `Linear.Auth.Github` in `config/dev.secret.exs` (see: [Creating a GitHub App](https://docs.github.com/en/developers/apps/creating-a-github-app)) with `repo` scope
  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `iex -S mix phx.server`

Now you can visit the URL provided by `ngrok` from your browser to access the application.

### Why use ngrok?

Webhook requests from GitHub or Linear cannot target `localhost`, so while
in development we use `ngrok` to expose the application to the internet. Phoenix
uses this URL when configuring webhooks, therefore allowing the application to
receive webhook requests while still running locally.

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
