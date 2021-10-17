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
end
