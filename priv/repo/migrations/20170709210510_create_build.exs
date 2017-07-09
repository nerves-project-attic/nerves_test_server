defmodule NervesTestServer.Repo.Migrations.CreateNervesTestServer.Build do
  use Ecto.Migration

  def change do
    create table(:builds) do
      add :vcs_id, :string
      add :target, :string
      add :result, :map
      add :result_io, :text
      add :node, :string
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime

      timestamps()
    end

    create unique_index(:builds, [:vcs_id])
  end
end
