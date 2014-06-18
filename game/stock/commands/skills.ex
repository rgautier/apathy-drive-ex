defmodule Commands.Skills do
  use Systems.Command

  def keywords, do: ["skills"]

  def execute(entity, arguments) do
    if Components.Spirit.value(entity) do
      Components.Player.send_message(entity, ["scroll", "<p>You need a body to do that.</p>"])
    else
      arguments = Enum.join(arguments, " ")
      Components.Player.send_message(entity, ["scroll", "<p><span class='white'>Your skills are:</span></p>"])
      Components.Player.send_message(entity, ["scroll", "<p><span class='blue'>---------------------------------------------------------------------------</span></p>"])
      skill_names = Components.Skills.value(entity) |> Map.keys |> Enum.sort
      chunks = get_chunks(skill_names)
      Enum.each chunks, &display_skills(entity, &1, arguments)
    end
  end

  defp display_skills(entity, [skill1, skill2], arguments) do
    Components.Player.send_message(entity, ["scroll", "<p>#{skilltext(entity, skill1, arguments)} #{skilltext(entity, skill2, arguments)}</p>"])
  end

  defp display_skills(entity, [skill], arguments) do
    Components.Player.send_message(entity, ["scroll", "<p>#{skilltext(entity, skill, arguments)}</p>"])
  end

  defp skilltext(entity, skill, "base") do
    base_skill_rating = Skills.find(skill).base(entity)
    modified_skill_rating = Skills.find(skill).modified(entity)
    skill_difference = modified_skill_rating - base_skill_rating
    skill_mod = if skill_difference >= 0 do
                   String.ljust("(+#{skill_difference})", 6)
                 else
                   String.ljust("(#{skill_difference})", 6)
                 end

    String.ljust("#{String.ljust(skill, 24)}#{String.rjust("#{base_skill_rating}", 4)}% #{skill_mod}", 36)
  end

  defp skilltext(entity, skill, _arguments) do
    skill_rating = Skills.find(skill).modified(entity)
    String.ljust("#{String.ljust(skill, 24)}#{String.rjust("#{skill_rating}", 4)}%", 36)
  end

  defp get_chunks([]), do: []
  defp get_chunks(skills) do
    chunks = Enum.chunk(skills, 2)
    last_skill = skills |> List.last
    if List.flatten(chunks) |> Enum.member?(last_skill) do
      chunks
    else
      [[last_skill] | chunks |> Enum.reverse] |> Enum.reverse
    end
  end
end
