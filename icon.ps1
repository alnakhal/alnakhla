Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path assets\icon | Out-Null
$bitmap = New-Object System.Drawing.Bitmap(512,512)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$rect = New-Object System.Drawing.RectangleF(0,0,512,512)
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, [System.Drawing.Color]::FromArgb(255,75,57,239), [System.Drawing.Color]::FromArgb(255,0,191,166), [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal)
$graphics.FillRectangle($brush, $rect)
$font = New-Object System.Drawing.Font('Segoe UI', 220, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$sf = New-Object System.Drawing.StringFormat
$sf.Alignment = 'Center'
$sf.LineAlignment = 'Center'
$graphics.DrawString('ã', $font, [System.Drawing.Brushes]::White, $rect, $sf)
$bitmap.Save('assets\icon\app_icon.png',[System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()
