-- アプリ切り替え + ウィンドウスナップ + ランチャー
-- prefix は Control+Command (Caps Lock はシステム設定で Control にリマップ済み)
-- 注意: macOS が ctrl+cmd+{space, d, q} を予約済みのため、それらのキーは避けること。
-- 左右の Command は区別されない (hs.hotkey は修飾キーの左右を見分けられない)。

-- `hs` CLI (brew の hammerspoon) から設定を叩けるようにする。
require("hs.ipc")

local prefix = { "ctrl", "cmd" }

--------------------------------------------------------------------------------
-- アプリ切り替え
--------------------------------------------------------------------------------

-- Profile recorded by install.sh ("full" or "neo"); "full" when not installed yet.
local function readProfile()
  local f = io.open(os.getenv("HOME") .. "/.config/dotfiles/profile", "r")
  if not f then
    return "full"
  end
  local profile = f:read("*l")
  f:close()
  return profile
end

-- Chrome on the Pro, Safari on the Neo.
local browser = readProfile() == "neo"
  and "com.apple.Safari"
  or "com.google.Chrome"

-- キー -> バンドル ID
local apps = {
  b = browser,                   -- browser
  t = "com.mitchellh.ghostty",   -- terminal
  o = "md.obsidian",
}

-- 起動 or 前面化。既に前面にいる場合も何もしない (連打しても状態が変わらない)。
local function focus(bundleID)
  hs.application.launchOrFocusByBundleID(bundleID)
end

for key, bundleID in pairs(apps) do
  hs.hotkey.bind(prefix, key, function()
    focus(bundleID)
  end)
end

--------------------------------------------------------------------------------
-- ランチャー (Spotlight)
--------------------------------------------------------------------------------

-- Spotlight is a macOS-reserved shortcut, so it cannot be invoked directly.
-- Synthesize its real cmd+space instead, on key down (cmd+space still works too).
--
-- The physically held ctrl+cmd could leak into the synthetic event and turn it
-- into ctrl+cmd+space; posting the event with an explicit cmd-only flag set
-- (via setFlags) overrides the current modifier state.
local function openSpotlight()
  local down = hs.eventtap.event.newKeyEvent("space", true)
  down:setFlags({ cmd = true })
  down:post()

  local up = hs.eventtap.event.newKeyEvent("space", false)
  up:setFlags({ cmd = true })
  up:post()
end

hs.hotkey.bind(prefix, "l", openSpotlight)

--------------------------------------------------------------------------------
-- ウィンドウスナップ
--------------------------------------------------------------------------------

-- 画面 (メニューバー等を除いた frame) に対する割合で位置とサイズを指定する。
-- アニメーションは切る (既定は 0.2 秒)。
hs.window.animationDuration = 0

local layouts = {
  left  = { x = 0,   y = 0,   w = 0.5, h = 1   },
  right = { x = 0.5, y = 0,   w = 0.5, h = 1   },
  up    = { x = 0,   y = 0,   w = 1,   h = 0.5 },
  down  = { x = 0,   y = 0.5, w = 1,   h = 0.5 },
  f     = { x = 0,   y = 0,   w = 1,   h = 1   },
}

local function snap(unit)
  local win = hs.window.focusedWindow()
  if not win then
    return
  end
  win:moveToUnit(hs.geometry.rect(unit.x, unit.y, unit.w, unit.h))
end

-- ctrl+cmd+←/→ は他の常駐アプリが Carbon hotkey として先に登録済みで、
-- hs.hotkey (RegisterEventHotKey) では -9878 で失敗する。
-- eventtap はより低いレイヤーでイベントを掴めるので、矢印キーだけこちらで処理する。
local arrowKeys = { left = true, right = true, up = true, down = true }

for key, unit in pairs(layouts) do
  if not arrowKeys[key] then
    hs.hotkey.bind(prefix, key, function()
      snap(unit)
    end)
  end
end

-- eventtap は修飾キーで判定する。
-- 矢印キーは Apple キーボードだと常に fn フラグが立つので、fn は判定に含めない。
local function isPrefixOnly(flags)
  return flags.ctrl and flags.cmd and not flags.alt and not flags.shift
