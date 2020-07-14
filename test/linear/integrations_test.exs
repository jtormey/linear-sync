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

  describe "ln_issues" do
    alias Linear.Integrations.LnIssue

    @valid_attrs %{description: "some description", number: 42, title: "some title", url: "some url"}
    @update_attrs %{description: "some updated description", number: 43, title: "some updated title", url: "some updated url"}
    @invalid_attrs %{description: nil, number: nil, title: nil, url: nil}

    def ln_issue_fixture(attrs \\ %{}) do
      {:ok, ln_issue} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Integrations.create_ln_issue()

      ln_issue
    end

    test "list_ln_issues/0 returns all ln_issues" do
      ln_issue = ln_issue_fixture()
      assert Integrations.list_ln_issues() == [ln_issue]
    end

    test "get_ln_issue!/1 returns the ln_issue with given id" do
      ln_issue = ln_issue_fixture()
      assert Integrations.get_ln_issue!(ln_issue.id) == ln_issue
    end

    test "create_ln_issue/1 with valid data creates a ln_issue" do
      assert {:ok, %LnIssue{} = ln_issue} = Integrations.create_ln_issue(@valid_attrs)
      assert ln_issue.description == "some description"
      assert ln_issue.number == 42
      assert ln_issue.title == "some title"
      assert ln_issue.url == "some url"
    end

    test "create_ln_issue/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Integrations.create_ln_issue(@invalid_attrs)
    end

    test "update_ln_issue/2 with valid data updates the ln_issue" do
      ln_issue = ln_issue_fixture()
      assert {:ok, %LnIssue{} = ln_issue} = Integrations.update_ln_issue(ln_issue, @update_attrs)
      assert ln_issue.description == "some updated description"
      assert ln_issue.number == 43
      assert ln_issue.title == "some updated title"
      assert ln_issue.url == "some updated url"
    end

    test "update_ln_issue/2 with invalid data returns error changeset" do
      ln_issue = ln_issue_fixture()
      assert {:error, %Ecto.Changeset{}} = Integrations.update_ln_issue(ln_issue, @invalid_attrs)
      assert ln_issue == Integrations.get_ln_issue!(ln_issue.id)
    end

    test "delete_ln_issue/1 deletes the ln_issue" do
      ln_issue = ln_issue_fixture()
      assert {:ok, %LnIssue{}} = Integrations.delete_ln_issue(ln_issue)
      assert_raise Ecto.NoResultsError, fn -> Integrations.get_ln_issue!(ln_issue.id) end
    end

    test "change_ln_issue/1 returns a ln_issue changeset" do
      ln_issue = ln_issue_fixture()
      assert %Ecto.Changeset{} = Integrations.change_ln_issue(ln_issue)
    end
  end
end
