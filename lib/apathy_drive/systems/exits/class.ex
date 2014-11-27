defmodule Systems.Exits.Class do
  use Systems.Exit

  def move(spirit, nil, current_room, room_exit),  do: super(spirit, nil, current_room, room_exit)
  def move(nil, monster, current_room, room_exit), do: super(nil, monster, current_room, room_exit)

  def move(spirit, monster, current_room, room_exit) do
    class = String.downcase(room_exit["class"])
    name = Components.Name.value(monster) |> String.downcase

    if String.contains?(name, class) do
      super(spirit, monster, current_room, room_exit)
    else
      send_message(monster, "scroll", "<p>Only #{Inflex.pluralize(room_exit["class"])} may go #{room_exit["direction"]} here.</p>")
      Systems.Monster.observers(current_room, monster)
      |> Enum.each(fn(observer) ->
        send_message(observer, "scroll", "<p>#{capitalize_first(Components.Name.value(monster))} tries to go #{room_exit["direction"]} but only #{Inflex.pluralize(room_exit["class"])} may go that way.</span></p>")
      end)
    end
  end
end