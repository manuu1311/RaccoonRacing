extends Node2D

@onready var subviewport := $SubViewport
@onready var camera := $SubViewport/Camera2D

func _ready():
	subviewport.world_2d = get_viewport().world_2d

	camera.enabled = true
	camera.make_current()

	# Wait a couple of frames so the viewport actually renders
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw

	save_screenshot()

func save_screenshot():
	var image = subviewport.get_texture().get_image()
	print(image.get_size())
	image.save_png("D:/misc/Projects/Godot/RaccoonRacing/raccoon-racing/Assets/screenshot.png")
