-- アプリ切り替えホットキー
-- prefix は Control+Command (Caps Lock はシステム設定で Control にリマップ済み)
-- 注意: macOS が ctrl+cmd+{space, f, d, q} を予約済みのため、それらのキーは避けること。
-- 左右の Command は区別されない (hs.hotkey は修飾キーの左右を見分けられない)。

local prefix = { "ctrl", "cmd" }

-- キー -> バンドル ID
local apps = {
  c = "com.google.Chrome",
  g = "com.mitchellh.ghostty",
  o = "md.obsidian",
}

-- 前面にいる場合は隠す。それ以外は起動 or 前面化。
-- 2 アプリ間の往復を同じキーの連打で行えるようにするための挙動。
local function toggle(bundleID)
  local app = hs.application.get(bundleID)
  if app and app:isFrontmost() then
    app:hide()
  else
    hs.application.launchOrFocusByBundleID(bundleID)
  end
end

for key, bundleID in pairs(apps) do
  hs.hotkey.bind(prefix, key, function()
    toggle(bundleID)
  end)
end

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
