defmodule Systems.Level do

  def exp_to_next_level(entity) do
    exp_at_level(Components.Level.value(entity) + 1) - Components.Experience.value(entity)
  end

  def exp_for_level(1), do: 0
  def exp_for_level(lvl) do
    ((1 + :math.pow(lvl - 2, 1.50 + (lvl / 75.0))) * 100000 / 150)
    |> trunc
  end

  def exp_at_level(0), do: nil
  def exp_at_level(level) do
    (1..level)
    |> Enum.reduce(0, fn(lvl, total) ->
         total + exp_for_level(lvl)
       end)
  end

end
