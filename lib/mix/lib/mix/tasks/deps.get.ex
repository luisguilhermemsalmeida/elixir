defmodule Mix.Tasks.Deps.Get do
  use Mix.Task

  import Mix.Dep, only: [load_on_environment: 1, check_lock: 1]

  @shortdoc "Gets all out of date dependencies"

  @moduledoc """
  Gets all out of date dependencies, i.e. dependencies
  that are not available or have an invalid lock.

  ## Command line options

    * `--only` - only fetches dependencies for given environment
    * `--no-archives-check` - does not check archives before fetching deps

  """

  @impl true
  def run(args) do
    unless "--no-archives-check" in args do
      Mix.Task.run("archive.check", args)
    end
    if "--strict" in args do
      load_on_environment([])
      |> Enum.sort_by(& &1.app)
      |> Enum.each(fn dep ->
        case check_lock(dep) do
          %Mix.Dep{status: {:lockmismatch, _}} -> Mix.raise("Lock mismatch")
          _ -> :ok
        end
      end)
    end

    Mix.Project.get!()
    {opts, _, _} = OptionParser.parse(args, switches: [only: :string, target: :string])

    fetch_opts =
      for {switch, key} <- [only: :env, target: :target],
          value = opts[switch],
          do: {key, :"#{value}"}

    apps = Mix.Dep.Fetcher.all(%{}, Mix.Dep.Lock.read(), fetch_opts)

    if apps == [] do
      Mix.shell().info("All dependencies are up to date")
    else
      :ok
    end
  end
end
