defmodule Linear.Synchronize.ContentWriter do
  alias Linear.Data.LnIssue
  alias Linear.GithubAPI.GithubData, as: Gh

  @doc """
  Returns the Linear issue title for a Github repo / issue combination.
  """
  def linear_issue_title(%Gh.Repo{} = gh_repo, %Gh.Issue{} = gh_issue) do
    """
    "#{gh_issue.title}" (#{gh_repo.full_name} ##{gh_issue.number})
    """
  end

  @doc """
  Returns the Linear issue body for a Github repo / issue combination.
  """
  def linear_issue_body(%Gh.Repo{} = gh_repo, %Gh.Issue{} = gh_issue) do
    issue_name = "#{gh_repo.full_name} ##{gh_issue.number}"

    """
    #{gh_issue.body}

    #{unless gh_issue.body == "", do: "___"}

    [#{issue_name}](#{gh_issue.html_url}) #{github_author_signature(gh_issue.user)}

    *via LinearSync*
    """
  end

  @doc """
  Returns the Linear comment body for a Github comment.
  """
  def linear_comment_body(%Gh.Comment{} = gh_comment) do
    """
    #{gh_comment.body}
    ___
    [Comment](#{gh_comment.html_url}) #{github_author_signature(gh_comment.user)}

    *via LinearSync*
    """
  end

  @doc """
  Returns the Linear comment body for a successfully linked Github issue.
  """
  def linear_comment_issue_linked_body(%Gh.Issue{} = gh_issue) do
    """
    Linked to [##{gh_issue.number}](#{gh_issue.html_url}) #{github_author_signature(gh_issue.user)}

    *via LinearSync*
    """
  end

  def github_issue_body(ln_issue) do
    """
    #{ln_issue["description"]}

    #{if ln_issue["description"], do: "___"}

    Automatically created from [Linear (##{ln_issue["number"]})](#{ln_issue["url"]})

    *via LinearSync*
    """
  end

  @doc """
  Returns a signature for Linear issues with a link to the Github author.
  """
  def github_author_signature(%Gh.User{} = gh_user) do
    """
    by [@#{gh_user.login}](#{gh_user.html_url}) on GitHub
    """
  end

  @doc """
  Returns the Github comment body for when an issue was moved to Linear.
  """
  def github_issue_comment_body(%LnIssue{} = ln_issue, body) do
    """
    Comment from [Linear (##{ln_issue.number})](#{ln_issue.url})

    #{body}

    ---
    *via LinearSync*
    """
  end

  @doc """
  Returns the Github comment body for when an issue was moved to Linear.
  """
  def github_issue_moved_comment_body(%LnIssue{} = ln_issue) do
    """
    Automatically moved to [Linear (##{ln_issue.number})](#{ln_issue.url})

    ---
    *via LinearSync*
    """
  end

  @doc """
  Returns true if the text contains the LinearSync comment signature.
  """
  def via_linear_sync?(body) do
    String.contains?(body, "*via LinearSync*")
  end
end
