defmodule Commands.Unlock do
  use ApathyDrive.Command

  def keywords, do: ["unlock"]

  def execute(%Spirit{} = spirit, _arguments) do
    spirit
    |> Spirit.send_scroll("<p>You need a body to do that.</p>")
  end

  def execute(_spirit, monster, arguments) do
    current_room = Parent.of(monster)

    if Enum.any? arguments do
      direction = arguments
                  |> Enum.join(" ")
                  |> ApathyDrive.Exit.direction

      room_exit = ApathyDrive.Exit.get_exit_by_direction(current_room, direction)

      case room_exit do
        nil ->
          Monster.send_scroll(monster, "<p>There is no exit in that direction!</p>")
        %{"kind" => "Door"} ->
          ApathyDrive.Exits.Door.unlock(monster, current_room, room_exit)
        %{"kind" => "Gate"} ->
          ApathyDrive.Exits.Gate.unlock(monster, current_room, room_exit)
        %{"kind" => "Key"} ->
          ApathyDrive.Exits.Key.unlock(monster, current_room, room_exit)
        _ ->
          Monster.send_scroll(monster, "<p>That exit has no door.</p>")
      end
    else
      Monster.send_scroll(monster, "<p>Unlock what?</p>")
    end
  end

end
