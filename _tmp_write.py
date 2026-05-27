import sys
path = sys.argv[1]
content = open(sys.argv[2], 'r', encoding='utf-8').read()
with open(path, 'w', encoding='utf-8', newline='\n') as f:
    f.write(content)
print(f"Written {len(content)} bytes to {path}")