from PIL import Image, ImageDraw, ImageFont
import os

def create_bus_icon():
    # إنشاء صورة جديدة بحجم 512x512
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # الألوان
    blue_bg = '#1E88E5'
    yellow_bus = '#FFD54F'
    orange_accent = '#FF8F00'
    light_blue = '#81D4FA'
    dark_blue = '#0277BD'
    gray_wheel = '#424242'
    white = '#FFFFFF'
    red = '#F44336'
    green = '#4CAF50'
    
    # رسم الخلفية الدائرية
    margin = 16
    draw.ellipse([margin, margin, size-margin, size-margin], fill=blue_bg)
    
    # رسم جسم الباص
    bus_x = 80
    bus_y = 180
    bus_width = 352
    bus_height = 180
    draw.rounded_rectangle([bus_x, bus_y, bus_x + bus_width, bus_y + bus_height], 
                          radius=20, fill=yellow_bus, outline=orange_accent, width=4)
    
    # رسم مقدمة الباص
    front_x = 60
    front_y = 200
    front_width = 40
    front_height = 140
    draw.rounded_rectangle([front_x, front_y, front_x + front_width, front_y + front_height], 
                          radius=15, fill=yellow_bus, outline=orange_accent, width=4)
    
    # رسم النوافذ
    windows = [
        (100, 200, 60, 50),
        (180, 200, 60, 50),
        (260, 200, 60, 50),
        (340, 200, 60, 50)
    ]
    
    for x, y, w, h in windows:
        draw.rounded_rectangle([x, y, x + w, y + h], 
                              radius=8, fill=light_blue, outline=dark_blue, width=2)
    
    # رسم الباب
    door_x = 420
    door_y = 220
    door_width = 30
    door_height = 80
    draw.rounded_rectangle([door_x, door_y, door_x + door_width, door_y + door_height], 
                          radius=5, fill=orange_accent, outline='#E65100', width=2)
    
    # مقبض الباب
    handle_x = 445
    handle_y = 260
    draw.ellipse([handle_x-3, handle_y-3, handle_x+3, handle_y+3], fill='#E65100')
    
    # رسم العجلات
    wheels = [(140, 380), (372, 380)]
    for wheel_x, wheel_y in wheels:
        # العجلة الخارجية
        draw.ellipse([wheel_x-35, wheel_y-35, wheel_x+35, wheel_y+35], 
                    fill=gray_wheel, outline='#212121', width=4)
        # العجلة الوسطى
        draw.ellipse([wheel_x-20, wheel_y-20, wheel_x+20, wheel_y+20], fill='#757575')
        # المركز
        draw.ellipse([wheel_x-8, wheel_y-8, wheel_x+8, wheel_y+8], fill='#BDBDBD')
    
    # المصابيح الأمامية
    front_lights = [(75, 220), (75, 280)]
    for light_x, light_y in front_lights:
        draw.ellipse([light_x-12, light_y-12, light_x+12, light_y+12], 
                    fill='#FFEB3B', outline='#F57F17', width=2)
    
    # المصابيح الخلفية
    rear_lights = [(437, 220), (437, 280)]
    for light_x, light_y in rear_lights:
        draw.ellipse([light_x-8, light_y-8, light_x+8, light_y+8], 
                    fill=red, outline='#C62828', width=2)
    
    # لوحة "SCHOOL BUS"
    sign_x = 120
    sign_y = 270
    sign_width = 200
    sign_height = 30
    draw.rounded_rectangle([sign_x, sign_y, sign_x + sign_width, sign_y + sign_height], 
                          radius=5, fill='#FF5722')
    
    # رسم الطريق
    road_y = 420
    draw.rounded_rectangle([40, road_y, 472, road_y + 8], radius=4, fill='#616161')
    
    # خطوط الطريق
    for i in range(11):
        line_x = 50 + i * 40
        draw.rectangle([line_x, road_y + 3, line_x + 20, road_y + 5], fill='#FFEB3B')
    
    # أيقونة GPS
    gps_x = 256
    gps_y = 140
    draw.ellipse([gps_x-15, gps_y-15, gps_x+15, gps_y+15], 
                fill=green, outline='#2E7D32', width=2)
    draw.ellipse([gps_x-8, gps_y-8, gps_x+8, gps_y+8], fill='#81C784')
    draw.ellipse([gps_x-3, gps_y-3, gps_x+3, gps_y+3], fill=white)
    
    # حفظ الصورة
    output_path = 'assets/icons/app_icon.png'
    img.save(output_path, 'PNG', quality=100)
    print(f"تم إنشاء الأيقونة بنجاح: {output_path}")
    
    # إنشاء أحجام مختلفة للأندرويد
    sizes = [192, 144, 96, 72, 48, 36]
    for size in sizes:
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(f'assets/icons/app_icon_{size}.png', 'PNG', quality=100)
        print(f"تم إنشاء أيقونة بحجم {size}x{size}")

if __name__ == "__main__":
    # التأكد من وجود المجلد
    os.makedirs('assets/icons', exist_ok=True)
    create_bus_icon()
