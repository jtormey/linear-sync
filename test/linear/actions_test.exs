defmodule Linear.ActionsTest do
  use Linear.DataCase

  alias Linear.Actions

  @moduletag :actions

  setup do
    shared_issue = Linear.Factory.insert(:shared_issue)
    %{
      issue_sync: shared_issue.issue_sync,
      shared_issue: shared_issue,
      repo_key: Linear.GithubAPI.to_repo_key!(shared_issue.issue_sync)
    }
  end

  setup :verify_on_exit!

  describe "AddGithubLabels" do
    test "ok: adds labels to a github issue", context do
      action =
        Actions.AddGithubLabels.new(%{
          labels: ["Test label", "Test label 2"]
        })

      expect_github_call(:add_issue_labels, 1, fn _client, repo_key, issue_number, labels ->
        assert context.repo_key == repo_key
        assert context.shared_issue.github_issue_number == issue_number
        assert action.labels == labels
        {200, nil, nil}
      end)

      assert {:ok, _context} = Actions.AddGithubLabels.process(action, context)
    end

    test "ok: does nothing with no labels to add", context do
      action =
        Actions.AddGithubLabels.new(%{
          labels: []
        })

      expect_github_call(:add_issue_labels, 0, fn _, _, _, _ -> :noop end)

      assert {:ok, _context} = Actions.AddGithubLabels.process(action, context)
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

  describe "RemoveGithubLabels" do
    test "ok: removes labels from a github issue", context do
      action =
        Actions.RemoveGithubLabels.new(%{
          labels: ["Test existing label", "Test existing label 2"]
        })

      expect_github_call(:remove_issue_labels, 2, fn _client, repo_key, issue_number, label ->
        assert context.repo_key == repo_key
        assert context.shared_issue.github_issue_number == issue_number
        assert label in action.labels
        {200, nil, nil}
      end)

      assert {:ok, _context} = Actions.RemoveGithubLabels.process(action, context)
    end

    test "ok: does nothing with no labels to remove", context do
      action =
        Actions.RemoveGithubLabels.new(%{
          labels: []
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
end
