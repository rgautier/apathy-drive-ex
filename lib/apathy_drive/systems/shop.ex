defmodule Systems.Shop do
  use Systems.Reload
  import Utility
  import Systems.Text

  def list(spirit, nil, room) do
    send_message(spirit, "scroll", "<p><span class='dark-green'>Item</span>                          <span class='dark-cyan'>Price (Experience)</span></p>")
    send_message(spirit, "scroll", "<p><span class='dark-cyan'>─────────────────────────────────────────────────────────────────</span></p>")
    Enum.each(Components.Shop.value(room), fn(item_hash) ->
      it = ItemTemplates.find_by_id(item_hash["item"])
      item_name = Components.Name.value(it)
      value = Components.Module.value(it).value
      cost = case value do
        0 ->
          "Free"
        amount ->
          amount
      end
      send_message(spirit, "scroll", "<p><span class='dark-green'>#{String.ljust(item_name, 30)}</span><span class='dark-cyan'>#{cost}</span></p>")
    end)
  end

  def list(spirit, monster, room) do
    send_message(spirit, "scroll", "<p><span class='dark-green'>Item</span>                          <span class='dark-cyan'>Price (Experience)</span>       <span class='dark-cyan'>Required Skill</span></p>")
    send_message(spirit, "scroll", "<p><span class='dark-cyan'>───────────────────────────────────────────────────────────────────────────</span></p>")
    Enum.each(Components.Shop.value(room), fn(item_hash) ->
      it = ItemTemplates.find_by_id(item_hash["item"])
      item_name = it |> Components.Name.value
      value = Components.Module.value(it).value
      cost = case value do
        0 ->
          "Free"
        amount ->
          amount
      end

      case Systems.Item.skill_too_low(monster, it) do
        {skill_name, requirement} ->
          send_message(spirit, "scroll", "<p><span class='dark-green'>#{String.ljust(to_string(item_name), 30)}</span><span class='dark-cyan'>#{String.ljust(to_string(cost), 25)}</span><span class='dark-cyan'>#{requirement} #{skill_name}</span></p>")
        _ ->
          send_message(spirit, "scroll", "<p><span class='dark-green'>#{String.ljust(item_name, 30)}</span><span class='dark-cyan'>#{cost}</span></p>")
      end
    end)
  end

  def buy(character, room, item) do
    cond do
      !Entity.has_component?(room, Components.Shop) ->
        send_message(character, "scroll", "<p><span class='red'>You cannot BUY if you are not in a shop!</span></p>")
      true ->
        case Systems.Match.all(Components.Shop.items(room), :name_contains, item) do
          [match] ->
            spirit = Possession.possessor(character)
            value  = Components.Module.value(match).value
            exp    = Components.Experience.value(spirit)

            if value > exp do
              send_message(character, "scroll", "<p>#{Components.Name.value(match) |> capitalize_first} costs #{value} experience, you only have #{exp}.</p>")
            else
              Components.Experience.add(spirit, -value)
              Systems.Item.spawn_item(match, character)
              send_message(character, "scroll", "<p>You purchase #{Components.Name.value(match)} for #{value} experience.</p>")
            end
          [] ->
            send_message(character, "scroll", "<p>\"#{item}\" does not appear to be for sale here.</p>")
          matches ->
            match_names = matches |> Enum.map &(Components.Name.value(&1))
            send_message(character, "scroll", "<p><span class='red'>Please be more specific. You could have meant any of these:</span></p>")
            Enum.each match_names, fn(match_name) ->
              send_message(character, "scroll", "<p>-- #{match_name}</p>")
            end
        end
    end
  end

  def sell(monster, room, item) do
    cond do
      !Entity.has_component?(room, Components.Shop) ->
        send_message(monster, "scroll", "<p><span class='red'>You cannot SELL if you are not in a shop!</span></p>")
      true ->
        case Systems.Match.all(Components.Items.get_items(monster), :name_contains, item) do
          [match] ->
            spirit = Possession.possessor(monster)

            if spirit do
              exp = trunc(Components.Module.value(match).value / 10)
              Components.Experience.add(spirit, exp)
              Entities.save!(spirit)
              send_message(spirit, "scroll", "<p>You just sold #{Components.Name.value(match)} for #{exp} experience.</p>")
            end
            Components.Items.remove_item(monster, match)
            Entities.save!(monster)
            Entities.delete!(match)
          [] ->
            send_message(monster, "scroll", "<p>You don't have \"#{item}\" to sell!</p>")
          matches ->
            match_names = matches |> Enum.map &(Components.Name.value(&1))
            send_message(monster, "scroll", "<p><span class='red'>Please be more specific. You could have meant any of these:</span></p>")
            Enum.each match_names, fn(match_name) ->
              send_message(monster, "scroll", "<p>-- #{match_name}</p>")
            end
        end
    end
  end
end
