defmodule ApathyDrive.Commands.Craft do
  use ApathyDrive.Command

  alias ApathyDrive.{
    Ability,
    Character,
    CharacterStyle,
    CraftingRecipe,
    Enchantment,
    Item,
    ItemInstance,
    ItemTrait,
    Match,
    Material,
    Mobile,
    Repo
  }

  require Ecto.Query

  def keywords, do: ["craft"]

  def execute(%Room{} = room, %Character{} = character, []) do
    display_crafts(character)
    room
  end

  def execute(%Room{} = room, %Character{} = character, ["list"]) do
    display_crafts(character)
    room
  end

  def execute(%Room{} = room, %Character{} = character, ["level", level | item]) do
    case Integer.parse(level) do
      {level, ""} ->
        level = min(level, 50)

        item_name = Enum.join(item, " ")

        character
        |> CharacterStyle.for_character()
        |> Ecto.Query.preload(:item)
        |> Repo.all()
        |> Enum.map(&Map.put(&1.item, :keywords, Match.keywords(&1.item.name)))
        |> Match.all(:keyword_starts_with, item_name)
        |> case do
          nil ->
            Mobile.send_scroll(character, "<p>You do not know how to craft #{item_name}.</p>")

            room

          %Item{} = item ->
            item = Map.put(item, :traits, ItemTrait.load_traits(item.id))

            recipe =
              item
              |> Map.put(:level, level)
              |> CraftingRecipe.for_item()
              |> Repo.preload(:skill)

            material = Repo.get(Material, recipe.material_id)

            min_level = Systems.Effect.effect_bonus(item, "MinLevel")

            if min_level && min_level > level do
              Mobile.send_scroll(
                character,
                "<p>#{Item.colored_name(item, character: character)} must be at least level #{
                  min_level
                }.</p>"
              )

              room
            else
              if character.materials[material.name] &&
                   character.materials[material.name].amount >=
                     recipe.material_amount do
                if item.weight <=
                     Character.max_encumbrance(character) - Character.encumbrance(character) do
                  character.materials[material.name]
                  |> Ecto.Changeset.change(%{
                    amount: character.materials[material.name].amount - recipe.material_amount
                  })
                  |> Repo.update!()

                  instance =
                    %ItemInstance{
                      item_id: item.id,
                      level: level,
                      character_id: character.id,
                      equipped: false,
                      hidden: false,
                      dropped_for_character_id: character.id
                    }
                    |> Repo.insert!()

                  item =
                    instance
                    |> Map.put(:item, item)
                    |> Item.from_assoc()

                  character
                  |> Mobile.send_scroll(
                    "<p>You set aside #{recipe.material_amount} #{material.name} to craft a #{
                      Item.colored_name(item, character: character)
                    }.</p>"
                  )

                  room = Ability.execute(room, character.ref, nil, item)

                  item = Enchantment.load_enchantments(item)

                  room
                  |> Room.update_mobile(character.ref, fn _room, char ->
                    char
                    |> Character.load_materials()
                    |> update_in([:inventory], &[item | &1])
                  end)
                else
                  Mobile.send_scroll(
                    character,
                    "<p>#{Item.colored_name(item, character: character)} is too heavy.</p>"
                  )

                  room
                end
              else
                Mobile.send_scroll(
                  character,
                  "<p>You don't have the required #{recipe.material_amount} #{material.name}.</p>"
                )

                room
              end
            end

          matches ->
            Mobile.send_scroll(
              character,
              "<p><span class='red'>Please be more specific. You could have meant any of these:</span></p>"
            )

            Enum.each(matches, fn match ->
              Mobile.send_scroll(
                character,
                "<p>-- #{Item.colored_name(match, character: character)}</p>"
              )
            end)

            room
        end

      _ ->
        Mobile.send_scroll(
          character,
          "<p><span class='red'>Syntax: craft level {level} {item}</span></p>"
        )

        room
    end
  end

  def execute(%Room{} = room, %Character{} = character, unfinished_item) do
    item_name = Enum.join(unfinished_item, " ")

    character.inventory
    |> Enum.filter(& &1.unfinished)
    |> Match.one(:name_contains, item_name)
    |> case do
      nil ->
        Mobile.send_scroll(character, "<p>You do not have an unfinished #{item_name}.</p>")
        room

      %Item{} = item ->
        Ability.execute(room, character.ref, nil, item)

      matches ->
        Mobile.send_scroll(
          character,
          "<p><span class='red'>Please be more specific. You could have meant any of these:</span></p>"
        )

        Enum.each(matches, fn match ->
          Mobile.send_scroll(
            character,
            "<p>-- #{Item.colored_name(match, character: character)}</p>"
          )
        end)

        room
    end
  end

  def display_crafts(%Character{} = character) do
    Mobile.send_scroll(
      character,
      "<p><span class='white'>You know how to craft following items:</span></p>"
    )

    Mobile.send_scroll(
      character,
      "<p><span class='dark-magenta'>Skill         Material      Worn On</span></p>"
    )

    styles =
      character
      |> CharacterStyle.for_character()
      |> Repo.all()

    character.skills
    |> Enum.map(fn {skill_name, %{skill_id: id}} ->
      Enum.map(CraftingRecipe.types_for_skill(id), fn columns ->
        [skill_name | columns]
      end)
    end)
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.each(fn recipes_for_skill ->
      Enum.each(recipes_for_skill, fn recipe ->
        case recipe |> List.flatten() |> Enum.reject(&is_nil/1) do
          [skill, "Armour", subtype, worn_on] ->
            styles
            |> Enum.filter(
              &(&1.item.type == "Armour" and &1.item.armour_type == subtype and
                  &1.item.worn_on == worn_on)
            )
            |> Enum.map(&[&1.item.type, &1.item.armour_type, &1.item.worn_on, &1])
            |> Enum.group_by(&Enum.slice(&1, 0..2))
            |> Enum.each(fn {[_type, subtype, worn_on], styles} ->
              styles =
                styles
                |> Enum.map(&List.last/1)
                |> Enum.map(fn %{item: item} ->
                  Map.put(item, :traits, ItemTrait.load_traits(item.id))
                end)
                |> Enum.sort_by(& &1.traits["Quality"])
                |> Enum.map(&Item.colored_name(&1, character: character))

              Mobile.send_scroll(
                character,
                "<p><span class='dark-cyan'>#{String.pad_trailing(skill, 13)} #{
                  String.pad_trailing(subtype, 13)
                } #{String.pad_trailing(worn_on, 13)}</span></p>"
              )

              Mobile.send_scroll(
                character,
                "<p>  #{ApathyDrive.Commands.Inventory.to_sentence(styles)}</p>"
              )
            end)

          [skill, "Weapon", subtype, worn_on] ->
            styles
            |> Enum.filter(
              &(&1.item.type == "Weapon" and &1.item.weapon_type == subtype and
                  &1.item.worn_on == worn_on)
            )
            |> Enum.map(
              &[
                &1.item.type,
                &1.item.weapon_type,
                &1.item.worn_on,
                Item.colored_name(&1.item, character: character)
              ]
            )
            |> Enum.group_by(&Enum.slice(&1, 0..2))
            |> Enum.each(fn {[_type, subtype, worn_on], styles} ->
              styles = Enum.map(styles, &List.last/1)

              Mobile.send_scroll(
                character,
                "<p><span class='dark-cyan'>#{String.pad_trailing(skill, 13)} #{
                  String.pad_trailing(subtype, 13)
                } #{String.pad_trailing(worn_on, 13)}</span></p>"
              )

              Mobile.send_scroll(
                character,
                "<p>  #{ApathyDrive.Commands.Inventory.to_sentence(styles)}</p>"
              )
            end)
        end
      end)
    end)
  end
end
