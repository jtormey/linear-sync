defmodule Linear.ActionsTest do
  use Linear.DataCase

  alias Linear.Actions
  alias Linear.GithubAPI.GithubData, as: Gh
  alias Linear.LinearAPI.LinearData, as: Ln

  @moduletag :actions

  setup do
    shared_issue = Linear.Factory.insert(:shared_issue)
    %{
      issue_sync: shared_issue.issue_sync,
      shared_issue: shared_issue,
      repo_key: Linear.GithubAPI.to_repo_key!(shared_issue.issue_sync),
      github_issue: Gh.Issue.new(%{"title" => "Existing github title"}),
      github_repo_labels: [%Gh.Label{id: 30001, name: "some label"}, %Gh.Label{id: 30002, name: "existing label"}],
      github_issue_labels: [%Gh.Label{id: 30002, name: "existing label"}],
      linear_issue: Ln.Issue.new(%{"title" => "Existing linear title", "labels" => %{"nodes" => [%{"id" => 99, "name" => "Existing Label"}]}}),
      linear_labels: [%Ln.Label{id: 1, name: "Some Label"}, %Ln.Label{id: 99, name: "Existing Label"}]
    }
  end

  setup :verify_on_exit!

  describe "AddGithubLabels" do
    test "ok: adds labels to a github issue", context do
      action =
        Actions.AddGithubLabels.new(%{
          label_ids: [1, 99]
        })

      expect_github_call(:add_issue_labels, 1, fn _client, repo_key, issue_number, labels ->
        assert context.repo_key == repo_key
        assert context.shared_issue.github_issue_number == issue_number
        assert ["some label"] == labels
        {200, nil, nil}
      end)

      assert {:ok, _context} = Actions.AddGithubLabels.process(action, context)
    end

    test "ok: does nothing with no labels to add", context do
      action =
        Actions.AddGithubLabels.new(%{
          label_ids: []
        })

      expect_github_call(:add_issue_labels, 0, fn _, _, _, _ -> :noop end)

      assert {:ok, _context} = Actions.AddGithubLabels.process(action, context)
    end
  end

  describe "BlockLinearPrivateIssue" do
    @private_label %{"id" => 400, "name" => "Private"}

    test "ok: continues if an issue is not private (from context)", context do
      action =
        Actions.BlockLinearPrivateIssue.new()

      assert {:ok, _context} = Actions.BlockLinearPrivateIssue.process(action, context)
    end

    test "error: fails if an issue has a private label (from context)", context do
      action =
        Actions.BlockLinearPrivateIssue.new()

      linear_issue =
        Ln.Issue.new(%{"title" => "Existing linear title", "labels" => %{"nodes" => [@private_label]}})

      context = %{context | linear_issue: linear_issue}

      assert {:error, :linear_issue_is_private} = Actions.BlockLinearPrivateIssue.process(action, context)
    end

    test "ok: continues if an issue is not private (from linear query)", context do
      action =
        Actions.BlockLinearPrivateIssue.new()

      linear_issue =
        Ln.Issue.new(%{"id" => context.shared_issue.id, "title" => "Existing linear title"})

      context = %{context | linear_issue: linear_issue}

      expect_linear_call(:issue, 1, fn _session, issue_id ->
        assert context.shared_issue.id == issue_id
        {:ok, %{"data" => %{"issue" => %{"labels" => %{"nodes" => []}}}}}
      end)

      assert {:ok, _context} = Actions.BlockLinearPrivateIssue.process(action, context)
    end

    test "error: fails if an issue has a private label (from linear query)", context do
      action =
        Actions.BlockLinearPrivateIssue.new()

      linear_issue =
        Ln.Issue.new(%{"id" => context.shared_issue.id, "title" => "Existing linear title"})

      context = %{context | linear_issue: linear_issue}

      expect_linear_call(:issue, 1, fn _session, issue_id ->
        assert context.shared_issue.id == issue_id
        {:ok, %{"data" => %{"issue" => %{"labels" => %{"nodes" => [@private_label]}}}}}
      end)

      assert {:error, :linear_issue_is_private} = Actions.BlockLinearPrivateIssue.process(action, context)
    end

    @tag capture_log: true
    test "error: fails if no labels can be found", context do
      action =
        Actions.BlockLinearPrivateIssue.new()

      linear_issue =
        Ln.Issue.new(%{"id" => context.shared_issue.id, "title" => "Existing linear title"})

      context = %{context | linear_issue: linear_issue}

      expect_linear_call(:issue, 1, fn _session, issue_id ->
        assert context.shared_issue.id == issue_id
        {:ok, %{"data" => %{"badResponse" => true}}}
      end)

      assert {:error, :block_linear_private_issue} = Actions.BlockLinearPrivateIssue.process(action, context)
    end
  end

  describe "CreateGithubComment" do
    test "ok: creates a github comment", context do
      action =
        Actions.CreateGithubComment.new(%{
          body: "Test comment body"
        })

      expect_github_call(:create_issue_comment, 1, fn _client, repo_key, issue_number, body ->
        assert context.repo_key == repo_key
        assert context.shared_issue.github_issue_number == issue_number
        assert "Test comment body" = body
        {201, nil, nil}
      end)

      assert {:ok, _context} = Actions.CreateGithubComment.process(action, context)
    end
  end

  describe "CreateGithubIssue" do
    test "ok: creates a github issue", context do
      action =
        Actions.CreateGithubIssue.new(%{
          title: "Test title",
          body: "Test body"
        })

      expect_github_call(:create_issue, 1, fn _client, repo_key, params ->
        assert context.repo_key == repo_key
        assert %{"title" =>  "Test title", "body" => "Test body"} = params
        {201, %{"id" => 10001, "number" => 10}, nil}
      end)

      assert {:ok, context} = Actions.CreateGithubIssue.process(action, context)
      assert %{github_issue_id: 10001, github_issue_number: 10} = context.shared_issue
    end
  end

  describe "CreateLinearComment" do
    test "ok: creates a linear comment", context do
      action =
        Actions.CreateLinearComment.new(%{
          body: "Test comment body"
        })

      expect_linear_call(:create_comment, 1, fn _session, args ->
        assert args[:issueId] == context.shared_issue.linear_issue_id
        assert args[:body] == "Test comment body"
        {:ok, %{"data" => %{"commentCreate" => %{"success" => true, "comment" => %{}}}}}
      end)

      assert {:ok, _context} = Actions.CreateLinearComment.process(action, context)
    end
  end

  describe "CreateLinearIssue" do
    test "ok: creates a linear issue", context do
      action =
        Actions.CreateLinearIssue.new(%{
          title: "Test title",
          body: "Test body"
        })

      issue_id = Ecto.UUID.generate()

      expect_linear_call(:create_issue, 1, fn _session, args ->
        assert args[:title] == "Test title"
        assert args[:description] == "Test body"
        assert args[:teamId] == context.issue_sync.team_id

        refute Keyword.has_key?(args, :stateId)
        refute Keyword.has_key?(args, :labelIds)
        refute Keyword.has_key?(args, :assigneeId)

        {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => %{"id" => issue_id, "number" => 93}}}}}
      end)

      assert {:cont, {context, []}} = Actions.CreateLinearIssue.process(action, context)
      assert %{linear_issue_id: ^issue_id, linear_issue_number: 93} = context.shared_issue
    end

    test "ok: creates a linear issue with a configured issue sync", context do
      action =
        Actions.CreateLinearIssue.new(%{
          title: "Test title",
          body: "Test body"
        })

      issue_id = Ecto.UUID.generate()

      issue_sync_updates = %{
        label_id: Ecto.UUID.generate(),
        assignee_id: Ecto.UUID.generate(),
        open_state_id: Ecto.UUID.generate()
      }

      issue_sync =
        context.issue_sync
        |> Ecto.Changeset.change(issue_sync_updates)
        |> Linear.Repo.update!()

      context = %{context | issue_sync: issue_sync}

      expect_linear_call(:create_issue, 1, fn _session, args ->
        assert args[:title] == "Test title"
        assert args[:description] == "Test body"
        assert args[:teamId] == context.issue_sync.team_id

        assert args[:stateId] == issue_sync_updates.open_state_id
        assert args[:labelIds] == [issue_sync_updates.label_id]
        assert args[:assigneeId] == issue_sync_updates.assignee_id

        {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => %{"id" => issue_id, "number" => 93}}}}}
      end)

      assert {:cont, {context, []}} = Actions.CreateLinearIssue.process(action, context)
      assert %{linear_issue_id: ^issue_id, linear_issue_number: 93} = context.shared_issue
    end

    test "ok: returns action to update github issue status when configured", context do
      action =
        Actions.CreateLinearIssue.new(%{
          title: "Test title",
          body: "Test body"
        })

      issue_id = Ecto.UUID.generate()

      issue_sync =
        context.issue_sync
        |> Ecto.Changeset.change(close_on_open: true)
        |> Linear.Repo.update!()

      context = %{context | issue_sync: issue_sync}

      expect_linear_call(:create_issue, 1, fn _session, _args ->
        {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => %{"id" => issue_id, "number" => 93}}}}}
      end)

      assert {:cont, {context, actions}} = Actions.CreateLinearIssue.process(action, context)
      assert %{linear_issue_id: ^issue_id, linear_issue_number: 93} = context.shared_issue

      assert [
          %Linear.Actions.CreateGithubComment{
            body: "Automatically moved to [Linear (#93)]()\n\n---\n*via LinearSync*\n"
          },
          %Linear.Actions.UpdateGithubIssue{
            state: :closed
          }
        ] = actions
    end

    test "ok: returns action to update github issue title when configured", context do
      action =
        Actions.CreateLinearIssue.new(%{
          title: "Test title",
          body: "Test body"
        })

      issue_id = Ecto.UUID.generate()

      issue_sync =
        context.issue_sync
        |> Ecto.Changeset.change(sync_github_issue_titles: true)
        |> Linear.Repo.update!()

      context = %{context | issue_sync: issue_sync}

      expect_linear_call(:create_issue, 1, fn _session, _args ->
        {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => %{"id" => issue_id, "number" => 93, "url" => "https://linear-issue-93", "team" => %{"key" => "TST"}}}}}}
      end)

      assert {:cont, {context, actions}} = Actions.CreateLinearIssue.process(action, context)
      assert %{linear_issue_id: ^issue_id, linear_issue_number: 93} = context.shared_issue

      assert [
          %Linear.Actions.UpdateGithubIssue{
            title: "Existing github title [TST-93]"
          }
        ] = actions
    end

    test "ok: returns action to update github issue status and title when configured", context do
      action =
        Actions.CreateLinearIssue.new(%{
          title: "Test title",
          body: "Test body"
        })

      issue_id = Ecto.UUID.generate()

      issue_sync =
        context.issue_sync
        |> Ecto.Changeset.change(close_on_open: true, sync_github_issue_titles: true)
        |> Linear.Repo.update!()

      context = %{context | issue_sync: issue_sync}

      expect_linear_call(:create_issue, 1, fn _session, _args ->
        {:ok, %{"data" => %{"issueCreate" => %{"success" => true, "issue" => %{"id" => issue_id, "number" => 93, "url" => "https://linear-issue-93", "team" => %{"key" => "TST"}}}}}}
      end)

      assert {:cont, {context, actions}} = Actions.CreateLinearIssue.process(action, context)
      assert %{linear_issue_id: ^issue_id, linear_issue_number: 93} = context.shared_issue

      assert [
          %Linear.Actions.UpdateGithubIssue{
            title: "Existing github title [TST-93]"
          },
          %Linear.Actions.CreateGithubComment{
            body: "Automatically moved to [Linear (#93)](https://linear-issue-93)\n\n---\n*via LinearSync*\n"
          },
          %Linear.Actions.UpdateGithubIssue{
            state: :closed
          }
        ] = actions
    end
  end

  describe "FetchGithubLabels" do
    test "ok: fetches github repo and issue labels", context do
      action =
        Actions.FetchGithubLabels.new()

      expect_github_call(:list_repository_labels, 1, fn _client, repo_key ->
        assert context.repo_key == repo_key
        {200, [%{"id" => 30001, "name" => "some label"}, %{"id" => 30002, "name" => "existing label"}], nil}
      end)

      expect_github_call(:list_issue_labels, 1, fn _client, repo_key, issue_number ->
        assert context.repo_key == repo_key
        assert context.shared_issue.github_issue_number == issue_number
        {200, [%{"id" => 30002, "name" => "existing label"}], nil}
      end)

      %{github_repo_labels: github_repo_labels, github_issue_labels: github_issue_labels} = context

      assert {:ok, context} = Actions.FetchGithubLabels.process(action, context)
      assert %{github_repo_labels: ^github_repo_labels, github_issue_labels: ^github_issue_labels} = context
    end
  end

  describe "FetchLinearIssue" do
    test "ok: fetches a linear issue by issue id number", context do
      action =
        Actions.FetchLinearIssue.new(%{
          issue_number: 93
        })

      issue_id = Ecto.UUID.generate()

      expect_linear_call(:issue, 1, fn _session, 93 ->
        {:ok, %{"data" => %{"issue" => %{"id" => issue_id, "number" => 93, "url" => "https://linear-issue-93", "team" => %{"key" => "TST"}}}}}
      end)

      assert {:ok, context} = Actions.FetchLinearIssue.process(action, context)
      assert %{id: ^issue_id, number: 93} = context.linear_issue
      assert %{linear_issue_id: ^issue_id, linear_issue_number: 93} = context.shared_issue
    end

    test "ok: fetches a linear issue by inferred issue id", context do
      action =
        Actions.FetchLinearIssue.new()

      issue_id = Ecto.UUID.generate()

      shared_issue =
        context.shared_issue
        |> Ecto.Changeset.change(linear_issue_id: issue_id, linear_issue_number: 93)
        |> Linear.Repo.update!()

      context = %{context | shared_issue: shared_issue}

      expect_linear_call(:issue, 1, fn _session, 93 ->
        {:ok, %{"data" => %{"issue" => %{"id" => issue_id, "number" => 93, "url" => "https://linear-issue-93", "team" => %{"key" => "TST"}}}}}
      end)

      assert {:ok, context} = Actions.FetchLinearIssue.process(action, context)
      assert %{id: ^issue_id, number: 93} = context.linear_issue
      assert %{linear_issue_id: ^issue_id, linear_issue_number: 93} = context.shared_issue
    end
  end

  describe "FetchLinearLabels" do
    test "ok: fetches all linear labels", context do
      action =
        Actions.FetchLinearLabels.new()

      expect_linear_call(:list_issue_labels, 1, fn _session ->
        {:ok, %{"data" => %{"issueLabels" => %{"nodes" => [%{"id" => 1, "name" => "Test label 1"}, %{"id" => 2, "name" => "Test label 2"}]}}}}
      end)

      assert {:ok, context} = Actions.FetchLinearLabels.process(action, context)

      assert [
          %Ln.Label{id: 1, name: "Test label 1"},
          %Ln.Label{id: 2, name: "Test label 2"}
        ] = context.linear_labels
    end
  end

  describe "RemoveGithubLabels" do
    test "ok: removes labels from a github issue", context do
      action =
        Actions.RemoveGithubLabels.new(%{
          label_ids: [1, 99]
        })

      expect_github_call(:remove_issue_labels, 1, fn _client, repo_key, issue_number, label ->
        assert context.repo_key == repo_key
        assert context.shared_issue.github_issue_number == issue_number
        assert label in ["existing label"]
        {200, nil, nil}
      end)

      assert {:ok, _context} = Actions.RemoveGithubLabels.process(action, context)
    end

    test "ok: does nothing with no labels to remove", context do
      action =
        Actions.RemoveGithubLabels.new(%{
          label_ids: []
        })

      expect_github_call(:remove_issue_labels, 0, fn _, _, _, _ -> :noop end)

      assert {:ok, _context} = Actions.RemoveGithubLabels.process(action, context)
    end
  end

  describe "UpdateGithubIssue" do
    test "ok: updates a github issue", context do
      action =
        Actions.UpdateGithubIssue.new(%{
          title: "Updated title"
        })

      expect_github_call(:update_issue, 1, fn _client, repo_key, issue_number, params ->
        assert context.repo_key == repo_key
        assert context.shared_issue.github_issue_number == issue_number
        assert %{"title" =>  "Updated title"} = params
        {200, nil, nil}
      end)

      assert {:ok, _context} = Actions.UpdateGithubIssue.process(action, context)
    end
  end

  describe "UpdateLinearIssue" do
    test "ok: updates the state of a linear issue", context do
      state_id = Ecto.UUID.generate()

      action =
        Actions.UpdateLinearIssue.new(%{
          state_id: state_id
        })

      context = Map.put(context, :linear_labels, [])

      expect_linear_call(:update_issue, 1, fn _session, args ->
        assert args[:issueId] == context.shared_issue.linear_issue_id
        assert args[:stateId] == state_id
        {:ok, %{"data" => %{"issueUpdate" => %{"success" => true, "issue" => %{}}}}}
      end)

      assert {:ok, _context} = Actions.UpdateLinearIssue.process(action, context)
    end

    test "ok: adds a github label to a linear issue", context do
      action =
        Actions.UpdateLinearIssue.new(%{
          add_labels: [%Gh.Label{id: 30001, name: "some label", color: "#ffffff", description: ""}]
        })

      expect_linear_call(:update_issue, 1, fn _session, args ->
        assert args[:issueId] == context.shared_issue.linear_issue_id
        assert args[:labelIds] == [1, 99]
        {:ok, %{"data" => %{"issueUpdate" => %{"success" => true, "issue" => %{}}}}}
      end)

      assert {:ok, _context} = Actions.UpdateLinearIssue.process(action, context)
    end

    test "ok: removes a github label from a linear issue", context do
      action =
        Actions.UpdateLinearIssue.new(%{
          remove_labels: [%Gh.Label{id: 30002, name: "existing label", color: "#ffffff", description: ""}]
        })

      expect_linear_call(:update_issue, 1, fn _session, args ->
        assert args[:issueId] == context.shared_issue.linear_issue_id
        assert args[:labelIds] == []
        {:ok, %{"data" => %{"issueUpdate" => %{"success" => true, "issue" => %{}}}}}
      end)

      assert {:ok, _context} = Actions.UpdateLinearIssue.process(action, context)
    end
  end
end
