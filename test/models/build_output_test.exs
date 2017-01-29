defmodule Juggler.BuildOutputTest do
  use Juggler.ModelCase

  alias Juggler.BuildOutput

  @valid_attrs %{event: "some content", payload: %{}}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = BuildOutput.changeset(%BuildOutput{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = BuildOutput.changeset(%BuildOutput{}, @invalid_attrs)
    refute changeset.valid?
  end
end
