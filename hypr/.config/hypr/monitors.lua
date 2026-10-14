-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Laptop screen
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1.5 })

-- Home: AOC 2460G4 144Hz - positioned to the right of laptop, top-aligned
hl.monitor({ output = "desc:AOC 2460G4 0x00000170", mode = "1920x1080@120", position = "1280x0", scale = 1 })

-- Work: Dell E2222HS - positioned above laptop, centered
hl.monitor({ output = "desc:Dell Inc. DELL E2222HS GY85314", mode = "1920x1080@60", position = "0x0", scale = 1 })

-- Fallback for any unrecognized monitor (TV, guests, etc.)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.6 })
