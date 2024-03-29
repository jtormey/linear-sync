defmodule Linear.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Linear.Repo
  alias Linear.LinearAPI
  alias Linear.Accounts.Account
  alias Linear.Data
  alias Linear.IssueSyncService

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.
  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Gets a single account by a set of options.
  """
  def get_account_by(opts), do: Repo.get_by(Account, opts)

  @doc """
  Finds an account by api_key.

  If the account is not found, tries to load the organization from the
  Linear API. If successful, tries to find an existing organization in the database.
  If one is found, updates the API key, otherwise creates a new one.
  """
  def find_or_create_account(api_key) when is_binary(api_key) do
    session = LinearAPI.Session.new(api_key)

    linear_api = Application.get_env(:linear, :linear_api, LinearAPI)

    with nil <- Repo.get_by(Account, api_key: api_key),
         {:ok, %{"data" => %{"organization" => %{"id" => org_id}}}} <-
           linear_api.organization(session) do
      if account = Repo.get_by(Account, organization_id: org_id) do
        account =
          account
          |> Account.changeset(%{api_key: api_key})
          |> Repo.update!()

        {:replaced, account}
      else
        %Account{}
        |> Account.changeset(%{api_key: api_key})
        |> Ecto.Changeset.put_change(:organization_id, org_id)
        |> Repo.insert()
      end
    else
      %Account{} = account ->
        {:ok, account}

      {:ok, %{"data" => nil}} ->
        {:error, :invalid_api_key}
    end
  end

  @doc """
  Updates the github connection details for an account.
  """
  def update_account_github_link(%Account{} = account, attrs) do
    account
    |> Ecto.Changeset.cast(attrs, [:github_token, :github_link_state, :github_installation_id])
    |> Repo.update()
    |> broadcast(:github_link)
  end

  @doc """
  Deletes the github connection details for an account.
  """
  def delete_account_github_link(%Account{} = account) do
    account
    |> Ecto.Changeset.change(
      github_token: nil,
      github_link_state: nil,
      github_installation_id: nil
    )
    |> Repo.update()
    |> broadcast(:github_link)
  end

  @doc """
  Deletes an account.
  """
  def delete_account(%Account{} = account) do
    with :ok <- IssueSyncService.disable_issue_syncs_for_account(account),
         :ok <- Data.delete_disabled_issue_syncs_for_account(account) do
      Repo.delete(account)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.
  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  def subscribe(account = %Account{}) do
    Phoenix.PubSub.subscribe(Linear.PubSub, "account:#{account.id}")
  end

  def broadcast({:ok, account = %Account{}}, type) do
    Phoenix.PubSub.broadcast(Linear.PubSub, "account:#{account.id}", {type, account})
    {:ok, account}
  end

  def broadcast({:error, _} = error, _type), do: error
end
