defmodule ApathyDrive.Scripts.HolyBlade do
  alias ApathyDrive.{Mobile, Room}

  def execute(%Room{} = room, mobile_ref, item) do
    Room.update_mobile(room, mobile_ref, fn room, character ->
      effect = %{
        "WeaponDamage" => [
          %{kind: "magical", min: 2, max: 2, damage_type: "Holy", damage_type_id: 9}
        ],
        "RemoveMessage" => "A holy blade spell wears off on your #{item.name}.",
        "stack_key" => "sanctify blade",
        "stack_count" => 3
      }

      Mobile.send_scroll(
        character,
        "<p><span class='blue'>Your #{item.name} glows with holy power!</span></p>"
      )

      Room.send_scroll(
        room,
        "<p><span class='blue'>#{character.name}'s #{item.name} glows with holy power!</span></p>",
        [character]
      )

      item = Systems.Effect.add(item, effect, :timer.minutes(24))

      equipment_location =
        Enum.find_index(
          character.equipment,
          &(&1.instance_id == item.instance_id)
        )

      inventory_location =
        Enum.find_index(
          character.inventory,
          &(&1.instance_id == item.instance_id)
        )

      if equipment_location do
        update_in(character.equipment, &List.replace_at(&1, equipment_location, item))
      else
        update_in(character.inventory, &List.replace_at(&1, inventory_location, item))
      end
    end)
  end
end