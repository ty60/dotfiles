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

-- キー -> バンドル ID
local apps = {
  b = "com.google.Chrome",       -- browser
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

-- event tap は macOS 側にタイムアウト等で無効化されることがあるので復帰させる。
snapTapWatchdog = hs.timer.doEvery(5, function()
  if not snapTap:isEnabled() then
    snapTap:start()
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
