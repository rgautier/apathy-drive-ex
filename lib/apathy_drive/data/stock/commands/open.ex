defmodule Commands.Open do
  use Systems.Command

  def keywords, do: ["open"]

  def execute(spirit, nil, _arguments) do
    send_message(spirit, "scroll", "<p>You need a body to do that.</p>")
  end

  def execute(_spirit, monster, arguments) do
    current_room = Parent.of(monster)

    if Enum.any? arguments do
      direction = arguments
                  |> Enum.join(" ")
                  |> Systems.Exit.direction

      room_exit = Systems.Exit.get_exit_by_direction(current_room, direction)

      case room_exit do
        nil ->
          send_message(monster, "scroll", "<p>There is no exit in that direction!</p>")
        %{"kind" => "Door"} ->
          Systems.Exits.Door.open(monster, current_room, room_exit)
        %{"kind" => "Gate"} ->
          Systems.Exits.Gate.open(monster, current_room, room_exit)
        %{"kind" => "Key"} ->
          Systems.Exits.Key.open(monster, current_room, room_exit)
        _ ->
          send_message(monster, "scroll", "<p>That exit has no door.</p>")
      end
    else
      send_message(monster, "scroll", "<p>Open what?</p>")
    end
  end

end
