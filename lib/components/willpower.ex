defmodule Components.Willpower do
  use GenEvent.Behaviour

  ### Public API
  def value(entity) do
    :gen_event.call(entity, Components.Willpower, :value)
  end

  def serialize(entity) do
    {"Willpower", value(entity)}
  end

  ### GenEvent API
  def init(value) do
    {:ok, value}
  end

  def handle_call(:value, value) do
    {:ok, value, value}
  end

  def handle_cast({:set_value, value}, _value) do
    {:noreply, value }
  end
end
