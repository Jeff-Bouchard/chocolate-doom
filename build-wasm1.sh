# 1) Find current config (for reference)
emcc -v 2>&1 | grep EM_CONFIG

# 2) Copy that config into your home, if you haven't yet
cp "$(emcc -v 2>&1 | grep EM_CONFIG | sed 's/.*= //')" "$HOME/.emscripten"
