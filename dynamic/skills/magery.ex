defmodule Skills.Magery do
  use Systems.Skill

  def prereqs, do: []
  def cost,    do: 2.3
  def level,   do: 1

  def help do
    "This is a general magic skill which allows casting of spells dealing with protection, summoning, magical attack, and some miscellaneous spells."
  end
end
