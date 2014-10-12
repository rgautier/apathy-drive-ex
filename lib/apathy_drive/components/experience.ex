defmodule Components.Experience do
  use Systems.Reload
  use GenEvent

  ### Public API
  def value(entity) do
    GenEvent.call(entity, Components.Experience, :value)
  end

  def value(entity, new_value) do
    GenEvent.notify(entity, {:set_experience, new_value})
  end

  def add(entity, amount) do
    GenEvent.call(entity, Components.Experience, {:add_exp, amount})
    Systems.Level.advance(entity)
  end

  def serialize(entity) do
    %{"Experience" => value(entity)}
  end

  ### GenEvent API
  def init(value) do
    {:ok, value}
  end

  def handle_call(:value, value) do
    {:ok, value, value}
  end

  def handle_call({:add_exp, amount}, value) do
    new_exp = value + amount
    {:ok, new_exp, new_exp}
  end

  def handle_event({:set_experience, new_value}, _value) do
    {:ok, new_value }
  end

  def handle_event(_, current_value) do
    {:ok, current_value}
  end

end
