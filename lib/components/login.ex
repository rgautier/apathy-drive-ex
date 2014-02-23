defmodule Components.Login do
  use GenEvent.Behaviour

  ### Public API
  def get_step(player) do
    :gen_event.call(player, Components.Login, :get_step)
  end

  def intro(player) do
    ApathyDrive.Entity.notify(player, {:intro})
    Players.send_message(player, ["scroll", "<p>Please enter your email address to log in or 'new' to create a new account: <input id='email' class='prompt'></input></p>"])
    Players.send_message(player, ["focus", "#email"])
  end

  def create_account_request_email(player) do
    ApathyDrive.Entity.notify(player, :create_account_request_email)
    Players.send_message(player, ["scroll", "<p>Please enter the email address you would like to use: <input id='email' class='prompt'></input></p>"])
    Players.send_message(player, ["focus", "#email"])
  end

  def sign_in_get_account(player, email) do
    ApathyDrive.Entity.notify(player, {:sign_in_set_email, email})
    Players.send_message(player, ["scroll", "<p>Please enter your password: <input id='password' type='password' class='prompt'></input></p>"])
    Players.send_message(player, ["focus", "#password"])
  end

  def sign_in_check_password(player, password) do
    email = :gen_event.call(player, Components.Login, :get_email)
    account = ApathyDrive.Account.find(email, password)
    if account do
      Players.send_message(player, ["scroll", "<p>Welcome back!</p>"])
      display_character_select(player, account)
    else
      Players.send_message(player, ["scroll", "<p>Invalid username/password!</p>"])
      intro(player)
    end
  end

  def display_character_select(player, account) do
    ApathyDrive.Entity.notify(player, {:sign_in_set_account, account})
    Players.send_message(player, ["scroll", "<p><span class='dark-yellow underline'>Characters</span></p>"])
    Players.send_message(player, ["scroll", "\n\n\n\n<p><span class='dark-red'>N</span> <span class='dark-green'>:</span> <span class='dark-yellow'>New Character</span></p>"])
    Players.send_message(player, ["scroll", "<p><span class='dark-yellow'>Please enter your selection:</span> <input id='character' class='prompt'></input></p>"])
    Players.send_message(player, ["focus", "#character"])
  end

  def display_race_select(player) do
    ApathyDrive.Entity.notify(player, :create_character_request_race)
    Players.send_message(player, ["scroll", "<p><span class='white'>Please choose a race from the following list:</span></p>"])
    Enum.sort(Races.all, &(Components.Number.get_number(&1) < Components.Number.get_number(&2)))
    |> Enum.each fn(race) ->
      Players.send_message(player, ["scroll", "<p><span class='dark-grey'>[</span><span class='white'>#{Components.Number.get_number(race)}</span><span class='dark-grey'>]</span> #{Components.Name.get_name(race)}</p>"])
    end
    prompt_for_race(player)
  end

  def prompt_for_race(player) do
    Players.send_message(player, ["scroll", "\n\n<p><span class='dark-green'>Please choose your race [ 'help &lt;race&gt;' for more info ]: </span><input id='race' class='prompt'></input></p>"])
    Players.send_message(player, ["focus", "#race"])
  end

  def prompt_for_class(player) do
    Players.send_message(player, ["scroll", "\n\n<p><span class='dark-green'>Please choose your class [ 'help &lt;class&gt;' for more info ]: </span><input id='class' class='prompt'></input></p>"])
    Players.send_message(player, ["focus", "#class"])
  end

  def display_class_select(player) do
    ApathyDrive.Entity.notify(player, :create_character_request_class)
    Players.send_message(player, ["scroll", "<p><span class='white'>Please choose a class from the following list:</span></p>"])
    Enum.sort(Classes.all, &(Components.Number.get_number(&1) < Components.Number.get_number(&2)))
    |> Enum.each fn(class) ->
      Players.send_message(player, ["scroll", "<p><span class='dark-grey'>[</span><span class='white'>#{Components.Number.get_number(class)}</span><span class='dark-grey'>]</span> #{Components.Name.get_name(class)}</p>"])
    end
    prompt_for_class(player)
  end

  def create_character_set_race(player, race_number) do
    if Regex.match?(%r/^\d+$/, race_number) do
      {number, _} = Integer.parse(race_number)
      race = Races.find_by_number(number)
      if race do
        ApathyDrive.Entity.notify(player, {:create_character_set_race, race})
        display_class_select(player)
      else
        Players.send_message(player, ["scroll", "There is no race with that number."])
      end
    else
      Components.Login.display_race_select(player)
    end
  end

  def create_character_set_class(player, class_number) do
    if Regex.match?(%r/^\d+$/, class_number) do
      {number, _} = Integer.parse(class_number)
      class = Classes.find_by_number(number)
      if class do
        race = get_race(player)
        {:ok, character} = ApathyDrive.Entity.init
        ApathyDrive.Entity.add_component(character, Components.Agility,   Components.Agility.value(race))
        ApathyDrive.Entity.add_component(character, Components.Charm,     Components.Charm.value(race))
        ApathyDrive.Entity.add_component(character, Components.Health,    Components.Health.value(race))
        ApathyDrive.Entity.add_component(character, Components.Intellect, Components.Intellect.value(race))
        ApathyDrive.Entity.add_component(character, Components.Strength,  Components.Strength.value(race))
        ApathyDrive.Entity.add_component(character, Components.Willpower, Components.Willpower.value(race))
        ApathyDrive.Entity.add_component(character, Components.CP, 100)
        ApathyDrive.Entity.add_component(character, Components.Class, class)
        ApathyDrive.Entity.add_component(character, Components.Race, race)

        Systems.Training.train_stats(player, character)
      else
        Players.send_message(player, ["scroll", "There is no class with that number."])
      end
    else
      Components.Login.display_class_select(player)
    end
  end

  def create_account_set_email(player, email) do
    account = ApathyDrive.Account.find(email)
    if account do
      sign_in_get_account(player, email)
    else
      ApathyDrive.Entity.notify(player, {:create_account_set_email, email})
      Players.send_message(player, ["scroll", "<p>Please enter the password you would like to use: <input id='password' type='password' class='prompt'></input></p>"])
      Players.send_message(player, ["focus", "#password"])
    end
  end

  def create_account_set_password(player, password) do
    ApathyDrive.Entity.notify(player, {:create_account_set_password, password})
    Players.send_message(player, ["scroll", "<p>Please confirm your new password: <input id='password-confirmation' type='password' class='prompt'></input></p>"])
    Players.send_message(player, ["focus", "#password-confirmation"])
  end

  def create_account_finish(player, password) do
    if password_confirmed?(player, password) do
      Players.send_message(player, ["scroll", "<p>Welcome!</p>"])
      account = ApathyDrive.Account.new(email:     :gen_event.call(player, Components.Login, :get_email),
                                        password:  "#{:gen_event.call(player, Components.Login, :get_password)}",
                                        salt:      "#{:gen_event.call(player, Components.Login, :get_salt)}"
      )
      Repo.create account
      display_character_select(player, account)
    else
      Players.send_message(player, ["scroll", "<p>Passwords did not match.</p>"])
      email = :gen_event.call(player, Components.Login, :get_email)
      create_account_set_email(player, email)
    end
  end

  def password_confirmed?(player, password_confirmation) do
    password = :gen_event.call(player, Components.Login, :get_password)
    salt     = :gen_event.call(player, Components.Login, :get_salt)
    {:ok, password} == :bcrypt.hashpw(password_confirmation, salt)
  end

  def get_class(player) do
    :gen_event.call(player, Components.Login, :get_class)
  end

  def get_race(player) do
    :gen_event.call(player, Components.Login, :get_race)
  end

  def get_character(player) do
    :gen_event.call(player, Components.Login, :get_character)
  end

  def get_cp(player) do
    :gen_event.call(player, Components.Login, :get_cp)
  end

  def get_stat(player, stat_name) do
    :gen_event.call(player, Components.Login, {:get_stat, stat_name})
  end

  def set_stat(player, stat_name, stat) do
    ApathyDrive.Entity.notify(player, {:set_stat, stat_name, stat})
  end

  def get_hair_length(player) do
    :gen_event.call(player, Components.Login, :get_hair_length)
  end

  def set_hair_length(player, hair_length) do
    ApathyDrive.Entity.notify(player, {:set_hair_length, hair_length})
  end

  def get_hair_color(player) do
    :gen_event.call(player, Components.Login, :get_hair_color)
  end

  def set_hair_color(player, hair_color) do
    ApathyDrive.Entity.notify(player, {:set_hair_color, hair_color})
  end

  def get_eye_color(player) do
    :gen_event.call(player, Components.Login, :get_eye_color)
  end

  def set_eye_color(player, eye_color) do
    ApathyDrive.Entity.notify(player, {:set_eye_color, eye_color})
  end

  def get_gender(player) do
    :gen_event.call(player, Components.Login, :get_gender)
  end

  def set_gender(player, gender) do
    ApathyDrive.Entity.notify(player, {:set_gender, gender})
  end

  def set_cp(player, cp) do
    ApathyDrive.Entity.notify(player, {:set_cp, cp})
  end

  def login(player, character) do
    ApathyDrive.Entity.notify(player, {:login, character})
  end

  def serialize(entity) do
    nil
  end

  ### GenEvent API
  def init(state) do
    {:ok, state}
  end

  def handle_call(:get_step, state) do
    {:ok, state[:step], state}
  end

  def handle_call(:get_email, state) do
    {:ok, state[:email], state}
  end

  def handle_call(:get_password, state) do
    {:ok, state[:password], state}
  end

  def handle_call(:get_salt, state) do
    {:ok, state[:salt], state}
  end

  def handle_call(:get_race, state) do
    {:ok, state[:race], state}
  end

  def handle_call(:get_character, state) do
    {:ok, state[:character], state}
  end

  def handle_call(:get_cp, state) do
    {:ok, state[:stats][:cp], state}
  end

  def handle_call({:get_stat, stat_name}, state) do
    {:ok, state[:stats][stat_name], state}
  end

  def handle_call(:get_class, state) do
    {:ok, state[:class], state}
  end

  def handle_call(:get_hair_length, state) do
    {:ok, state[:hair_length], state}
  end

  def handle_call(:get_hair_color, state) do
    {:ok, state[:hair_color], state}
  end

  def handle_call(:get_eye_color, state) do
    {:ok, state[:eye_color], state}
  end

  def handle_call(:get_gender, state) do
    {:ok, state[:gender], state}
  end

  def handle_call(:get_account, state) do
    {:ok, state[:account], state}
  end

  def handle_event({:set_stat, stat_name, stat}, state) do
    stats = Keyword.put(state[:stats], stat_name, stat)
    {:ok, Keyword.put(state, :stats, stats)}
  end

  def handle_event({:set_cp, cp}, state) do
    stats = Keyword.put(state[:stats], :cp, cp)
    {:ok, Keyword.put(state, :stats, stats)}
  end

  def handle_event({:set_hair_length, hair_length}, state) do
    {:ok, Keyword.put(state, :hair_length, hair_length)}
  end

  def handle_event({:set_hair_color, hair_color}, state) do
    {:ok, Keyword.put(state, :hair_color, hair_color)}
  end

  def handle_event({:set_eye_color, eye_color}, state) do
    {:ok, Keyword.put(state, :eye_color, eye_color)}
  end

  def handle_event({:set_gender, gender}, state) do
    {:ok, Keyword.put(state, :gender, gender)}
  end

  def handle_event({:intro}, _state) do
    {:ok, [step: "intro"]}
  end

  def handle_event({:sign_in_set_email, email}, _state) do
    {:ok, [step: "sign_in_check_password", email: email]}
  end

  def handle_event({:sign_in_set_account, account}, _state) do
    {:ok, [step: "character_select", account: account]}
  end

  def handle_event(:create_character_request_race, state) do
    {:ok, [step: "create_character_request_race", account: state[:account]]}
  end

  def handle_event({:create_character_set_race, race}, state) do
    {:ok, [step: "create_character_request_class", race: race, account: state[:account]]}
  end

  def handle_event({:training, character, stats}, state) do
    {:ok, [step: "training", character: character, stats: stats]}
  end

  def handle_event({:login, character}, state) do
    {:ok, [step: "playing", character: character]}
  end

  def handle_event(:create_account_request_email, _state) do
    {:ok, [step: "create_account_request_email"]}
  end

  def handle_event({:create_account_set_email, email}, _state) do
    {:ok, salt} = :bcrypt.gen_salt
    {:ok, [step: "create_account_request_password", email: email, salt: salt]}
  end

  def handle_event({:create_account_set_password, password}, state) do
    {:ok, password} = :bcrypt.hashpw(password, state[:salt])
    {:ok, Keyword.merge(state, [step: "create_account_confirm_password", password: password])}
  end

  def handle_event(_, state) do
    {:ok, state}
  end
end
