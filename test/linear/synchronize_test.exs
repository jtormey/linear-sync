defmodule Linear.SynchronizeTest do
  use Linear.DataCase

  import Mox

  alias Linear.Synchronize
  alias Linear.Repo
  alias Linear.Accounts.Account
  alias Linear.Data
  alias Linear.Data.IssueSync

  @api_key "815c3c82c984bde95e0b0ebc3b8e4a42"

  setup :verify_on_exit!

  setup do
    {:ok, account} =
      %Account{api_key: @api_key, organization_id: Ecto.UUID.generate()}
      |> Repo.insert()

    attrs = %{
      enabled: true,
      repo_id: 1,
      repo_owner: "test_owner",
      repo_name: "test_repo",
      source_name: "source",
      dest_name: "dest",
      team_id: Ecto.UUID.generate()
    }

    {:ok, issue_sync} =
      %IssueSync{}
      |> IssueSync.assoc_changeset(account, attrs)
      |> Repo.insert()

    %{account: account, issue_sync: issue_sync}
  end

  describe "handle_incoming/2 github: issue opened" do
    test "ok: creates a new linear issue from a github issue" do
      expect(Linear.LinearAPIMock, :create_issue, 1, fn _session, _args ->
        {:ok, make_ln_success("issueCreate", "issue", make_ln_issue())}
      end)

      simulate(:github_issue_opened)
    end

    test "ok: creates a new linear issue from a github pr" do
      expect(Linear.LinearAPIMock, :create_issue, 1, fn _session, _args ->
        {:ok, make_ln_success("issueCreate", "issue", make_ln_issue())}
      end)

      simulate(:github_pull_request_opened)
    end

    test "ok: does not create a new linear issue if issue sync is disabled", context do
      Data.update_issue_sync(context.issue_sync, %{enabled: false})

      stub(Linear.LinearAPIMock, :create_issue, fn _session, _args ->
        send(self(), :create_issue_called)
      end)

      simulate(:github_issue_opened)

      refute_received :create_issue_called
    end

    test "ok: updates github issue title if sync github titles is configured", context do
      Data.update_issue_sync(context.issue_sync, %{sync_github_issue_titles: true})

      stub(Linear.LinearAPIMock, :create_issue, fn _session, _args ->
        {:ok, make_ln_success("issueCreate", "issue", make_ln_issue())}
      end)

      expect(Linear.GithubAPIMock, :update_issue, 1, fn _client, repo_key, issue_number, args ->
        assert {"test_owner", "test_repo"} = repo_key
        assert 2 == issue_number
        assert args["title"] =~ "[LN-3]"
        {200, nil, nil}
      end)

      simulate(:github_issue_opened)
    end

    test "ok: closes and comments on github issue if close on open is configured", context do
      Data.update_issue_sync(context.issue_sync, %{close_on_open: true})

      stub(Linear.LinearAPIMock, :create_issue, fn _session, _args ->
        {:ok, make_ln_success("issueCreate", "issue", make_ln_issue())}
      end)

      expect(Linear.GithubAPIMock, :create_issue_comment, 1, fn _client,
                                                                repo_key,
                                                                issue_number,
                                                                body ->
        assert {"test_owner", "test_repo"} = repo_key
        assert 2 == issue_number
        assert body =~ "Automatically moved to [Linear (#3)]"
        {201, nil, nil}
      end)

      expect(Linear.GithubAPIMock, :update_issue, 1, fn _client, repo_key, issue_number, args ->
        assert {"test_owner", "test_repo"} = repo_key
        assert 2 == issue_number
        assert %{"state" => "closed"} = args
        {200, nil, nil}
      end)

      simulate(:github_issue_opened)
    end
  end

  # describe "handle_incoming/2 github: pr opened", context do
  # describe "handle_incoming/2 github: issue closed"
  # describe "handle_incoming/2 github: comment created"
  # describe "handle_incoming/2 github: issue labeled"
  # describe "handle_incoming/2 github: issue unlabeled"
  # describe "handle_incoming/2 linear: issue created"
  # describe "handle_incoming/2 linear: issue updated"
  # describe "handle_incoming/2 linear: comment created"

  def simulate(:github_issue_opened) do
    Synchronize.handle_incoming(:github, %{
      "action" => "opened",
      "repository" => make_gh_repo(),
      "issue" => make_gh_issue()
    })
  end

  def simulate(:github_pull_request_opened) do
    Synchronize.handle_incoming(:github, %{
      "action" => "opened",
      "repository" => make_gh_repo(),
      "pull_request" => make_gh_issue()
    })
  end

  def make_gh_repo() do
    %{
      "id" => 1,
      "full_name" => "Test Repository",
      "html_url" => "https://github.com/test_user/test_repo"
    }
  end

  def make_gh_user() do
    %{
      "id" => Ecto.UUID.generate(),
      "login" => "test_user",
      "html_url" => "https://github.com/test_user"
    }
  end

  def make_gh_issue() do
    %{
      "id" => 2,
      "title" => "New issue",
      "body" => "Issue body",
      "number" => 2,
      "user" => make_gh_user(),
      "html_url" => "https://github.com/issue/2"
    }
  end

  def make_ln_issue() do
    %{
      "id" => Ecto.UUID.generate(),
      "number" => 3,
      "url" => "https://linear.app/ln_team/LN/3",
      "team" => %{
        "key" => "LN"
      }
    }
  end

  def make_ln_success(type, resource, data) do
    %{"data" => %{type => %{"success" => true, resource => data}}}
  end
end
