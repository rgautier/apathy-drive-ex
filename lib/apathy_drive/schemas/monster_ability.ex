defmodule ApathyDrive.MonsterAbility do
  use ApathyDriveWeb, :model

  alias ApathyDrive.{
    Ability,
    AbilityDamageType,
    AbilityTrait,
    Monster,
    MonsterAbility
  }

  schema "monsters_abilities" do
    belongs_to(:monster, Monster)
    belongs_to(:ability, Ability)

    field(:chance, :integer)
  end

  def load_abilities(%Monster{id: id} = monster) do
    load_abilities(monster, id)
  end

  def load_abilities(entity, id) do
    monster_abilities =
      MonsterAbility
      |> Ecto.Query.where(monster_id: ^id)
      |> Ecto.Query.preload([:ability])
      |> Repo.all()

    abilities =
      Enum.reduce(monster_abilities, %{}, fn %{
                                               ability: %Ability{id: id} = ability,
                                               chance: chance
                                             },
                                             abilities ->
        ability =
          put_in(ability.traits, AbilityTrait.load_traits(id))
          |> Map.put(:chance, chance)

        ability =
          case AbilityDamageType.load_damage(id) do
            [] ->
              ability

            damage ->
              ability = update_in(ability.traits, &Map.put(&1, "Damage", damage))

              crit_types = Enum.map(ability.traits["Damage"], & &1.damage_type_id)

              Map.put(ability, :crit_tables, crit_types)
          end

        Map.put(abilities, ability.command || ability.id, ability)
      end)

    Map.put(entity, :abilities, abilities)
  end
end
