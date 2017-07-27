defmodule NervesTestServer.Repo.Migrations.CreateNervesTestServer.Build do
  use Ecto.Migration

  def change do
    create table(:builds) do
      add :vcs_id, :string
      add :org, :string
      add :system, :string
      add :result, :map
      add :result_io, :text
      add :device, :string
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime

      timestamps()
    end

    create unique_index(:builds, [:vcs_id])
  end
end
