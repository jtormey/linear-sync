defmodule Linear.IntegrationsTest do
  use Linear.DataCase

  alias Linear.Integrations

  describe "public_entries" do
    alias Linear.Integrations.PublicEntry

    @valid_attrs %{assign_self: true, label_id: "7488a646-e31f-11e4-aace-600308960662", project_id: "7488a646-e31f-11e4-aace-600308960662", state_id: "7488a646-e31f-11e4-aace-600308960662", team_id: "7488a646-e31f-11e4-aace-600308960662"}
    @update_attrs %{assign_self: false, label_id: "7488a646-e31f-11e4-aace-600308960668", project_id: "7488a646-e31f-11e4-aace-600308960668", state_id: "7488a646-e31f-11e4-aace-600308960668", team_id: "7488a646-e31f-11e4-aace-600308960668"}
    @invalid_attrs %{assign_self: nil, label_id: nil, project_id: nil, state_id: nil, team_id: nil}

    def public_entry_fixture(attrs \\ %{}) do
      {:ok, public_entry} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Integrations.create_public_entry()

      public_entry
    end

    test "list_public_entries/0 returns all public_entries" do
      public_entry = public_entry_fixture()
      assert Integrations.list_public_entries() == [public_entry]
    end

    test "get_public_entry!/1 returns the public_entry with given id" do
      public_entry = public_entry_fixture()
      assert Integrations.get_public_entry!(public_entry.id) == public_entry
    end

    test "create_public_entry/1 with valid data creates a public_entry" do
      assert {:ok, %PublicEntry{} = public_entry} = Integrations.create_public_entry(@valid_attrs)
      assert public_entry.assign_self == true
      assert public_entry.label_id == "7488a646-e31f-11e4-aace-600308960662"
      assert public_entry.project_id == "7488a646-e31f-11e4-aace-600308960662"
      assert public_entry.state_id == "7488a646-e31f-11e4-aace-600308960662"
      assert public_entry.team_id == "7488a646-e31f-11e4-aace-600308960662"
    end

    test "create_public_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Integrations.create_public_entry(@invalid_attrs)
    end

    test "update_public_entry/2 with valid data updates the public_entry" do
      public_entry = public_entry_fixture()
      assert {:ok, %PublicEntry{} = public_entry} = Integrations.update_public_entry(public_entry, @update_attrs)
      assert public_entry.assign_self == false
      assert public_entry.label_id == "7488a646-e31f-11e4-aace-600308960668"
      assert public_entry.project_id == "7488a646-e31f-11e4-aace-600308960668"
      assert public_entry.state_id == "7488a646-e31f-11e4-aace-600308960668"
      assert public_entry.team_id == "7488a646-e31f-11e4-aace-600308960668"
    end

    test "update_public_entry/2 with invalid data returns error changeset" do
      public_entry = public_entry_fixture()
      assert {:error, %Ecto.Changeset{}} = Integrations.update_public_entry(public_entry, @invalid_attrs)
      assert public_entry == Integrations.get_public_entry!(public_entry.id)
    end

    test "delete_public_entry/1 deletes the public_entry" do
      public_entry = public_entry_fixture()
      assert {:ok, %PublicEntry{}} = Integrations.delete_public_entry(public_entry)
      assert_raise Ecto.NoResultsError, fn -> Integrations.get_public_entry!(public_entry.id) end
    end

    test "change_public_entry/1 returns a public_entry changeset" do
      public_entry = public_entry_fixture()
      assert %Ecto.Changeset{} = Integrations.change_public_entry(public_entry)
    end
  end
end
