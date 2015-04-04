defmodule Item do
  require Logger
  use Ecto.Model
  alias ApathyDrive.Repo
  alias ApathyDrive.PubSub

  schema "items" do
    field :name,                  :string,  virtual: true
    field :description,           :string,  virtual: true
    field :keywords,              {:array, :string}, virtual: true
    field :equipped,              :boolean, default: false
    field :worn_on,               :string,  virtual: true
    field :required_skills,       :any,     virtual: true, default: nil
    field :cost,                  :integer, virtual: true
    field :pid,                   :any,     virtual: true
    field :effects,               :any,     virtual: true, default: %{}
    field :timers,                :any,     virtual: true, default: %{}
    field :light,                 :integer, virtual: true
    field :always_lit,            :boolean, virtual: true
    field :uses,                  :integer
    field :destruct_message,      :string,  virtual: true
    field :room_destruct_message, :string,  virtual: true
    field :can_pick_up,           :boolean, virtual: true
    field :ac,                    :integer, virtual: true
    field :properties,            :any,     virtual: true
    field :hit_verbs,             {:array, :string}, virtual: true
    field :accuracy_skill,        :string,  virtual: true
    field :weight,                :integer, virtual: true
    field :speed,                 :integer, virtual: true

    timestamps

    belongs_to :room,    Room
    belongs_to :monster, Monster
    belongs_to :item_template, ItemTemplate
  end

  def insert(%Item{id: nil} = item) do
    ApathyDrive.Repo.insert(item)
  end
  def insert(%Item{} = item), do: item

  def save(%Item{id: id} = item) when is_integer(id) do
    Repo.update(item)
  end
  def save(%Item{} = item), do: item

  def delete(%Item{} = item), do: Repo.delete(item)

  def load(id) do
    case Repo.one from i in Item, where: i.id == ^id do
      %Item{} = item ->

        it = item.item_template_id
             |> ItemTemplate.find
             |> ItemTemplate.value

        item = Map.merge(it, item, fn(_key, it_val, item_val) ->
                    item_val || it_val
                  end)
                  |> Map.from_struct
                  |> Enum.into(Keyword.new)

        item = struct(Item, item)

        # if item.always_lit do
        #   room_id = if item.room_id do
        #     item.room_id
        #   else
        #     monster = item.monster_id
        #               |> Monster.find
        #               |> Monster.value
        #     monster.room_id
        #   end
        # 
        #   Item.light(pid, room_id)
        # end

        item
      nil ->
        nil
    end
  end

  def find_room(%Item{room_id: room_id}) do
    room_id
    |> Room.find
    |> Room.value
  end

  def set_room_id(%Item{} = item, room_id) do
    PubSub.unsubscribe(self, "rooms:#{item.room_id}")
    PubSub.unsubscribe(self, "rooms:#{item.room_id}:items")
    PubSub.subscribe(self, "rooms:#{room_id}")
    PubSub.subscribe(self, "rooms:#{room_id}:items")
    Map.put(item, :room_id, room_id)
  end

  def light(item, room_id \\ nil) do
    GenServer.call(item, {:light, room_id})
  end

  def extinguish(item, room_id \\ nil) do
    GenServer.call(item, {:extinguish, room_id})
  end

  def lit?(%Item{effects: effects}) do
    effects
    |> Map.values
    |> Enum.any?(fn(effect) ->
         Map.has_key?(effect, "light")
       end)
  end

  def handle_call(:value, _from, monster) do
    {:reply, monster, monster}
  end

  def handle_call({:light, room_id}, from, item) do
    cond do
      !item.light ->
        {:reply, :not_a_light, item}
      lit?(item) ->
        {:reply, :already_lit, item}
      !!item.uses ->
        TimerManager.call_every(item, {:light, 1000, fn ->
          send(self, :use)
        end})
        item = Systems.Effect.add(item, %{"light" => item.light, "timers" => [:light]})

        if room_id do
          ApathyDrive.PubSub.subscribe(self, "rooms:#{room_id}:lights")
        end

        {:reply, item, item}
      true ->
        item = Systems.Effect.add(item, %{"light" => item.light})
        {:reply, item, item}
    end
  end

  def handle_call({:extinguish, room_id}, _from, item) do
    cond do
      !item.light ->
        {:reply, :not_a_light, item}
      !lit?(item) ->
        {:reply, :not_lit, item}
      item.always_lit ->
        if !!item.destruct_message do
          monster = Monster.find(item.monster_id)

          send(monster, {:item_destroyed, item})
          send(self, :delete)

          {:reply, item, item}
        else
          {:reply, :always_lit, item}
        end
      true ->
        item = Systems.Effect.remove(item, :light)
        if room_id do
          ApathyDrive.PubSub.unsubscribe(self, "rooms:#{room_id}:lights")
        end
        {:reply, item, item}
    end
  end

  def handle_call({:to_monster_inventory, %Monster{} = monster}, _from, item) do
    ApathyDrive.PubSub.unsubscribe(self, "monsters:#{item.monster_id}:inventory")
    ApathyDrive.PubSub.unsubscribe(self, "monsters:#{item.monster_id}:equipped_items")
    ApathyDrive.PubSub.unsubscribe(self, "monsters:#{item.monster_id}:equipped_items:#{item.worn_on}")
    ApathyDrive.PubSub.unsubscribe(self, "rooms:#{item.room_id}:items")

    ApathyDrive.PubSub.subscribe(self, "monsters:#{monster.id}:items")
    ApathyDrive.PubSub.subscribe(self, "monsters:#{monster.id}:inventory")

    if lit?(item) do
      ApathyDrive.PubSub.subscribe(self, "rooms:#{monster.room_id}:lights")
    end

    item = item
           |> Map.put(:monster_id, monster.id)
           |> Map.put(:room_id, nil)
           |> save

    {:reply, self, item}
  end

  def handle_call({:to_room, %Room{} = room}, _from, item) do
    ApathyDrive.PubSub.unsubscribe(self, "monsters:#{item.monster_id}:items")
    ApathyDrive.PubSub.unsubscribe(self, "monsters:#{item.monster_id}:inventory")
    ApathyDrive.PubSub.unsubscribe(self, "monsters:#{item.monster_id}:equipped_items")
    ApathyDrive.PubSub.unsubscribe(self, "monsters:#{item.monster_id}:equipped_items:#{item.worn_on}")
    ApathyDrive.PubSub.unsubscribe(self, "rooms:#{item.room_id}:items")

    ApathyDrive.PubSub.subscribe(self, "rooms:#{room.id}:items")

    item = item
           |> Map.put(:monster_id, nil)
           |> Map.put(:room_id, room.id)
           |> save

    {:reply, self, item}
  end

  def handle_info(:use, %Item{uses: 0, monster_id: nil} = item) do
    send(self, :delete)

    {:noreply, item}
  end

  def handle_info(:use, %Item{uses: 0, room_id: nil} = item) do
    monster = Monster.find(item.monster_id)

    send(monster, {:item_destroyed, item})
    send(self, :delete)

    {:noreply, item}
  end

  def handle_info(:use, %Item{uses: uses} = item) do
    item = item
           |> Map.put(:uses, uses - 1)
           |> save

    {:noreply, item}
  end

  def handle_info({:timeout, _ref, {name, time, function}}, %Item{timers: timers} = item) do
    jitter = trunc(time / 2) + :random.uniform(time)

    new_ref = :erlang.start_timer(jitter, self, {name, time, function})

    timers = Map.put(timers, name, new_ref)

    TimerManager.execute_function(function)

    {:noreply, Map.put(item, :timers, timers)}
  end

  def handle_info({:timeout, _ref, {name, function}}, %Item{timers: timers} = item) do
    TimerManager.execute_function(function)

    timers = Map.delete(timers, name)

    {:noreply, Map.put(item, :timers, timers)}
  end

  def handle_info({:remove_effect, key}, item) do
    item = Systems.Effect.remove(item, key)
    {:noreply, item}
  end

  def handle_info({:apply_ability, %Ability{} = ability, %Monster{} = ability_user}, item) do
    item = Ability.apply_ability(item, ability, ability_user)

    {:noreply, item}
  end

  def handle_info(:delete, item) do
    delete(item)

    Process.exit(self, :normal)
    {:noreply, item}
  end

  def handle_info(_message, monster) do
    {:noreply, monster}
  end

end
