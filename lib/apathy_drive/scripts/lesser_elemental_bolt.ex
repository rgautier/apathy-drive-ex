defmodule ApathyDrive.Scripts.LesserElementalBolt do
  alias ApathyDrive.{Ability, Room}

  @damage %{min: 8, max: 25}

  def execute(%Room{} = room, mobile_ref, target_ref) do
    Room.update_mobile(room, mobile_ref, fn room, character ->
      lore = character.lore

      damage =
        lore.damage_types
        |> Enum.map(fn damage_type ->
          Map.merge(damage_type, %{
            min: div(@damage.min, length(lore.damage_types)),
            max: div(@damage.max, length(lore.damage_types))
          })
        end)

      ability = %Ability{
        kind: "attack",
        name: "lesser elemental bolt",
        energy: 0,
        mana: 0,
        user_message: "You fire a lesser #{lore.name} bolt at {{target}} for {{amount}} damage!",
        target_message: "{{User}} fires a lesser #{lore.name} bolt at you for {{amount}} damage!",
        spectator_message:
          "{{User}} fires a lesser #{lore.name} bolt at {{target}} for {{amount}} damage!",
        traits: %{
          "Damage" => damage
        }
      }

      Ability.execute(room, mobile_ref, ability, [target_ref])
    end)
  end
end
