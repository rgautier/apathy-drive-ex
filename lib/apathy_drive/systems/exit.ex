defmodule Systems.Exit do
  use Systems.Reload
  import Utility

  def direction(direction) do
    case direction do
      "n" ->
        "north"
      "ne" ->
        "northeast"
      "e" ->
        "east"
      "se" ->
        "southeast"
      "s" ->
        "south"
      "sw" ->
        "southwest"
      "w" ->
        "west"
      "nw" ->
        "northwest"
      "u" ->
        "up"
      "d" ->
        "down"
      direction ->
        direction
    end
  end

  def look(spirit, monster, direction) do
    current_room = Parent.of(spirit)
    room_exit = current_room |> get_exit_by_direction(direction)
    look(spirit, monster, current_room, room_exit)
  end

  def look(spirit, _monster, _current_room, nil) do
    send_message(spirit, "scroll", "<p>There is no exit in that direction.</p>")
  end

  def look(spirit, monster, current_room, room_exit) do
    :"Elixir.Systems.Exits.#{room_exit.kind}".look(spirit, monster, current_room, room_exit)
  end

  def move(nil, monster, direction) do
    current_room = Parent.of(monster)
    room_exit = current_room |> get_exit_by_direction(direction)
    move(nil, monster, current_room, room_exit)
  end

  def move(spirit, monster, direction) do
    current_room = Spirit.room(spirit)
    room_exit = current_room |> get_exit_by_direction(direction)
    move(spirit, monster, current_room, room_exit)
  end

  def move(nil,    _monster, _current_room, nil), do: nil
  def move(spirit, _monster, _current_room, nil) do
    send_message(spirit, "scroll", "<p>There is no exit in that direction.</p>")
  end

  def move(spirit, monster, current_room, room_exit) do
    :"Elixir.Systems.Exits.#{room_exit.kind}".move(spirit, monster, current_room, room_exit)
  end

  def get_exit_by_direction(room, direction) do
    room.exits
    |> Enum.find(&(&1.direction == direction(direction)))
  end

  def direction_description(direction) do
    case direction do
    "up" ->
      "above you"
    "down" ->
      "below you"
    direction ->
      "to the #{direction}"
    end
  end

  defmacro __using__(_opts) do
    quote do
      use Systems.Reload
      import Systems.Text
      import Utility
      import BlockTimer
      alias Systems.Monster
      alias Systems.Exit

      def display_direction(_room, room_exit) do
        room_exit.direction
      end

      def move(spirit, nil, current_room, room_exit) do
        Spirit.set_room_id(spirit, room_exit.destination)
        Spirit.deactivate_hint(spirit, "movement")
        Systems.Room.display_room_in_scroll(spirit, nil)
      end

      def move(nil, monster, current_room, room_exit) do
        if !Systems.Combat.stunned?(monster) do
          destination = Rooms.find_by_id(room_exit.destination)
          Components.Monsters.remove_monster(current_room, monster)
          Components.Monsters.add_monster(destination, monster)
          if Entity.has_component?(monster, Components.ID) do
            Entities.save!(destination)
            Entities.save!(current_room)
          end
          Entities.save(monster)
          notify_monster_left(monster, current_room, destination)
          notify_monster_entered(monster, current_room, destination)
        end
      end

      def move(spirit, monster, current_room, room_exit) do
        if Systems.Combat.stunned?(monster) do
          send_message(monster, "scroll", "<p><span class='yellow'>You are stunned and cannot move!</span></p>")
        else
          destination = Rooms.find_by_id(room_exit.destination)
          Components.Monsters.remove_monster(current_room, monster)
          Components.Monsters.add_monster(destination, monster)
          Components.Characters.remove_character(current_room, spirit)
          Components.Characters.add_character(destination, spirit)
          Entities.save!(destination)
          Entities.save!(current_room)
          Entities.save!(spirit)
          Entities.save(monster)
          notify_monster_left(monster, current_room, destination)
          notify_monster_entered(monster, current_room, destination)
          Spirit.deactivate_hint(spirit, "movement")
          Systems.Room.display_room_in_scroll(spirit, monster, destination)
        end
      end

      def look(spirit, monster, current_room, room_exit) do
        {mirror_room, mirror_exit} = mirror(current_room, room_exit)

        Systems.Room.display_room_in_scroll(spirit, monster, mirror_room)

        if monster && mirror_exit do

          mirror_room
          |> Systems.Room.characters_in_room
          |> Enum.each(fn(character) ->
               message = "#{Components.Name.value(monster)} peeks in from #{Systems.Monster.enter_direction(mirror_exit.direction)}!"
                         |> capitalize_first

               send_message(character, "scroll", "<p><span class='dark-magenta'>#{message}</span></p>")
             end)
        end
      end

      def notify_monster_entered(monster, entered_from, room) do
        direction = get_direction_by_destination(room, entered_from)
        if direction do
          Monster.display_enter_message(room, monster, direction)
        else
          Monster.display_enter_message(room, monster)
        end
        Systems.Aggression.monster_entered(monster, room)
      end

      def notify_monster_left(monster, room, left_to) do
        direction = get_direction_by_destination(room, left_to)
        if direction do
          Monster.display_exit_message(room, monster, direction)
          Monster.pursue(room, monster, direction)
        else
          Monster.display_exit_message(room, monster)
        end
      end

      def get_direction_by_destination(room, destination) do
        exits = Components.Exits.value(room)
        exit_to_destination = exits
                              |> Enum.find fn(room_exit) ->
                                   other_room = Rooms.find_by_id(room_exit.destination)
                                   other_room == destination
                                 end
        exit_to_destination.direction
      end

      def mirror(room, room_exit) do
        mirror_room = Rooms.find_by_id(room_exit.destination)
        room_exit = mirror_room
                    |> Room.exits
                    |> Enum.find(fn(room_exit) ->
                         room_exit.destination == Room.value(room).id
                       end)
        {mirror_room, room_exit}
      end

      defoverridable [move: 4,
                      look: 4,
                      display_direction: 2]
    end
  end

end
