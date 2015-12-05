defmodule ApathyDrive.AI do
  alias ApathyDrive.Mobile

  def think(%Mobile{} = mobile) do
    mobile =
      mobile
      |> calm_down()

    heal(mobile) || bless(mobile) || attack(mobile) || mobile
  end

  def calm_down(%Mobile{hate: hate, room_id: room_id} = mobile) do
    mobiles_in_room = ApathyDrive.PubSub.subscribers("rooms:#{room_id}:mobiles")
                      |> Enum.into(HashSet.new)

    hate = hate
           |> Map.keys
           |> Enum.into(HashSet.new)
           |> HashSet.difference(mobiles_in_room)
           |> Enum.reduce(hate, fn(enemy, new_hate) ->
                current = Map.get(new_hate, enemy)
                if current > 5 do
                  Map.put(new_hate, enemy, current - 5)
                else
                  Map.delete(new_hate, enemy)
                end
              end)

    Map.put(mobile, :hate, hate)
  end

  def heal(%Mobile{spirit: nil, hp: hp, max_hp: max_hp, spirit: nil} = mobile) do
    unless Ability.on_global_cooldown?(mobile) do
      chance = trunc((max_hp - hp) / max_hp * 100)

      roll = :random.uniform(100)

      if chance > roll do
        ability = mobile
                  |> Ability.heal_abilities
                  |> random_ability

        if ability do
          send(self, {:execute_ability, ability})
          mobile
        end
      end
    end
  end
  def heal(%Mobile{}), do: nil

  def bless(%Mobile{spirit: nil} = mobile) do
    unless Ability.on_global_cooldown?(mobile) do
      ability = mobile
                |> Ability.bless_abilities
                |> random_ability

      if ability do
        send(self, {:execute_ability, ability})
        mobile
      end
    end
  end
  def bless(%Mobile{}), do: nil

  def attack(%Mobile{spirit: nil} = mobile) do
    if target = Mobile.aggro_target(mobile) do

      attack = cond do
        !Ability.on_global_cooldown?(mobile) ->
           mobile
           |> Ability.attack_abilities
           |> random_ability
        true ->
          nil
      end

      if attack do
        send(self, {:execute_ability, attack, [target]})
        mobile
        |> Mobile.set_attack_target(target)
        |> Mobile.initiate_combat
      else
        mobile
        |> Mobile.set_attack_target(target)
        |> Mobile.initiate_combat
      end
    end
  end
  def attack(%{spirit: _} = mobile) do
    if target = Mobile.aggro_target(mobile) do

      mobile
      |> Mobile.set_attack_target(target)
      |> Mobile.initiate_combat
    end
  end

  def random_ability(abilities) do
    case abilities do
      [ability] ->
        ability
      [] ->
        nil
      abilities ->
        abilities |> Enum.random
    end
  end

  def move(%Monster{spirit: nil} = monster) do
    if !Monster.on_ai_move_cooldown?(monster) && !Monster.aggro_target(monster) do

      room = Monster.find_room(monster)
      roll = :random.uniform(100)

      if room && (roll < trunc(monster.chance_to_follow / 5)) do
        direction = Room.random_direction(room)

        if direction do
          ApathyDrive.Command.execute(monster, direction, [])
        end
      end
    end
  end
  def move(%Monster{}), do: nil

end
