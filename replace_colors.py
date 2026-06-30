import os
import re

lib_dir = 'lib'
color_pattern = re.compile(r'Colors\.(red|green|blue|orange|yellow|amber|purple|pink|cyan|teal)(Accent)?(\.shade\d{3})?')

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = color_pattern.sub('Colors.white', content)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
