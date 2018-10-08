defprotocol ApathyDrive.Mobile do
  def ability_value(mobile, ability)
  def accuracy_at_level(mobile, level, room)
  def add_attribute_experience(mobile, skills_and_experience)
  def attack_ability(mobile)
  def attribute_at_level(mobile, attribute, level)
  def auto_attack_target(mobile, room, attack_ability)
  def block_at_level(mobile, level)
  def caster_level(caster, target)
  def colored_name(mobile, observer)
  def confused(mobile, room)
  def cpr(mobile)
  def crits_at_level(mobile, level, room)
  def description(mobile, observer)
  def die(mobile, room)
  def dodge_at_level(mobile, level, room)
  def enough_mana_for_ability?(mobile, ability)
  def enter_message(mobile)
  def exit_message(mobile)
  def has_ability?(mobile, ability_name)
  def heartbeat(mobile, room)
  def held(mobile)
  def hp_description(mobile)
  def hp_regen_per_round(mobile)
  def magical_damage_at_level(mobile, level)
  def magical_resistance_at_level(mobile, level)
  def mana_regen_per_round(mobile)
  def max_hp_at_level(mobile, level)
  def max_mana_at_level(mobile, level)
  def parry_at_level(mobile, level)
  def perception_at_level(mobile, level, room)
  def party_refs(mobile, room)
  def physical_damage_at_level(mobile, level)
  def physical_resistance_at_level(mobile, level)
  def power_at_level(mobile, level)
  def round_length_in_ms(mobile)
  def send_scroll(mobile, html)
  def set_room_id(mobile, room_id)
  def shift_hp(mobile, percentage, room)
  def silenced(mobile, room)
  def spellcasting_at_level(mobile, level, room)
  def stealth_at_level(mobile, level)
  def subtract_mana(mobile, ability)
  def subtract_energy(mobile, ability)
  def target_level(caster, target)
  def tracking_at_level(mobile, level, room)
  def update_prompt(mobile)
end
