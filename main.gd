extends Control

const STARTING_HP := 100
const STARTING_ENERGY := 3
const HAND_SIZE := 5

var player_hp := STARTING_HP
var enemy_hp := 70
var energy := STARTING_ENERGY
var player_shield := 0
var enemy_shield := 0
var turn_number := 1
var battle_over := false
var escaped := false

var draw_pile: Array[Dictionary] = []
var discard_pile: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var removed_cards: Array[Dictionary] = []

var status_label: Label
var player_hp_label: Label
var enemy_hp_label: Label
var energy_label: Label
var turn_label: Label
var pile_label: Label
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var cards_row: HBoxContainer
var end_turn_button: Button
var run_button: Button
var restart_button: Button

func _ready() -> void:
    _build_ui()
    _start_battle()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#111b2b")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_theme_constant_override("separation", 5)
    add_child(root)
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.offset_left = 10
    root.offset_right = -10
    root.offset_top = 8
    root.offset_bottom = -8

    var title := Label.new()
    title.text = "CARDBOUND  |  BATTLE TEST"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color("#f4d28a"))
    root.add_child(title)

    var fighters := HBoxContainer.new()
    fighters.add_theme_constant_override("separation", 12)
    root.add_child(fighters)

    var player_panel := _make_panel(Color("#243a4d"))
    fighters.add_child(player_panel)
    var pbox := VBoxContainer.new()
    player_panel.add_child(pbox)
    var ptitle := Label.new()
    ptitle.text = "YOU - VANGUARD"
    ptitle.add_theme_color_override("font_color", Color("#a9ddff"))
    pbox.add_child(ptitle)
    player_bar = ProgressBar.new()
    player_bar.max_value = STARTING_HP
    player_bar.value = STARTING_HP
    player_bar.show_percentage = false
    pbox.add_child(player_bar)
    player_hp_label = Label.new()
    pbox.add_child(player_hp_label)
    player_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var enemy_panel := _make_panel(Color("#49313b"))
    fighters.add_child(enemy_panel)
    var ebox := VBoxContainer.new()
    enemy_panel.add_child(ebox)
    var etitle := Label.new()
    etitle.text = "EMBER WOLF"
    etitle.add_theme_color_override("font_color", Color("#ffb0a9"))
    ebox.add_child(etitle)
    enemy_bar = ProgressBar.new()
    enemy_bar.max_value = 70
    enemy_bar.value = 70
    enemy_bar.show_percentage = false
    ebox.add_child(enemy_bar)
    enemy_hp_label = Label.new()
    ebox.add_child(enemy_hp_label)
    enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

    var status_panel := _make_panel(Color("#1b293a"))
    root.add_child(status_panel)
    var status_box := VBoxContainer.new()
    status_panel.add_child(status_box)
    var stats := HBoxContainer.new()
    status_box.add_child(stats)
    energy_label = Label.new()
    stats.add_child(energy_label)
    turn_label = Label.new()
    turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    turn_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    stats.add_child(turn_label)
    status_label = Label.new()
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.custom_minimum_size.y = 28
    status_box.add_child(status_label)

    var hand_title := Label.new()
    hand_title.text = "YOUR HAND — tap a card to play"
    hand_title.add_theme_color_override("font_color", Color("#f4d28a"))
    root.add_child(hand_title)

    cards_row = HBoxContainer.new()
    cards_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    cards_row.add_theme_constant_override("separation", 5)
    root.add_child(cards_row)

    var bottom := HBoxContainer.new()
    bottom.add_theme_constant_override("separation", 6)
    root.add_child(bottom)
    end_turn_button = Button.new()
    end_turn_button.text = "End Turn"
    end_turn_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    end_turn_button.pressed.connect(_end_turn)
    bottom.add_child(end_turn_button)

    run_button = Button.new()
    run_button.text = "Run"
    run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    run_button.pressed.connect(_try_run)
    bottom.add_child(run_button)

    restart_button = Button.new()
    restart_button.text = "Restart"
    restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    restart_button.pressed.connect(_start_battle)
    restart_button.visible = false
    bottom.add_child(restart_button)

    pile_label = Label.new()
    pile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pile_label.add_theme_font_size_override("font_size", 11)
    root.add_child(pile_label)

