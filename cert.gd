extends Node2D

var image : Image = null;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:


func render():
	await get_tree().create_timer(0.5).timeout;
	var texture = get_viewport().get_texture();
	image = texture.get_image();
	var file_dialog = FileDialog.new();
	file_dialog.size = Vector2 (50,400);
	file_dialog.file_selected.connect(_on_save_file_selected);
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM;
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE;
	file_dialog.current_file = "render.png";
	add_child(file_dialog);
	file_dialog.popup_centered();
	var weak_ref = weakref(file_dialog);
	file_dialog.visibility_changed.connect(func(): _on_save_file_selected(file_dialog.current_file))

	

func _on_save_file_selected(path: String):
	image.save_png(path);
	await get_tree().create_timer(0.21).timeout
	convert_png_to_pdf(path)

func convert_png_to_pdf(png_path: String) -> void:
	var pdf_path = png_path.get_basename() + ".pdf"
	var command = ""
	var args = []
	var os_name = OS.get_name()  
	if OS.get_name() == "Windows":
		command = "powershell"
		var ps_script = """
			Add-Type -AssemblyName System.Windows.Forms;
			Add-Type -AssemblyName System.Drawing;
			
			# Cargar la imagen y obtener sus dimensiones
			$image = [System.Drawing.Image]::FromFile('%s');
			$width = $image.Width;
			$height = $image.Height;
			
			# Crear un nuevo bitmap con las dimensiones de la imagen
			$bitmap = New-Object System.Drawing.Bitmap($image);
			
			# Configurar el documento para impresión
			$printDoc = New-Object System.Drawing.Printing.PrintDocument;
			$printDoc.DefaultPageSettings.Landscape = $true;
			
			# Configurar la impresora PDF y eliminar márgenes
			$printDoc.PrinterSettings.PrinterName = "Microsoft Print to PDF";
			$printDoc.PrinterSettings.PrintToFile = $true;
			$printDoc.PrinterSettings.PrintFileName = '%s';
			$printDoc.DefaultPageSettings.Margins.Left = 0;
			$printDoc.DefaultPageSettings.Margins.Right = 0;
			$printDoc.DefaultPageSettings.Margins.Top = 0;
			$printDoc.DefaultPageSettings.Margins.Bottom = 0;
			
			# Manejar el evento de impresión
			$printDoc.Add_PrintPage({
				param($sender, $e)
				
				# Usar el área total de la página en lugar del área imprimible
				$pageWidth = $e.PageBounds.Width;
				$pageHeight = $e.PageBounds.Height;
				
				# Calcular la escala manteniendo la proporción
				$scale = [Math]::Min($pageWidth / $width, $pageHeight / $height) * 0.95;
				
				# Calcular las nuevas dimensiones
				$newWidth = $width * $scale;
				$newHeight = $height * $scale;
				
				# Centrar la imagen en la página
				$x = ($pageWidth - $newWidth) / 2;
				$y = ($pageHeight - $newHeight) / 2;
				
				# Configurar calidad de renderizado
				$e.Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;
				$e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality;
				$e.Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality;
				$e.Graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality;
				
				# Dibujar la imagen
				$e.Graphics.DrawImage($bitmap, $x, $y, $newWidth, $newHeight);
				
				# Indicar que no hay más páginas
				$e.HasMorePages = $false;
			});
			
			# Imprimir el documento
			$printDoc.Print();
			
			# Limpiar recursos
			$bitmap.Dispose();
			$image.Dispose();
			$printDoc.Dispose();
		""" % [png_path.replace("\\", "\\\\"), pdf_path.replace("\\", "\\\\")]
		
		args = ["-Command", ps_script]
		var result = OS.execute(command, args, [], true)

	elif os_name == "Linux":
		command = "convert"
		args = [png_path, pdf_path]
		OS.execute(command, args, [], true)
		OS.shell_open("file://" + pdf_path)  # Abre el PDF automáticamente
	else:
		print("Sistema operativo no soportado para conversión automática.")
		return
