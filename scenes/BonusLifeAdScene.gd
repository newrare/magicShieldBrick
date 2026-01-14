# reviewed
extends Control

@onready var ad_title         = $CenterContainer/VBoxContainer/AdTitle
@onready var ad_content       = $CenterContainer/VBoxContainer/AdContent
@onready var countdown_label  = $CenterContainer/VBoxContainer/CountdownLabel
@onready var close_button     = $CenterContainer/VBoxContainer/ButtonContainer/CloseButton

func _ready():
	set_text()
	close_button.pressed.connect(_on_close_pressed)
	start_countdown()

func set_text():
	ad_title.text         = tr("BONUS_LIFE_TITLE")
	ad_content.text       = tr("BONUS_LIFE_MESSAGE")
	countdown_label.text  = tr("AD_CLOSES_IN") + " : 3s"
	close_button.text     = tr("BACK_TO_MENU")

func start_countdown():
	_run_countdown(3)

func _run_countdown(countdown_remaining: int):
	if countdown_remaining > 0:
		countdown_label.text = tr("AD_CLOSES_IN") + " : " + str(countdown_remaining) + "s"

		var timer            = Timer.new()
		timer.wait_time      = 1.0
		timer.one_shot       = true
		timer.timeout.connect(func():
			timer.queue_free()
			_run_countdown(countdown_remaining - 1)
		)
		add_child(timer)
		timer.start()
	else:
		countdown_label.text = tr("BONUS_LIFE_OBTAINED")

		var final_timer       = Timer.new()
		final_timer.wait_time = 1.0
		final_timer.one_shot  = true
		final_timer.timeout.connect(func():
			final_timer.queue_free()
			finish_ad()
		)
		add_child(final_timer)
		final_timer.start()

func finish_ad():
	if BonusLifeManager:
		BonusLifeManager.earn_bonus_life()

	GameManager.change_scene("res://scenes/GameScene.tscn")

func _on_close_pressed():
	GameManager.change_scene("res://scenes/MainMenu.tscn")
