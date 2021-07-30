defmodule Linear.AccountsTest do
  use Linear.DataCase

  import Mox

  alias Linear.Accounts
  alias Linear.Accounts.Account

  @api_key "815c3c82c984bde95e0b0ebc3b8e4a42"
  @api_key_also_valid "3fba2e3ed573ffe26eaf0582c8c8713b"

  def account_fixture() do
    {:ok, account} =
      Accounts.find_or_create_account(@api_key)

    account
  end

  setup do
    context = %{organization_id: Ecto.UUID.generate()}

    stub(Linear.LinearAPIMock, :organization, fn _session ->
      {:ok, %{"data" => %{"organization" => %{"id" => context.organization_id}}}}
    end)

    context
  end

  describe "find_or_create_account/1" do
    test "ok: creates a new account with an organization id", context do
      assert {:ok, account} = Accounts.find_or_create_account(@api_key)

      assert account.organization_id == context.organization_id
    end

    test "ok: returns an existing account" do
      assert {:ok, account_1} = Accounts.find_or_create_account(@api_key)
      assert {:ok, account_2} = Accounts.find_or_create_account(@api_key)

      assert account_1 == account_2
    end

    test "ok: updates an existing account with a new api key" do
      assert {:ok, account_1} = Accounts.find_or_create_account(@api_key)
      assert {:replaced, account_2} = Accounts.find_or_create_account(@api_key_also_valid)

      assert account_1.id == account_2.id
      assert account_2.api_key == @api_key_also_valid
    end

    test "error: fails with an invalid api key" do
      stub(Linear.LinearAPIMock, :organization, fn _session ->
        {:ok, %{"data" => nil}}
      end)

      assert {:error, :invalid_api_key} = Accounts.find_or_create_account(@api_key)
    end
  end

  test "get_account!/1 returns the account with given id" do
    account = account_fixture()
    assert Accounts.get_account!(account.id) == account
  end

  test "delete_account/1 deletes the account" do
    account = account_fixture()
    assert {:ok, %Account{}} = Accounts.delete_account(account)
    assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
  end

  test "change_account/1 returns a account changeset" do
    account = account_fixture()
    assert %Ecto.Changeset{} = Accounts.change_account(account)
  end
end
