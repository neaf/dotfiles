#!/bin/sh
# Starts CamillaGUI, the web control panel. Requires the CamillaDSP script to already be running
# (CamillaGUI is a client, it doesn't start CamillaDSP itself).
# Open http://localhost:5005/gui/index.html after starting.
DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$DIR/camillagui_backend/camillagui_backend" -c "$DIR/camillagui.yml"
