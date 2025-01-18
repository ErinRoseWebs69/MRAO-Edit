extends Control

### Node Variables
@onready var MetallicTexturePreview = $Panel/Splitter/TextureList/MapSplitter/Metallic/MetallicTexture
@onready var RoughnessTexturePreview = $Panel/Splitter/TextureList/MapSplitter/Roughness/RoughnessTexture
@onready var AOTexturePreview = $Panel/Splitter/TextureList/MapSplitter/AO/AOTexture
@onready var MRAOTexturePreview = $Panel/Splitter/Settings/SettingsSplitter/MRAOPreview
@onready var MetalPathButton = $Panel/Splitter/TextureList/MapSplitter/Metallic/PathButton
@onready var RoughPathButton = $Panel/Splitter/TextureList/MapSplitter/Roughness/PathButton2
@onready var AOPathButton = $Panel/Splitter/TextureList/MapSplitter/AO/PathButton3
@onready var SaveDirectlyDialogue = $SaveDirectoryDialogue
@onready var SavePathButton = $Panel/Splitter/Settings/SettingsSplitter/FilePath/PathButton
@onready var FileNameField = $Panel/Splitter/Settings/SettingsSplitter/FileName/TextEdit
@onready var LoadFileDialouge = $LoadFileDialogue

### Variables
var isSmoothnessMap:bool = false ## Temporarily disabled due to compression oddities
var savedMetalImage:Image
var savedRoughImage:Image
var savedAOImage:Image
var savedMRAOImage:Image ## technically pointless? leaving here just in case though.
var saveDirectory:String
var exportFileType:String = ".png"
var openMapType:String
var tempMapPath:String

# Self-explanatory
func _ready() -> void:
	get_window().files_dropped.connect(onFilesDropped)

# Checks if the mouse is hovering over a TextureRect node
func mouseOverControl(node:TextureRect):
	var mouse = get_global_mouse_position()
	if mouse.x < node.global_position.x or mouse.x > node.global_position.x + node.size.x or mouse.y < node.global_position.y or mouse.y > node.global_position.y + node.size.y:
		return false
	return true

#Actually detect file-dropping, and run the above function to make sure mouse is positioned correctly.
func onFilesDropped(files: Array):
	var path = files[0]
	if path.ends_with(".png") or path.ends_with(".tga") or path.ends_with(".bmp"):
		if mouseOverControl(MetallicTexturePreview):
			var image = Image.new()
			image.load(path)
			var texture = ImageTexture.new()
			texture.set_image(image)
			savedMetalImage = image
			MetallicTexturePreview.texture = texture
			updateMRAOTexture(image, "metal")
			MetalPathButton.text = "pass"
		if mouseOverControl(RoughnessTexturePreview):
			var image = Image.new()
			image.load(path)
			var texture = ImageTexture.new()
			texture.set_image(image)
			savedRoughImage = image
			RoughnessTexturePreview.texture = texture
			updateMRAOTexture(image, "rough")
		if mouseOverControl(AOTexturePreview):
			var image = Image.new()
			image.load(path)
			var texture = ImageTexture.new()
			texture.set_image(image)
			savedAOImage = image
			AOTexturePreview.texture = texture
			updateMRAOTexture(image, "ao")

# Just update the MRAO preview TextureRect. Whenever the M, R, and AO maps above are updated, this is called.
func updateMRAOTexture(image:Image, map:String):
	print("loading image")
	var mraoImage = Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
	print("created mrao image base")
	match map:
		"metal":
			for y in image.get_height():
				for x in image.get_width():
					var rChannel = image.get_pixel(x, y).r
					var gChannel
					var bChannel
					if savedRoughImage != null:
						gChannel = savedRoughImage.get_pixel(x, y).g
					else:
						gChannel = 0.0
					if savedAOImage != null:
						bChannel = savedAOImage.get_pixel(x, y).b
					else:
						bChannel = 0.0
					mraoImage.set_pixel(x, y, Color(rChannel, gChannel, bChannel, 1.0))
		"rough":
			for y in image.get_height():
				for x in image.get_width():
					var rChannel
					var gChannel = image.get_pixel(x, y).g
					var bChannel
					if savedMetalImage != null:
						rChannel = savedMetalImage.get_pixel(x, y).r
					else:
						rChannel = 0.0
					if savedAOImage != null:
						bChannel = savedAOImage.get_pixel(x, y).b
					else:
						bChannel = 0.0
					mraoImage.set_pixel(x, y, Color(rChannel, gChannel, bChannel, 1.0))
		"ao":
			for y in image.get_height():
				for x in image.get_width():
					var rChannel
					var gChannel
					var bChannel = image.get_pixel(x, y).b
					if savedMetalImage == null:
						rChannel = 0.0
					else:
						rChannel = savedMetalImage.get_pixel(x, y).r
					if savedRoughImage != null:
						gChannel = savedRoughImage.get_pixel(x, y).g
					else:
						gChannel = 0.0
					mraoImage.set_pixel(x, y, Color(rChannel, gChannel, bChannel, 1.0))
	var mraoTexture = ImageTexture.new()
	mraoTexture.set_image(mraoImage)
	savedMRAOImage = mraoImage
	MRAOTexturePreview.texture = mraoTexture

## TODO: Export the final product.
func _on_export_button_pressed() -> void:
	if savedMRAOImage != null:
		savedMRAOImage.save_png(saveDirectory + FileNameField.text + exportFileType)


func _on_path_button_pressed() -> void:
	SaveDirectlyDialogue.show()


func _on_save_file_dialouge_dir_selected(dir: String) -> void:
	saveDirectory = dir + "/"
	SavePathButton.text = saveDirectory


func _on_png_pressed() -> void:
	exportFileType = ".png"

func _on_tga_pressed() -> void:
	exportFileType = ".tga"

func _on_load_file_dialogue_file_selected(path: String) -> void:
	match openMapType:
		"metal":
			var image = Image.new()
			image.load(path)
			var texture = ImageTexture.new()
			texture.set_image(image)
			savedMetalImage = image
			MetallicTexturePreview.texture = texture
			updateMRAOTexture(image, "metal")
			MetalPathButton.text = path
		"rough":
			var image = Image.new()
			image.load(path)
			var texture = ImageTexture.new()
			texture.set_image(image)
			savedRoughImage = image
			RoughnessTexturePreview.texture = texture
			updateMRAOTexture(image, "rough")
			RoughPathButton.text = path
		"ao":
			var image = Image.new()
			image.load(path)
			var texture = ImageTexture.new()
			texture.set_image(image)
			savedAOImage = image
			AOTexturePreview.texture = texture
			updateMRAOTexture(image, "ao")
			AOPathButton.text = path

func _on_metal_path_button_pressed() -> void:
	openMapType = "metal"
	LoadFileDialouge.show()

func _on_path_button_2_pressed() -> void:
	openMapType = "rough"
	LoadFileDialouge.show()

func _on_path_button_3_pressed() -> void:
	openMapType = "ao"
	LoadFileDialouge.show()
