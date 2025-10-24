extends Control

# UI References
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var message_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var accept_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/AcceptButton
@onready var background_overlay: ColorRect = $BackgroundOverlay

# Gift message
var current_message: String = ""

func _ready():
	# Hide initially
	hide()

	# Connect button
	if accept_button:
		accept_button.pressed.connect(_on_accept_pressed)

	# Connect to PetDragonManager signal
	if PetDragonManager.instance:
		PetDragonManager.instance.gift_received.connect(_on_gift_received)
		print("[GiftNotificationPopup] ✓ Connected to PetDragonManager")

func _on_gift_received(message: String) -> void:
	"""Show gift popup with message"""
	current_message = message

	# Get pet dragon's name and replace "your dragon" with it
	var display_message = message
	var pet_name = "Your Dragon"  # Default fallback

	if PetDragonManager and PetDragonManager.instance:
		var pet = PetDragonManager.instance.get_pet_dragon()
		if pet:
			pet_name = pet.dragon_name
			# Replace both capitalized and lowercase versions
			display_message = display_message.replace("Your dragon", pet_name)
			display_message = display_message.replace("your dragon", pet_name)

	# Update title with pet's name
	if title_label:
		title_label.text = "🎁 %s Brought You a Gift!" % pet_name

	if message_label:
		message_label.text = display_message

	# Show popup
	show()

	print("[GiftNotificationPopup] Showing gift: '%s'" % display_message)

func _on_accept_pressed() -> void:
	"""Accept the gift and add to inventory"""
	# Add to InventoryManager
	if InventoryManager and InventoryManager.instance:
		var success = InventoryManager.instance.add_item_by_id("pet_gift", 1)
		if success:
			print("[GiftNotificationPopup] ✓ Added 'Pet Gift' to inventory")
		else:
			print("[GiftNotificationPopup] ⚠️ Failed to add gift (inventory full?)")
	else:
		push_warning("[GiftNotificationPopup] InventoryManager not found!")

	# Hide popup
	hide()

	print("[GiftNotificationPopup] Gift accepted!")
