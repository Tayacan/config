{-# LANGUAGE NoMonomorphismRestriction #-} -- allow binding of GSConfig at top level
{-# LANGUAGE TypeSynonymInstances #-} -- allow funky coloring thing
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
import XMonad

import qualified XMonad.StackSet as W

import XMonad.Hooks.ManageDocks
import XMonad.Layout.NoBorders
import XMonad.Layout.WorkspaceDir
import XMonad.Layout.PerWorkspace
import XMonad.Layout.LayoutModifier
import XMonad.Layout.IndependentScreens (countScreens)

import XMonad.Actions.TopicSpace
import XMonad.Actions.GridSelect

import XMonad.Util.Run(spawnPipe,safeSpawn)
import XMonad.Util.EZConfig(additionalKeys)
import XMonad.Util.Scratchpad
import XMonad.Hooks.SetWMName

import qualified Data.Map as M

-- own libs
import XMonad.Layout.TopicExtra
import XMonad.Layout.WorkspaceDirAlt hiding (workspaceDir, WorkspaceDir)

main :: IO ()
main = do
  checkTopicConfig myWorkspaces myTopicConfig
  xmonad myConfig

myConfig :: XConfig (ModifiedLayout WorkspaceDir
                    (ModifiedLayout AvoidStruts
                    (ModifiedLayout SmartBorder
                    MyLayout)))
myConfig = def
  { modMask = modm
  , terminal = myTerminal
  , layoutHook = setWorkspaceDirs $ avoidStruts $ smartBorders myLayoutHook
  , workspaces = myWorkspaces
  , manageHook = manageHook def <+> scratchpadManageHook (W.RationalRect 0.2 0.2 0.6 0.6)
  , startupHook = composeAll [docksStartupHook, setWMName "LG3D", fixScreens]
  } `additionalKeys`
  [ ((modm, xK_z), goToSelectedWS myTopicConfig True myGSConfig)
  , ((modm, xK_l), spawn "i3lock -n -c 000000")
  , ((modm, xK_t), sendMessage NextLayout)
  , ((modm, xK_f), fixScreens)
  , ((modm, xK_space), scratchpadSpawnActionCustom "urxvt -name scratchpad")
  ]

myTerminal :: String
myTerminal = "urxvt"

fixScreens :: X ()
fixScreens = do
  screens <- countScreens
  case screens of
    3 -> spawn "xrandr --output eDP-1 --mode 2048x1152 --auto --output DP-1-1 --mode 2560x1440 --right-of eDP-1 --auto --output DP-1-2 --mode 2560x1440 --right-of DP-1-1 --auto"
    1 -> spawn "xrandr --output eDP-1 --mode 2048x1152 --auto"
    _ -> pure ()

modm :: KeyMask
modm = mod4Mask

myWorkspaces :: [String]
myWorkspaces = ["web"
               ,"misc1"
               ,"misc2"
               ,"misc3"
               ,"gmail"
               ,"calendar"
               ,"pdf"
               ,"slack"
               ,"funbrowser"
               ]

type MyLayout = Choose Full (Choose Tall (Mirror Tall))

myLayoutHook :: MyLayout a
myLayoutHook = Full ||| tiled ||| Mirror tiled
    where
     tiled = Tall nmaster delta ratio
     nmaster = 1
     ratio = 1/2
     delta = 3/100

setWorkspaceDirs layout =
    workspaceDir "~" layout
  where add ws dir = onWorkspace ws (workspaceDir dir layout)

myGSConfig = defaultGSConfig {gs_navigate = navNSearch}

myTopicConfig :: TopicConfig
myTopicConfig = TopicConfig
  { topicDirs = M.fromList []
  , topicActions = M.fromList
      [ ("gmail", appBrowser ["https://gmail.com"])
      , ("web", browser [])
      , ("calendar", appBrowser ["https://calendar.google.com"])
      , ("slack", safeSpawn "slack" [])
      , ("funbrowser", newBrowser ["https://reddit.com", "https://discordapp.com/activity"])
      ]
  , defaultTopicAction = const $ return ()
  , defaultTopic = "web"
  , maxTopicHistory = 10
  }

myBrowser = "chromium-browser"

browser, incogBrowser, newBrowser, appBrowser :: [String] -> X ()
browser         = safeSpawn myBrowser
incogBrowser s  = safeSpawn myBrowser ("--new-window" : "--incognito" : s)
newBrowser s    = safeSpawn myBrowser ("--new-window" : s)
appBrowser = mapM_ (\s -> safeSpawn myBrowser ["--app=" ++ s])

instance HasColorizer WindowSpace where
  defaultColorizer ws isFg =
    if nonEmptyWS ws || isFg
    then stringColorizer (W.tag ws) isFg
    -- Empty workspaces get a dusty-sandy-ish colour
    else return ("#CAC3BA", "white")