func _make_panel(color: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(7)
    style.content_margin_left = 8
    style.content_margin_right = 8
    style.content_margin_top = 5
    style.content_margin_bottom = 5
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _card(name: String, cost: int, kind: String, value: int, description: String, compatible: bool = false) -> Dictionary:
    return {
        "name": name,
        "cost": cost,
        "kind": kind,
        "value": value,
        "description": description,
        "compatible": compatible
    }

func _start_battle() -> void:
    player_hp = STARTING_HP
    enemy_hp = 70
    energy = STARTING_ENERGY
    player_shield = 0
    enemy_shield = 0
    turn_number = 1
    battle_over = false
    escaped = false
    discard_pile.clear()
    hand.clear()
    removed_cards.clear()
    draw_pile = [
        _card("Flame Strike", 2, "attack", 24, "Deal 24 damage.", true),
        _card("Piercing Shot", 2, "attack", 20, "Deal 20 damage. Ignore 5 shield."),
        _card("Quick Guard", 1, "defense", 12, "Gain 12 shield."),
        _card("Iron Guard", 2, "defense", 20, "Gain 20 shield.", true),
        _card("Focus", 1, "draw", 2, "Draw 2 cards."),
        _card("Jab", 1, "attack", 10, "Deal 10 damage."),
        _card("Heavy Blow", 3, "attack", 32, "Deal 32 damage.", true),
        _card("Second Wind", 1, "heal", 10, "Restore 10 HP."),
        _card("Small Potion", 0, "consumable", 20, "Restore 20 HP. Consumed on use."),
        _card("Jab", 1, "attack", 10, "Deal 10 damage.")
    ]
    draw_pile.shuffle()
    _draw_to_hand()
    status_label.text = "A wild Ember Wolf appears! Compatible Vanguard cards get a small bonus."
    _refresh_ui()

func _draw_to_hand() -> void:
    while hand.size() < HAND_SIZE:
        if draw_pile.is_empty():
            if discard_pile.is_empty():
                break
            draw_pile = discard_pile.duplicate(true)
            discard_pile.clear()
            draw_pile.shuffle()
        hand.append(draw_pile.pop_back())

func _play_card(index: int) -> void:
    if battle_over or index < 0 or index >= hand.size():
        return
    var card: Dictionary = hand[index]
    var cost: int = card["cost"]
    if cost > energy:
        status_label.text = "Not enough energy to play " + str(card["name"]) + "."
        return

    energy -= cost
    var kind: String = card["kind"]
    var amount: int = card["value"]
    var name: String = card["name"]
    var bonus := 4 if card["compatible"] else 0

    match kind:
        "attack":
            var damage := amount + bonus
            var ignored := 5 if name == "Piercing Shot" else 0
            var shield_absorbed: int = mini(maxi(enemy_shield - ignored, 0), damage)
            enemy_shield -= shield_absorbed
            var hp_damage: int = damage - shield_absorbed
            enemy_hp = maxi(0, enemy_hp - hp_damage)
            status_label.text = name + " deals " + str(damage) + " damage" + (" (Vanguard bonus!)" if bonus > 0 else "") + "."
        "defense":
            player_shield += amount + bonus
            status_label.text = name + ": gained " + str(amount + bonus) + " shield."
        "draw":
            for i in range(amount):
                _draw_one()
            status_label.text = "Focus: drew " + str(amount) + " card(s)."
        "heal":
            var healed: int = mini(amount, STARTING_HP - player_hp)
            player_hp += healed
            status_label.text = "Second Wind restores " + str(healed) + " HP."
        "consumable":
            var healed_item: int = mini(amount, STARTING_HP - player_hp)
            player_hp += healed_item
            removed_cards.append(card)
            status_label.text = "Potion restores " + str(healed_item) + " HP. It is permanently consumed."
    hand.remove_at(index)
    if kind != "consumable":
        discard_pile.append(card)
    if enemy_hp <= 0:
        _finish_battle("Victory! The Ember Wolf is defeated.")
    else:
        _refresh_ui()

func _draw_one() -> void:
    if draw_pile.is_empty():
        if discard_pile.is_empty():
            return
        draw_pile = discard_pile.duplicate(true)
        discard_pile.clear()
        draw_pile.shuffle()
    hand.append(draw_pile.pop_back())

func _end_turn() -> void:
    if battle_over:
        return
    for card in hand:
        discard_pile.append(card)
    hand.clear()

    if enemy_hp > 0:
        var damage := randi_range(8, 14)
        var absorbed: int = mini(player_shield, damage)
        player_shield -= absorbed
        var actual_damage: int = damage - absorbed
        player_hp = maxi(0, player_hp - actual_damage)
        status_label.text = "Ember Wolf attacks for " + str(damage) + ". Shield blocks " + str(absorbed) + "."
    if player_hp <= 0:
        _finish_battle("Defeat! Your character has fallen.")
        return

    turn_number += 1
    energy = STARTING_ENERGY
    _draw_to_hand()
    _refresh_ui()

func _try_run() -> void:
    if battle_over:
        return
    if randf() < 0.5:
        escaped = true
        _finish_battle("You escaped successfully!")
    else:
        status_label.text = "Escape failed! The Ember Wolf gets an attack."
        var damage := randi_range(8, 14)
        var absorbed: int = mini(player_shield, damage)
        player_shield -= absorbed
        player_hp = maxi(0, player_hp - (damage - absorbed))
        if player_hp <= 0:
            _finish_battle("Defeat! You were caught while escaping.")
        else:
            _refresh_ui()

func _finish_battle(message: String) -> void:
    battle_over = true
    status_label.text = message
    end_turn_button.disabled = true
    run_button.disabled = true
    restart_button.visible = true
    _refresh_ui()

func _refresh_ui() -> void:
    player_bar.value = player_hp
    enemy_bar.value = enemy_hp
    player_hp_label.text = "HP %d/%d  |  Shield %d" % [player_hp, STARTING_HP, player_shield]
    enemy_hp_label.text = "HP %d/70  |  Shield %d" % [enemy_hp, enemy_shield]
    energy_label.text = "Energy: %d/%d" % [energy, STARTING_ENERGY]
    turn_label.text = "Turn %d" % turn_number
    pile_label.text = "Draw: %d    Discard: %d    Consumed: %d" % [draw_pile.size(), discard_pile.size(), removed_cards.size()]

    for child in cards_row.get_children():
        child.queue_free()
    for i in range(hand.size()):
        var card: Dictionary = hand[i]
        var button := Button.new()
        button.custom_minimum_size = Vector2(82, 95)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.size_flags_vertical = Control.SIZE_EXPAND_FILL
        button.text = "%s\n\n%d EN\n%s" % [card["name"], card["cost"], card["description"]]
        button.add_theme_font_size_override("font_size", 11)
        button.disabled = battle_over or int(card["cost"]) > energy
        if card["kind"] == "consumable":
            button.add_theme_color_override("font_color", Color("#8ee3b1"))
        elif card["compatible"]:
            button.add_theme_color_override("font_color", Color("#f4d28a"))
        button.pressed.connect(_play_card.bind(i))
        cards_row.add_child(button)

    end_turn_button.disabled = battle_over
    run_button.disabled = battle_over
    restart_button.visible = battle_over