end

snapTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  local key = hs.keycodes.map[event:getKeyCode()]
  local unit = arrowKeys[key] and layouts[key]
  if unit and isPrefixOnly(event:getFlags()) then
    snap(unit)
    return true -- イベントを飲み込んで他アプリに渡さない
  end
  return false
end)
snapTap:start()

--------------------------------------------------------------------------------
-- IME 切り替え (右 Command 単体)
--------------------------------------------------------------------------------

-- Tapping right cmd alone toggles between English and Japanese input.
-- The tap only observes events and never swallows them, so right cmd + key
-- shortcuts and left cmd behave exactly as before.
local RIGHT_CMD = 54
-- Device-dependent bits in CGEventFlags that tell left and right cmd apart.
local LEFT_CMD_MASK = 0x08
local RIGHT_CMD_MASK = 0x10
-- A press held longer than this is treated as an aborted shortcut, not a tap.
local IME_TAP_MAX_SECONDS = 0.3
-- JIS 英数 / かな keys; posting them is more reliable than selecting the
-- input source directly, which can leave the Japanese IME half-switched.
local EISU = 102
local KANA = 104

local imePressedAt = nil -- set while a right cmd tap is still a candidate

local function onlyCmd(flags)
  return flags.cmd and not flags.ctrl and not flags.alt and not flags.shift
end

local function isJapanese()
  local id = hs.keycodes.currentSourceID()
  return id:find("inputmethod.Kotoeri", 1, true) ~= nil
    and id:find("Roman", 1, true) == nil
end

local function toggleIme()
  local key = isJapanese() and EISU or KANA
  hs.eventtap.event.newKeyEvent({}, key, true):post()
  hs.eventtap.event.newKeyEvent({}, key, false):post()
end

local types = hs.eventtap.event.types
imeTap = hs.eventtap.new({
  types.flagsChanged,
  types.keyDown,
  types.leftMouseDown,
  types.rightMouseDown,
  types.otherMouseDown,
  types.scrollWheel,
}, function(event)
  if event:getType() ~= types.flagsChanged then
    -- Any key, click or scroll while held makes this a shortcut, not a tap.
    imePressedAt = nil
    return false
  end

  local raw = event:rawFlags()
  local rightDown = raw & RIGHT_CMD_MASK ~= 0
  local leftDown = raw & LEFT_CMD_MASK ~= 0

  if event:getKeyCode() == RIGHT_CMD and rightDown then
    -- Right cmd pressed: a candidate only when no other modifier is held.
    if onlyCmd(event:getFlags()) and not leftDown then
      imePressedAt = hs.timer.secondsSinceEpoch()
    else
      imePressedAt = nil
    end
  elseif event:getKeyCode() == RIGHT_CMD and imePressedAt then
    -- Right cmd released with nothing else in between.
    if hs.timer.secondsSinceEpoch() - imePressedAt <= IME_TAP_MAX_SECONDS then
      toggleIme()
    end
    imePressedAt = nil
  else
    -- Another modifier changed while right cmd was held.
    imePressedAt = nil
  end
  return false
end)
imeTap:start()

--------------------------------------------------------------------------------
-- event tap の監視
--------------------------------------------------------------------------------

-- event tap は macOS 側にタイムアウト等で無効化されることがあるので復帰させる。
tapWatchdog = hs.timer.doEvery(5, function()
  for _, tap in ipairs({ snapTap, imeTap }) do
    if not tap:isEnabled() then
      tap:start()
    end
  end
end)

--------------------------------------------------------------------------------
-- 設定のリロード
--------------------------------------------------------------------------------

-- 設定ファイルを編集したら自動でリロードする。
-- ~/.hammerspoon は dotfiles へのシンボリックリンクなので実体のパスを監視する。
local configPath = hs.fs.pathToAbsolute(hs.configdir)
configWatcher = hs.pathwatcher.new(configPath, function(paths)
  for _, path in ipairs(paths) do
    if path:sub(-4) == ".lua" then
      hs.reload()
      return
    end
  end
end)
configWatcher:start()

hs.alert.show("Hammerspoon config loaded")
