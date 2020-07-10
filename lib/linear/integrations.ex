defmodule Linear.Integrations do
  @moduledoc """
  The Integrations context.
  """

  import Ecto.Query, warn: false
  alias Linear.Repo

  alias Linear.Integrations.PublicEntry

  @doc """
  Returns the list of public_entries.

  ## Examples

      iex> list_public_entries()
      [%PublicEntry{}, ...]

  """
  def list_public_entries do
    Repo.all(PublicEntry)
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

  @doc """
  Creates a public_entry.

  ## Examples

      iex> create_public_entry(%{field: value})
      {:ok, %PublicEntry{}}

      iex> create_public_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_public_entry(attrs \\ %{}) do
    %PublicEntry{}
    |> PublicEntry.changeset(attrs)
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
  def update_public_entry(%PublicEntry{} = public_entry, attrs) do
    public_entry
    |> PublicEntry.changeset(attrs)
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
  def change_public_entry(%PublicEntry{} = public_entry, attrs \\ %{}) do
    PublicEntry.changeset(public_entry, attrs)
  end
end
