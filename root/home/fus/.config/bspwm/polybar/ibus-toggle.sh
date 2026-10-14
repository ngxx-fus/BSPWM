
#!/usr/bin/env bash

# Lấy engine hiện tại
CURRENT=$(ibus engine)

if [ "$CURRENT" = "Bamboo" ]; then
    ibus engine "xkb:us::eng"
else
    ibus engine "Bamboo"
fi
