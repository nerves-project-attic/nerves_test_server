defmodule NervesTestServer.Build do
  use Ecto.Schema
  import Ecto.Changeset
  alias NervesTestServer.Build


  schema "builds" do
    field :end_time, :utc_datetime
    field :node, :string
    field :result, :map
    field :result_io, :string
    field :start_time, :utc_datetime
    field :target, :string
    field :vcs_id, :string

    timestamps()
  end

  @doc false
  def changeset(%Build{} = build, attrs) do
    build
    |> cast(attrs, [:vcs_id, :target, :result, :result_io, :node, :start_time, :end_time])
    |> validate_required([:vcs_id, :target, :result, :result_io, :node, :start_time, :end_time])
    |> unique_constraint(:vcs_id)
  end
end
