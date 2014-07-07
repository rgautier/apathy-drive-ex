defmodule Systems.Description do
  use Systems.Reload
  import Utility

  @attribute_descriptions [
    strength:  ["puny", "weak", "slightly built", "moderately built", "well built", "muscular", "powerfully built", "heroically proportioned", "Herculean", "physically Godlike"],
    health:    ["frail", "thin", "healthy", "stout", "solid", "massive", "gigantic", "colossal"],
    agility:   ["slowly", "clumsily", "slugishly", "cautiously", "gracefully", "very swiftly", "with uncanny speed", "with catlike agility", "blindingly fast"],
    charm:     ["openly hostile and quite revolting.", "hostile and unappealing.", "quite unfriendly and aloof.", "likeable in an unassuming sort of way.", "quite attractive and pleasant to be around.", "charismatic and outgoing. You can't help but like {{him/her}}.", "extremely likeable, and fairly radiates charisma.", "incredibly charismatic. You are almost overpowered by {{his/her}} strong personality.", "overwhelmingly charismatic. You almost drop to your knees in wonder at the sight of {{him/her}}!"],
    intellect: ["utterly moronic", "quite stupid", "slightly dull", "intelligent", "bright", "extremely clever", "brilliant", "a genius", "all-knowing"],
    willpower: ["selfish and hot-tempered", "sullen and impulsive", "a little naive", "looks fairly knowledgeable", "looks quite experienced and wise", "has a worldly air about him", "seems to possess a wisdom beyond his years", "seems to be in an enlightened state of mind", "looks like he is one with the Gods"]
  ]

  def interpolate(string, character) do
    case Components.Gender.value(character) do
      "male"   ->
        String.replace(string, ~r/\{\{(.+?)\/(.+?)\}\}/, "\\1")
      "female" ->
        String.replace(string, ~r/\{\{(.+?)\/(.+?)\}\}/, "\\2")
    end
  end

  def add_description_to_scroll(character, target) do
    if Entity.list_components(target) |> Enum.member?(Components.Description) do
      send_message character, "scroll", "<p><span class='cyan'>#{Components.Name.value(target)}</span></p>"
      send_message character, "scroll", "<p>#{Components.Description.value(target)}</p>"
    else
      add_character_description_to_scroll(character, target)
    end
  end

  def add_character_description_to_scroll(character, target) do
    send_message character, "scroll", "<p><span class='cyan'>#{Components.Name.get_name(target)}</span></p>"
    send_message character, "scroll", "<p>#{describe_character(target) |> interpolate(%{"user" => target})}</span></p>"
  end

  def describe_character(character) do
    name        = Components.Name.get_name(character)
    race_name   = Components.Race.value(character)  |> Components.Name.get_name
    eye_color   = Components.EyeColor.value(character)
    strength    = describe_stat(character, "strength")
    health      = describe_stat(character, "health")
    agility     = describe_stat(character, "agility")
    charm       = describe_stat(character, "charm")
    intellect   = describe_stat(character, "intellect")
    willpower   = describe_stat(character, "willpower")
    hair        = describe_hair(character)
    hp          = describe_hp(character)
    "#{name} is a #{health}, #{strength} #{race_name} with #{hair} and #{eye_color} eyes. {{He/She}} moves #{agility}, and is #{charm} #{name} appears to be #{intellect} and #{willpower}. #{hp}"
  end

  def describe_hair(character) do
    hair_length = Components.HairLength.value(character)
    hair_color  = Components.HairColor.value(character)
    case hair_length do
      "none" ->
        "a bald head"
       _ ->
         "#{hair_length} #{hair_color} hair"
    end
  end

  def describe_hp(character) do
    percentage = round(100 * (Components.HP.value(character) / Systems.HP.max_hp(character)))
    description = case percentage do
      _ when percentage >= 100 ->
        "unwounded"
      _ when percentage >= 90 ->
        "slightly wounded"
      _ when percentage >= 60 ->
        "moderately wounded"
      _ when percentage >= 40 ->
        "heavily wounded"
      _ when percentage >= 20 ->
        "severely wounded"
      _ when percentage >= 10 ->
        "critically wounded"
      _ ->
        "very critically wounded"
    end
    "{{He/She}} is #{description}."
  end

  def describe_stat(character, stat_name) do
    stat = Systems.Stat.modified(character, stat_name)
    race = Components.Race.value(character)
    starting_stat = Systems.Stat.base(character, stat_name)
    difference = stat - starting_stat
    index = round(difference / 10)
    list_size = @attribute_descriptions[:"#{stat_name}"] |> Enum.count
    if index > list_size - 1 do
      {:ok, description } = @attribute_descriptions[:"#{stat_name}"] |> Enum.fetch(list_size - 1)
    else
      {:ok, description } = @attribute_descriptions[:"#{stat_name}"] |> Enum.fetch(index)
    end
    description
  end
end