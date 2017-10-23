# Rendercam
A universal render script & camera package for all the common camera types: perspective or orthographic, fixed aspect ratio or unfixed aspect ratio, plus four options for how the view changes for different resolutions and window sizes, and more. Also does screen-to-world and world-to-screen transforms for any camera type; camera switching, zooming, panning, shaking, recoil, and lerped following.

## Installation

Install Rendercam in your project by adding it as a [library dependency](https://www.defold.com/manuals/libraries/). Open your game.project file and in the "Dependencies" field under "Project", add:
```
https://github.com/rgrams/rendercam/archive/master.zip
```

Then open the "Project" menu of the editor and click "Fetch Libraries". You should see the "rendercam" folder appear in your assets panel after a few moments.

## Basic Setup

It just takes two simple steps to get Rendercam up and running.

1. Select the Rendercam render script in your game.project file. Under "bootstrap", edit the "Render" field and select "/rendercam/rendercam.render".
2. Add a Rendercam camera to your scene. Add "camera.go" from the rendercam folder to your main collection. It can be a child of another game object, or not, but make sure it's z-position is zero (this is for the default camera settings only).

## Camera Settings

To change your camera settings, expand the camera game object in the outline and select it's script component. In the properties panel you will have a bunch of different options.

#### Active <kbd>bool</kbd>
Whether the camera is initially active or not. If you have multiple cameras you will want to uncheck this property on your secondary cameras to make sure the right camera is used.

#### Orthographic <kbd>bool</kbd>
Leave checked for an orthographic camera, uncheck for a perspective camera. Certain other options are only used if the camera is of one type or the other. FOV is only used by perspective cameras, Ortho Scale is only used by orthographic cameras, etc.

#### Near Z <kbd>number</kbd>
The distance in front of the camera where rendering will start, relative to the camera's position. This can be any value for orthographic cameras, but must be greater than zero for perspective cameras.

#### Far Z <kbd>number</kbd>
The distance in front of the camer where rendering will end, relative to the camera's position. Should be greater than Near Z.

#### 2d World Z <kbd>number</kbd>
The z coordinate of the game world for 2D or 2.5D games (orthographic _or_ perspective camera). This is the z position used for screen-to-world position transforms, and if you are using a set camera view area (see below), this is the z position those dimensions will be measured at.

#### FOV (field of view) <kbd>number</kbd>
The field of view for perspective cameras, in degrees. This property is generally unused, as the FOV will be calculated based on other settings. If you want a camera with a fixed FOV, make sure "Use View Area" is _un-checked_ and select the "Fixed Height" scale mode. The aspect ratio can be fixed or not.

#### Ortho Scale <kbd>number</kbd>
The initial "zoom"/scale for orthographic cameras. At an ortho scale of 2 the camera will show an area of the world four times as large (x and y are both doubled) as it would at scale 1. Or 1/4 of the area at scale 0.5, etc. See the "View Area" property below to set the initial view are of your camera.

#### Fixed Aspect Ratio <kbd>bool</kbd>
If checked, black bars will be added to the top and bottom or sides of the viewport as necessary so it will always match the aspect ratio you specify via the "Aspect Ratio" property.

#### Aspect Ratio <kbd>vector3</kbd>
The aspect ratio to be used if "Fixed Aspect Ratio" is checked. Use X and Y to enter your desired proportion---i.e. X=16, Y=9 for a 16:9 aspect. A vector is used to enter the ratio so it can be an accurate fraction. The numbers themselves don't matter, just the proportion between them. You can use 1280, 1024 instead of 5, 4, and so on.

#### Use View Area <kbd>bool</kbd>
If checked, the "View Area" setting will be used to calculate the initial area of the world that the camera will show. If not checked, the window resolution specified in your game.project file will be used, _unless_ you're using a perspective camera and have set "FOV" greater than zero, in which case the camera will start with that FOV instead of calculating a specific area of world.

#### View Area <kbd>vector3</kbd>
The dimensions in world space that the camera will show, if "Use View Area" is checked. They will be measured at "2d World Z" (usually 0). If using a fixed aspect ratio, the view area Y value will be overwritten based on the X value if they don't match the specified aspect ratio.

### View Scale Modes:
The last four checkbox settings determine the scale mode used to calculate how the view changes anytime the window resolution is changed (including on init if your camera settings don't match your display settings in game.project). Only the first mode checked will be used (and a default is used if none are checked). Note that Fixed Area, Fixed Width, and Fixed Height all work exactly the same if you're using a fixed aspect ratio (since the aspect ratio locks the viewport dimensions together).

#### Expand View
The view area will expand and contract with the window size, keeping the world at the same size on-screen. If you set your camera view area to 800x600, but your game starts with a window size of 1600x900 (as set in game.project), then the view will expand to fill the window and show a 1600x900 area of the world. Likewise if the window size is smaller---the camera will simply show less of the world.

#### Fixed Area
The camera will zoom in or out to show exactly the same _area_ of the game world.  This works great for a wide range of window or display proportions, if you don't need either dimension to be exactly the same for everyone.  

#### Fixed Width
The camera will always show the same width of game world, the height is adjusted to fit. If the window is stretched vertically, it will show more space on top and bottom.

#### Fixed Height
Like "Fixed Width", but switched. The camera will always showe the same height of the game world, and the width will vary with the window proportion. If you make the window tall and skinny, you'll see the same space up and down, but very little side to side.

## Camera Functions
To use the other features of Rendercam you need to call module functions from a script. First, require the rendercam module in your script:
```
local rendercam = require "rendercam.rendercam"
```

#### rendercam.activate_camera(cam_id)
Activate the camera and deactivate the last active camera.

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object.

#### rendercam.zoom(z, [cam_id])
Zoom the camera. If the camera is orthographic, this adds `z * rendercam.ortho_zoom_mult` to the camera's ortho scale. If the camera is perspective, this moves the camera forward by `z`. You can set `rendercam.ortho_zoom_mult` to adjust the ortho zoom speed, or use `rendercam.get_ortho_scale` and `rendercam.set_ortho_scale` for full control.

_PARAMETERS_
* __z__ <kbd>number</kbd> - Amount to zoom.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.get_ortho_scale([cam_id])
Gets the current ortho scale of the camera. (doesn't work for perspective cameras obviously).

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.set_ortho_scale(s, [cam_id])
Sets the current ortho scale of the camera. (doesn't work for perspective cameras obviously).

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.pan(dx, dy, [cam_id])
Moves the camera in it's local X/Y plane.

_PARAMETERS_
* __dx__ <kbd>number</kbd> - Distance to move the camera along its local X axis.
* __dy__ <kbd>number</kbd> - Distance to move the camera along its local Y axis.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.shake(dist, dur, [cam_id])
Shakes the camera in its local X/Y plane. The intensity of the shake will fall off linearly over its duration.

_PARAMETERS_
* __dist__ <kbd>number</kbd> - Radius of the shake.
* __dur__ <kbd>number</kbd> - Duration of the shake in seconds.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.recoil(vec, dur, [cam_id])
Recoils the camera by the supplied vector, local to the camera's rotation. The recoil will fall off quadratically (t^2) over its duration.

_PARAMETERS_
* __vec__ <kbd>vector3</kbd> - Initial vector to offset the camera by, local to the camera's rotation.
* __dur__ <kbd>number</kbd> - Duration of the recoil in seconds.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.stop_shaking([cam_id])
Cancel's all current shakes and recoils for this camera.

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.follow(target_id, [allowMultiFollow], [cam_id])
Makes the camera follow a game object. Lerps by default (see `rendercam.follow_lerp_func` below). If you want the camera to rigidly follow a game object it is better to just make the camera a child of that object. You can tell a camera to follow multiple game objects, in which case it will move toward the average of their positions. Note that the camera follow function only affects the camera's X and Y coordinates, so it only makes sense for 2D-oriented games.

_PARAMETERS_
* __target_id__ <kbd>hash</kbd> - ID of the game object to follow.
* __allowMultiFollow__ <kbd>bool</kbd> - If true, will add `target_id` to the list of objects to follow instead of replacing all previous targets.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.unfollow(target_id, [cam_id])
Makes the camera stop following a game object. If the camera was following multiple objects, this will remove `target_id` from the list, otherwise it will stop the camera from following anything.

_PARAMETERS_
* __target_id__ <kbd>hash</kbd> - ID of the object to unfollow.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

#### rendercam.follow_lerp_func(curPos, targetPos, dt)
```
function M.follow_lerp_func(curPos, targetPos, dt)
    return vmath.lerp(dt * M.follow_lerp_speed, curPos, targetPos)
end
```

This is the default follow lerp function used by all cameras. Feel free to overwrite it if you need different behavior.

_PARAMETERS_
* __curPos__ <kbd>vector3</kbd> - The camera's current position, local to its parent.
* __targetPos__ <kbd>vector3</kbd> - The average position of all follow targets---the exact position of the target if there is only one.
* __dt__ <kbd>number</kbd> - Delta time for this frame.

## Transform Functions

#### rendercam.screen_to_viewport(x, y, [delta])
Transforms `x` and `y` from screen coordinates to viewport coordinates. This only does something when you are using a fixed aspect ratio camera. Otherwise the viewport and the window are the same size. Called internally by `rendercam.screen_to_world_ray` and `rendercam.screen_to_world_2d`.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X.
* __y__ <kbd>number</kbd> - Screen Y.
* __delta__ <kbd>bool</kbd> - If `x` and `y` are for a delta (change in) screen position, rather than an absolute screen position.

_RETURNS_
* __x__ <kbd>number</kbd> - Viewport X.
* __y__ <kbd>number</kbd> - Viewport Y.

#### rendercam.screen_to_world_2d(x, y, [delta], [worldz])
Transforms `x` and `y` from screen coordinates to world coordinates at a certain Z position---either a specified `worldz` or by default the current camera's "2d World Z". This function returns a position on an X/Y plane at the specified Z. For full 3D games it often makes more sense to cast a ray out from the camera to check what object is under a point on the screen. For that, use `rendercam.screen_to_world_ray()`.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X
* __y__ <kbd>number</kbd> - Screen Y
* __delta__ <kbd>bool</kbd> - If `x` and `y` are for a delta (change in) screen position, rather than an absolute screen position.
* __worlds__ <kbd>number</kbd> - World Z position to find the X and Y coordinates at. Defaults to the current camera's "2d World Z" setting.

_RETURNS_
* __pos__ <kbd>vector3</kbd> - World position.

#### rendercam.screen_to_world_ray(x, y)
Takes `x` and `y` screen coordinates and returns two points describing the start and end of a ray from the camera's near plane to its far plane, through that point on the screen. You can use these points to cast a ray to check for collisions "underneath" the mouse cursor, or any other screen point.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X
* __y__ <kbd>number</kbd> - Screen Y

_RETURNS_
* __start__ <kbd>vector3</kbd> - Start point on the camera near plane, in world coordinates.
* __end__ <kbd>vector3</kbd> - End point on the camera far plane, in world coordinates.

#### rendercam.world_to_screen(pos, [adjust])
Transforms the supplied world position into screen (viewport) coordinates. Can take an optional `adjust` parameter to calculate an accurate screen coordinate for a gui node with any adjust mode: Fit, Zoom, or Stretch.

_PARAMETERS_
* __pos__ <kbd>vector3</kbd> - World position.
* __adjust__ <kbd>constant</kbd> - GUI adjust mode to use for calculation.
    * You can use
	    * gui.ADJUST_FIT
		* gui.ADJUST_ZOOM
		* gui.ADJUST_STRETCH
	* Or
	    * rendercam.GUI_ADJUST_FIT
		* rendercam.GUI_ADJUST_ZOOM
		* rendercam.GUI_ADJUST_STRETCH

_RETURNS_
* __pos__ <kbd>vector3</kbd> - Screen position

## Custom Render Scripts
For a lot of projects you will want to write your own custom render script, to mess with material predicates, use render targets, etc. You can definitely do that with Rendercam. Just copy the "rendercam.render_script" out of the rendercam folder, hook it up, and change whatever you want in it. The Rendercam render script is not very complicated, all the real work is done in the rendercam module. As long as you don't change the view, projection, or viewport stuff, you should be able to do whatever you want without interfering with Rendercam.

## GUI and Fixed Aspect Ratios
If you're using a fixed aspect ratio camera, presumably at some point your viewport will be smaller than the actual window (you will have black bars). Unfortunately, if you want your GUI to stay inside the viewport, Defold's nice system of anchors and adjust modes aren't really set up to deal with that. All the automatic GUI adjustments are based on the size of the full window. The best option I've found is to set your game.project display resolution to match your aspect ratio and build your gui inside the guide box that the editor shows you, leaving all the nodes' X and Y anchors set to "None" (i.e. Center). This way, however the display size changes, the GUI nodes should stay at the correct positions inside the viewport.
