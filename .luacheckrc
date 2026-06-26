-- luacheck config for XLoot (World of Warcraft addon; Lua 5.1 runtime)
std = "lua51"
max_line_length = false

-- Don't lint vendored third-party libraries
exclude_files = {
	"Libs/**/*.lua",
	"Modules/Options/Libs/**/*.lua",
}

-- WoW exposes a huge global API and addons intentionally set/override globals,
-- so maintaining a full allowlist isn't worth it. Silence the global-access
-- family and keep the checks that catch real bugs (syntax errors, unused and
-- shadowed locals, unreachable code).
ignore = {
	"111", -- setting non-standard global
	"112", -- mutating non-standard global
	"113", -- accessing undefined global
	"143", -- accessing undefined field of a global
}
