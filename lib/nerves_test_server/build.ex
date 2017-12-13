defmodule NervesTestServer.Build do
  use Ecto.Schema
  import Ecto.Changeset
  alias NervesTestServer.Build

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "builds" do
    field :vcs_id, :string
    field :org, :string
    field :system, :string
    field :device, :string
    field :result, :map
    field :result_io, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(%Build{} = build, attrs) do
    build
    |> cast(attrs, [:vcs_id, :org, :system, :result, :result_io, :device, :start_time, :end_time])
    |> validate_required([:vcs_id, :org, :system])
    |> unique_constraint(:vcs_id)
  end
end
