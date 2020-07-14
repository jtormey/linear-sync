defmodule Linear.Integrations do
  @moduledoc """
  The Integrations context.
  """

  import Ecto.Query, warn: false
  alias Linear.Repo

  alias Linear.Accounts.Account
  alias Linear.Integrations.PublicEntry

  @doc """
  Returns the list of public_entries.

  ## Examples

      iex> list_public_entries(account)
      [%PublicEntry{}, ...]

  """
  def list_public_entries(account = %Account{}) do
    Repo.all from p in PublicEntry,
      where: [account_id: ^account.id],
      order_by: {:desc, :inserted_at}
  end

  @doc """
  Gets a single public_entry.

  Raises `Ecto.NoResultsError` if the Public entry does not exist.

  ## Examples

      iex> get_public_entry!(123)
      %PublicEntry{}

      iex> get_public_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_public_entry!(id), do: Repo.get!(PublicEntry, id)

  def get_public_entry_from_param!(param) do
    Repo.get_by!(PublicEntry, external_id: PublicEntry.from_param(param))
  end

  @doc """
  Creates a public_entry.

  ## Examples

      iex> create_public_entry(%{field: value})
      {:ok, %PublicEntry{}}

      iex> create_public_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_public_entry(account = %Account{}, attrs \\ %{}) do
    %PublicEntry{}
    |> PublicEntry.changeset(account, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a public_entry.

  ## Examples

      iex> update_public_entry(public_entry, %{field: new_value})
      {:ok, %PublicEntry{}}

      iex> update_public_entry(public_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_public_entry(%PublicEntry{} = public_entry, account = %Account{}, attrs) do
    public_entry
    |> PublicEntry.changeset(account, attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a public_entry.

  ## Examples

      iex> delete_public_entry(public_entry)
      {:ok, %PublicEntry{}}

      iex> delete_public_entry(public_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_public_entry(%PublicEntry{} = public_entry) do
    Repo.delete(public_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking public_entry changes.

  ## Examples

      iex> change_public_entry(public_entry)
      %Ecto.Changeset{data: %PublicEntry{}}

  """
  def change_public_entry(%PublicEntry{} = public_entry, account = %Account{}, attrs \\ %{}) do
    PublicEntry.changeset(public_entry, account, attrs)
  end

  alias Linear.Integrations.LnIssue

  @doc """
  Returns the ln_issues for an account, grouped by public_entry_id.

  ## Examples

      iex> group_ln_issues(account)
      %{1 => [%LnIssue{}, ...], ...}

  """
  def group_ln_issues(account = %Account{}) do
    ln_issues = Repo.all from l in LnIssue,
      join: p in PublicEntry, on: [id: l.public_entry_id],
      where: p.account_id == ^account.id,
      order_by: {:desc, :inserted_at}

    Enum.group_by(ln_issues, & &1.public_entry_id)
  end

  @doc """
  Gets a single ln_issue.

  Raises `Ecto.NoResultsError` if the Ln issue does not exist.

  ## Examples

      iex> get_ln_issue!(123)
      %LnIssue{}

      iex> get_ln_issue!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ln_issue!(id), do: Repo.get!(LnIssue, id)

  @doc """
  Creates a ln_issue.

  ## Examples

      iex> create_ln_issue(%{field: value})
      {:ok, %LnIssue{}}

      iex> create_ln_issue(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ln_issue(public_entry = %PublicEntry{}, attrs \\ %{}) do
    %LnIssue{}
    |> LnIssue.changeset(public_entry, attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a ln_issue.

  ## Examples

      iex> delete_ln_issue(ln_issue)
      {:ok, %LnIssue{}}

      iex> delete_ln_issue(ln_issue)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ln_issue(%LnIssue{} = ln_issue) do
    Repo.delete(ln_issue)
  end
end
