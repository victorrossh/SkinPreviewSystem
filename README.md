# Skins Preview Plugin

## **Description**

The **Skins Preview** plugin is a test implementation for previewing custom skins in AMX Mod X servers for Counter-Strike 1.6. It allows players to preview skins (weapons or player models) in-game by spawning a model in front of them, which follows their aim. The plugin includes a menu system to select skins, control their position, and toggle visibility settings.

-------

## **Features**

- Preview custom skins (weapons or player models) in-game.
- Menu to select from a predefined list of test skins.
- Control the preview distance (move closer or further away).
- Automatic rotation of the preview model.
- Configurable visibility: only the player can see the preview, or all players can see it.
- Timer to automatically remove the preview after a set duration.
- Colored chat messages with a custom prefix `[FWO]`.

-------

## **Usage**

1. **Open the Preview Menu**:
   - Type `/preview` in the chat while alive to open the skin preview menu.
   - Select a skin from the list to preview it.

2. **Control the Preview**:
   - A control menu will appear after selecting a skin:
     - **Move Closer**: Reduces the distance between you and the preview model (minimum: 20 units).
     - **Move Away**: Increases the distance (maximum: 70 units).
     - **Remove Preview**: Removes the preview and reopens the skin selection menu.
   - You can also press the "Exit" key (usually `0`) to remove the preview and reopen the skin selection menu.

3. **Timer**:
   - The preview will automatically disappear after a set duration (default: 15 seconds).
   - The remaining time is displayed in the center of your screen.

-------

## **Commands**

- **say /preview**: Opens the skin preview menu. You must be alive to use this command.

-------

## **CVars**

The plugin includes several CVars for customization. You can set these in `amxmodx/configs/amxx.cfg` or use the `amx_cvar` command in-game.

| CVar                     | Default Value | Description                                                                 |
|--------------------------|---------------|-----------------------------------------------------------------------------|
| `preview_time`           | `15`          | Duration (in seconds) before the preview is automatically removed.          |
| `min_preview_distance`   | `20.0`        | Minimum distance (in units) between the player and the preview model.       |
| `max_preview_distance`   | `70.0`        | Maximum distance (in units) between the player and the preview model.       |
| `preview_visible_all`    | `0`           | Visibility setting: `0` (only the player sees the preview), `1` (all see).  |

-------

## **Test Skins**

The plugin includes 6 test skins for demonstration purposes:
1. **Knife Ahegao** (`models/llg2025/v_def_knife.mdl`, submodel 26)
2. **USP Abstract Blue** (`models/llg2025/v_usp.mdl`, submodel 23)
3. **Pink Panther** (`models/player/llg2025_panther/llg2025_panther.mdl`, submodel 0)
4. **Neo** (`models/player/llg_player_compiled/llg_player_compiled.mdl`, submodel 7)
5. **Mila** (`models/player/llg2025_mila/llg2025_mila.mdl`, submodel 0)
6. **Banana** (`models/player/llg_player_compiled/llg_player_compiled.mdl`, submodel 6)

**Note**: These are placeholder models. Replace them with your own skins in the `g_Skins` array in the source code.

-------

## **Credits**

- **Author**: ftl~ツ
- **Plugin Name**: Skins Preview
- **Version**: 1.0