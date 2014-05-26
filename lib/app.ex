defmodule ApathyDrive do

  require Weber.Templates.ViewsLoader

  def start(_type, _args) do

    :crypto.start
    :bcrypt.start
    :random.seed(:erlang.now)

    Players.start_link
    Races.start_link
    Classes.start_link
    Characters.start_link
    Monsters.start_link
    MonsterTemplates.start_link
    Items.start_link
    ItemTemplates.start_link
    Rooms.start_link
    Exits.start_link
    Components.start_link
    Systems.Help.start_link
    Repo.start_link
    # Set resources
    Weber.Templates.ViewsLoader.set_up_resources(File.cwd!)
    # compile all views
    Weber.Templates.ViewsLoader.compile_views(File.cwd!)

    if Mix.env != :test do
      IO.puts "Loading Entities..."
      Entity.load!
      IO.puts "Done!"
    end

    Systems.LairSpawning.initialize

    # start weber application
    Weber.run_weber

  end

  def stop(_state) do
    :ok
  end

end
