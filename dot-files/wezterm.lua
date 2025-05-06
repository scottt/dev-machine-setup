local wezterm = require 'wezterm'

local launch_menu = {}
local act = wezterm.action
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

config.enable_scroll_bar = true

-- https://wezterm.org/config/keys.html#configuring-key-assignments
config.keys = {
  -- mods: SUPER, CMD, WIN
  --       CTRL
  --       SHIFT
  --       ALT, OPT, META
  --       LEADER see https://wezterm.org/config/keys.html#leader-key
  {
    key = '1',
    mods = 'ALT',
    action = act.ActivateTab(0),
  },
  {
    key = '2',
    mods = 'ALT',
    action = act.ActivateTab(1),
  },
  {
    key = '3',
    mods = 'ALT',
    action = act.ActivateTab(2),
  },
  {
    key = '4',
    mods = 'ALT',
    action = act.ActivateTab(3),
  },
  {
    key = '5',
    mods = 'ALT',
    action = act.ActivateTab(4),
  },
  {
    key = '6',
    mods = 'ALT',
    action = act.ActivateTab(5),
  },
  {
    key = '7',
    mods = 'ALT',
    action = act.ActivateTab(6),
  },
  {
    key = '8',
    mods = 'ALT',
    action = act.ActivateTab(7),
  },
  {
    key = '9',
    mods = 'ALT',
    action = act.ActivateTab(8),
  },
  {
    key = '0',
    mods = 'ALT',
    action = act.ActivateTab(-1),
  },
} 

-- scottt: gnome-terminal, ptyaxis like mouse behavior including "reporting bypass modifer"
config.disable_default_mouse_bindings = true
-- https://wezterm.org/config/mouse.html#configuring-mouse-assignments
config.mouse_bindings = {
  -- Change the default click behavior so that it only selects
  -- text and doesn't open hyperlinks
  -- and make CTRL-Click open hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  -- NOTE that binding only the 'Up' event can give unexpected behaviors.
  -- Read more below on the gotcha of binding an 'Up' event only.
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.SelectTextAtMouseCursor("Cell"),
  },
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'SHIFT',
    action = act.SelectTextAtMouseCursor("Cell"),
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SHIFT',
    action = act.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  --
  {
    event = { Down = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = act.SelectTextAtMouseCursor("Word"),
  },
  {
    event = { Down = { streak = 2, button = 'Left' } },
    mods = 'SHIFT',
    action = act.SelectTextAtMouseCursor("Word"),
  },
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'SHIFT',
    action = act.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  --
  {
    event = { Down = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = act.SelectTextAtMouseCursor("Line"),
  },
  {
    event = { Down = { streak = 3, button = 'Left' } },
    mods = 'SHIFT',
    action = act.SelectTextAtMouseCursor("Line"),
  },
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'SHIFT',
    action = act.CompleteSelection("ClipboardAndPrimarySelection"),
  },
  --
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.ExtendSelectionToMouseCursor("Cell")
  },
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'SHIFT',
    action = act.ExtendSelectionToMouseCursor("Cell")
  },
  --
  {
    event = { Drag = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = act.ExtendSelectionToMouseCursor("Word")
  },
  {
    event = { Drag = { streak = 2, button = 'Left' } },
    mods = 'SHIFT',
    action = act.ExtendSelectionToMouseCursor("Word")
  },
  --
  {
    event = { Drag = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = act.ExtendSelectionToMouseCursor("Line")
  },
  {
    event = { Drag = { streak = 3, button = 'Left' } },
    mods = 'SHIFT',
    action = act.ExtendSelectionToMouseCursor("Line")
  },
  --
  {
    event = { Down = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = act.PasteFrom("PrimarySelection")
  },
  --
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'NONE',
    action = act.ScrollByCurrentEventWheelDelta
  },
  --
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'NONE',
    action = act.ScrollByCurrentEventWheelDelta
  },
}

-- https://wezterm.org/config/lua/config/bypass_mouse_reporting_modifiers.html
config.bypass_mouse_reporting_modifiers = 'SHIFT'

-- https://wezterm.org/colorschemes/v/index.html#vs-code-dark-gogh
config.color_scheme = 'Vs Code Dark+ (Gogh)'

-- Disable ligatures
-- https://github.com/wezterm/wezterm/issues/1264
config.harfbuzz_features = {"calt=0", "clig=0", "liga=0"}

-- Windows PowerShell
--  https://www.reddit.com/r/wezterm/comments/18l1fku/comment/l6ksiyu/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    -- Developer PowerShell for VS 2022
    -- TODO: detect if Visual Studio is present
    -- '$vsPath = &(Join-Path ${env:ProgramFiles(x86)} "/Microsoft Visual Studio/Installer/vswhere.exe") -property installationpath; Import-Module (Join-Path $vsPath "Common7/Tools/vsdevshell/Microsoft.VisualStudio.DevShell.dll"); Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments "-arch=x64"',
    config.default_prog = {
      'powershell.exe',
      '-noe',
      '-c',
      '& "C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/Tools/Launch-VsDevShell.ps1" -Arch amd64',

    }
    table.insert(launch_menu, {
      label = 'Developer PowerShell for VS 2022',
      -- if on windows 10 replace for 'pwsh.exe'
      args = {
        'powershell.exe',
        '-noe',
        '-c',
        '& "C:/Program Files/Microsoft Visual Studio/2022/Community/Common7/Tools/Launch-VsDevShell.ps1"',
      },
    })
    table.insert(launch_menu, {
      label = 'PowerShell',
      -- if on windows 10 replace for 'pwsh.exe'
      args = { 'powershell.exe' },
    })
    config.launch_menu = launch_menu
end

-- Windows ssh-agent
-- https://github.com/wezterm/wezterm/discussions/3772#discussioncomment-7201688
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
    config.ssh_backend = "Ssh2"
    -- Fix "Error connecting to agent : no such file or directory"
    -- https://github.com/wezterm/wezterm/discussions/988#discussioncomment-9440847
    config.mux_enable_ssh_agent = false
end

return config
