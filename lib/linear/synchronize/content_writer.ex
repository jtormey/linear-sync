defmodule Linear.Synchronize.ContentWriter do
  alias Linear.GithubAPI.GithubData, as: Gh
  alias Linear.LinearAPI.LinearData, as: Ln

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

  @doc """
  Returns a bracketed Linear issue key, i.e. "[AB-123]"

  Accepts a `brackets: false` opt to return an issue key without brackets.
  """
  def linear_issue_key(ln_issue, opts \\ [])

  def linear_issue_key(%Ln.Issue{team: %Ln.Team{key: team_key}, number: number}, opts)
      when not is_nil(team_key) and not is_nil(number) do
    issue_key = "#{team_key}-#{number}"
    if Keyword.get(opts, :brackets, true), do: "[#{issue_key}]", else: issue_key
  end

  def linear_issue_key(%Ln.Issue{} = _otherwise, _opts), do: nil

  @doc """
  Returns the Github issue body for a given linear issue.
  """
  def github_issue_body(%Ln.Issue{} = ln_issue) do
    """
    #{ln_issue.description}

    #{if ln_issue.description, do: "___"}

    Automatically created from [Linear (##{ln_issue.number})](#{ln_issue.url})

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
  def github_issue_comment_body(%Ln.Issue{} = ln_issue, body) do
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
  def github_issue_moved_comment_body(%Ln.Issue{} = ln_issue) do
    """
    Automatically moved to [Linear (##{ln_issue.number})](#{ln_issue.url})

    ---
    *via LinearSync*
    """
  end

  @doc """
  Returns the title for a Github issue updated from Linear.
  """
  def github_issue_title_from_linear(%Ln.Issue{} = ln_issue) do
    github_issue_title_from_linear(ln_issue.title, ln_issue)
  end

  def github_issue_title_from_linear(original_title, %Ln.Issue{} = ln_issue) do
    original_title <> " " <> linear_issue_key(ln_issue)
  end

  @doc """
  Returns true if the text contains the LinearSync comment signature.
  """
  def via_linear_sync?(body) when is_binary(body) do
    String.contains?(body, "*via LinearSync*")
  end

  def via_linear_sync?(nil), do: false

  @doc """
  Parses Linear issue keys from a binary.

  ## Examples

    iex> parse_linear_issue_keys("[LN-93] My Github issue")
    ["[LN-93]"]

  """
  def parse_linear_issue_keys(title) when is_binary(title) do
    Regex.scan(~r/\[([A-Z0-9]+-\d+)\]/, title) |> Enum.map(&List.last/1)
  end
end
