# Rendercam
A universal render script & camera package for all the common camera types: perspective or orthographic, fixed aspect ratio or unfixed aspect ratio, plus four options for how the view changes for different resolutions and window sizes, and more. Also does screen-to-world and world-to-screen transforms for any camera type; camera switching, zooming, panning, shaking, recoil, and lerped following.

---

## Installation

Install Rendercam in your project by adding it as a [library dependency](https://www.defold.com/manuals/libraries/). Open your game.project file and in the "Dependencies" field under "Project", add:
```
https://github.com/rgrams/rendercam/archive/v1.0.2.zip
```

Then open the "Project" menu of the editor and click "Fetch Libraries". You should see the "rendercam" folder appear in your assets panel after a few moments.

## Basic Setup

After installation, it just takes two simple steps to get Rendercam up and running.

1. Select the Rendercam render script in your game.project file. Under "bootstrap", edit the "Render" field and select "/rendercam/rendercam.render".
2. Add a Rendercam camera to your scene. Add "camera.go" from the rendercam folder to your main collection. It can be a child of another game object, or not, but make sure it's z-position is zero (this is for the default camera settings only).

> Note: the "shared_state" setting must also be enabled in your game.project file for Rendercam to work, but it is enabled by default.

## Camera Name Conflicts

Rendercam identifies cameras by their URL "path" or "ID". Normally this means you don't have to worry about name collisions. However, if you use collection proxies, it's possible to have two cameras with identical IDs, so you will need to rename one of them. If you have a camera named "camera" in your main collection, and another, also named "camera", in a collection you load via proxy, this will cause a name conflict with Rendercam.

If either of the cameras is inside a secondary collection with a different name, there will be no conflict, it's only an issue if they are both in the base level of their collections (or in identically-named sub-collections).

## Camera Settings

To change your camera settings, expand the camera game object in the outline and select it's script component. In the properties panel you will have a bunch of different options.

#### Active <kbd>bool</kbd>
Whether the camera is initially active or not. If you have multiple cameras you may want to uncheck this property on your secondary cameras to make sure the right camera is used. If you have no active camera a fallback camera will be used for rendering and you will see a message in the console.

#### Orthographic <kbd>bool</kbd>
Leave checked for an orthographic camera, uncheck for a perspective camera. Some other options below are only used if the camera is of one type or the other. For example: FOV is only used by perspective cameras, and Ortho Scale is only used by orthographic cameras.

#### Near Z <kbd>number</kbd>
The distance in front of the camera where rendering will start, relative to the camera's position. This can be any value for orthographic cameras, but must be greater than zero for perspective cameras. -1 is the default for orthographic cameras, 1 is a decent value for perspective cameras.

#### Far Z <kbd>number</kbd>
The distance in front of the camera where rendering will end, relative to the camera's position. Should be greater than Near Z. 1 is the default for orthographic cameras, 1000 is a reasonable value for perspective cameras.

#### View Distance <kbd>number</kbd>
The distance in front of the camera where the game world is located. This is usually 0 for orthographic cameras, or the Z position of a perspective camera for 2.5D games (if the game world is at Z=0). For most perspective cameras (non-fixed FOV), this is the distance at which the view area is measured. The View Distance is subtracted from the camera Z position on init to get the world Z position used for screen-to-world position transforms.

#### FOV (field of view) <kbd>number</kbd>
The field of view for perspective cameras, in degrees. This property is generally unused (and should be left at -1), as the FOV will be calculated based on other settings. If you want a camera with a fixed FOV, make sure "Use View Area" is un-checked, select the "Fixed Height" scale mode, and set FOV to your desired angle. The aspect ratio can be fixed or not.

#### Ortho Scale <kbd>number</kbd>
The initial "zoom"/scale for orthographic cameras. At an ortho scale of 2 the camera will show an area of the world four times as large as it would at scale 1 (both x and y are doubled). Or 1/4 of the area at scale 0.5, etc. See the "View Area" property below to set the initial view area of your camera.

#### Fixed Aspect Ratio <kbd>bool</kbd>
If checked, black bars will be added to the top and bottom or sides of the viewport as necessary so it will always match the aspect ratio you specify via the "Aspect Ratio" property.

#### Aspect Ratio <kbd>vector3</kbd>
The aspect ratio to be used if "Fixed Aspect Ratio" is checked. Use X and Y to enter your desired proportion---i.e. X=16, Y=9 for a 16:9 aspect. A vector is used to enter the ratio so it can be an accurate fraction. The numbers themselves don't matter, just the proportion between them. You can use 1280, 1024 instead of 5, 4, and so on.

#### Use View Area <kbd>bool</kbd>
If checked, the "View Area" setting will be used to calculate the initial area of the world that the camera will show. If not checked, the _current_ window resolution will be used _unless_ you're using a perspective camera and have set "FOV" greater than zero, in which case the camera will start with that FOV instead of calculating a specific area of world. Note that without "Use View Area" checked, the camera will zoom differently on mobile devices with different screen resolutions or if you create a new camera after changing the window size on desktop. 

#### View Area <kbd>vector3</kbd>
The dimensions in world space that the camera will show, if "Use View Area" is checked. They will be measured at the camera's "View Distance" in front of the camera (by default, at Z=0). If using a fixed aspect ratio, the view area Y value will be overwritten based on the X value if they don't match the specified aspect ratio.

### View Scale Modes:
The last four checkbox settings determine the scale mode used to calculate how the view changes anytime the window resolution is changed (including on init if your camera settings don't match your display settings in game.project). Only the first mode checked will be used (and a default is used if none are checked). Note that Fixed Area, Fixed Width, and Fixed Height all work exactly the same if you're using a fixed aspect ratio (since the aspect ratio locks the viewport dimensions together).

#### Expand View
The view area will expand and contract with the window size, keeping the world at the same size on-screen. If you set your camera view area to 800x600, but your game starts with a window size of 1600x900 (as set in game.project), then the view will expand to fill the window and show a 1600x900 area of the world. Likewise if the window size is smaller---the camera will simply show less of the world.

#### Fixed Area
The camera will zoom in or out to show exactly the same _area_ of the game world.  This works great for a wide range of window or display proportions, if you don't need either dimension to be exactly the same for everyone.  

#### Fixed Width
The camera will always show the same width of game world, the height is adjusted to fit. If the window is stretched vertically, it will show more space on top and bottom.

#### Fixed Height
Like "Fixed Width", but switched. The camera will always show the same height of the game world, and the width will vary with the window proportion. If you make the window tall and skinny, you'll see the same distance up and down, but very little side to side.

## Camera Functions
To use the other features of Rendercam you need to call module functions from a script. First, require the rendercam module in your script:
```lua
local rendercam = require "rendercam.rendercam"
```
A lot of Rendercam's functions have optional arguments. These are listed in brackets, `[like_this]`. For example, most of the camera functions have an optional `[cam_id]` argument. You can leave this out and the functions will operate on the current camera.

### rendercam.activate_camera(cam_id)
Activate a different camera. If you have multiple cameras, use this to switch between them, otherwise you don't need it. Cameras with "Active" checked will activate themselves on init.

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object.

### rendercam.zoom(z, [cam_id])
Zoom the camera. If the camera is orthographic, this adds `z * rendercam.ortho_zoom_mult` to the camera's ortho scale. If the camera is perspective, this moves the camera forward by `z`. You can set `rendercam.ortho_zoom_mult` to adjust the ortho zoom speed, or use `rendercam.get_ortho_scale` and `rendercam.set_ortho_scale` for full control.

_PARAMETERS_
* __z__ <kbd>number</kbd> - Amount to zoom.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.get_ortho_scale([cam_id])
Gets the current ortho scale of the camera. (doesn't work for perspective cameras obviously).

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.set_ortho_scale(s, [cam_id])
Sets the current ortho scale of the camera. (doesn't work for perspective cameras obviously).

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.pan(dx, dy, [cam_id])
Moves the camera in it's local X/Y plane.

_PARAMETERS_
* __dx__ <kbd>number</kbd> - Distance to move the camera along its local X axis.
* __dy__ <kbd>number</kbd> - Distance to move the camera along its local Y axis.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.shake(dist, dur, [cam_id])
Shakes the camera in its local X/Y plane. The intensity of the shake will fall off linearly over its duration.

_PARAMETERS_
* __dist__ <kbd>number</kbd> - Radius of the shake.
* __dur__ <kbd>number</kbd> - Duration of the shake in seconds.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.recoil(vec, dur, [cam_id])
Recoils the camera by the supplied vector, local to the camera's rotation. The recoil will fall off quadratically (t^2) over its duration.

_PARAMETERS_
* __vec__ <kbd>vector3</kbd> - Initial vector to offset the camera by, local to the camera's rotation.
* __dur__ <kbd>number</kbd> - Duration of the recoil in seconds.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.stop_shaking([cam_id])
Cancels all current shakes and recoils for this camera.

_PARAMETERS_
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.follow(target_id, [allowMultiFollow], [cam_id])
Makes the camera follow a game object. Lerps by default (see `rendercam.follow_lerp_func` below). If you want the camera to rigidly follow a game object it is better to just make the camera a child of that object. Set `rendercam.follow_lerp_speed` to adjust the global camera follow speed (default: 3). You can tell a camera to follow multiple game objects, in which case it will move toward the average of their positions. Note that the camera follow function only affects the camera's X and Y coordinates, so it only makes sense for 2D-oriented games.

_PARAMETERS_
* __target_id__ <kbd>hash</kbd> - ID of the game object to follow.
* __allowMultiFollow__ <kbd>bool</kbd> - If true, will add `target_id` to the list of objects to follow instead of replacing all previous targets.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.unfollow(target_id, [cam_id])
Makes the camera stop following a game object. If the camera was following multiple objects, this will remove `target_id` from the list, otherwise it will stop the camera from following anything.

_PARAMETERS_
* __target_id__ <kbd>hash</kbd> - ID of the object to unfollow.
* __cam_id__ <kbd>hash</kbd> - ID of the camera game object. Uses the current camera by default.

### rendercam.follow_lerp_func(curPos, targetPos, dt)
```lua
function M.follow_lerp_func(curPos, targetPos, dt)
    return vmath.lerp(dt * M.follow_lerp_speed, curPos, targetPos)
end
```

This is the default follow lerp function used by all cameras. Feel free to overwrite it if you need different behavior. If you need more complex control or different behavior for each camera, you should ignore Rendercam's follow feature and move your cameras directly, as you would any other game object.

_PARAMETERS_
* __curPos__ <kbd>vector3</kbd> - The camera's current position, local to its parent.
* __targetPos__ <kbd>vector3</kbd> - The average position of all follow targets---the exact position of the target if there is only one.
* __dt__ <kbd>number</kbd> - Delta time for this frame.

## Window Update Listeners

Sometimes you may have scripts or shaders that need to be updated when the window or camera is changed. The following module functions let you add and remove items from a list of URLs that will be sent the following message whenever the window is resized or the camera is switched:

### window_update

_FIELDS_
* __window__ <kbd>vector3</kbd> - The same as `rendercam.window`. The new size of the window.
* __viewport__ <kbd>table</kbd> - The same as `rendercam.viewport`. Contains:
	* __x__ <kbd>number</kbd> - The viewport X offset (black bar width) for fixed aspect ratio cameras.
	* __y__ <kbd>number</kbd> - The viewport Y offset (black bar height) for fixed aspect ratio cameras.
	* __width__ <kbd>number</kbd> - The viewport width.
	* __height__ <kbd>number</kbd> - The viewport height.
* __aspect__ <kbd>number</kbd> - The aspect ratio of the camera.
* __fov__ <kbd>number</kbd> - The field of view of the camera in radians. Should be -1 for orthographic cameras.

### rendercam.add_window_listener(url)

Register a URL to be sent a message when the window is updated.

Example:
```lua
function init(self)
	self.url = msg.url()
	rendercam.add_window_listener(self.url)
end
```

_PARAMETERS_
* __url__ <kbd>string | url</kbd> - The URL. Note: If using a string, this must be an absolute URL including the socket.

### rendercam.remove_window_listener(url)

Remove a URL from the list of window update listeners. If you added a listener, make sure you remove it before the script is destroyed.

To continue the above example:
```lua
function final(self)
	rendercam.remove_window_listener(self.url)
end
```

_PARAMETERS_
* __url__ <kbd>string | url</kbd> - The URL. This must be the same address and type that you passed to 'add_window_listener'. If you added a string, you must remove a string.

## Transform Functions

### rendercam.screen_to_viewport(x, y, [delta])
Transforms `x` and `y` from screen coordinates to viewport coordinates. This only does something when you are using a fixed aspect ratio camera. Otherwise the viewport and the window are the same size. Called internally by `rendercam.screen_to_world_ray` and `rendercam.screen_to_world_2d`.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X.
* __y__ <kbd>number</kbd> - Screen Y.
* __delta__ <kbd>bool</kbd> - If `x` and `y` are for a delta (change in) screen position, rather than an absolute screen position.

_RETURNS_
* __x__ <kbd>number</kbd> - Viewport X.
* __y__ <kbd>number</kbd> - Viewport Y.

### rendercam.screen_to_world_2d(x, y, [delta], [worldz], [raw])
Transforms `x` and `y` from screen coordinates to world coordinates at a certain Z position—either a specified `worldz` or by default the current camera's "2d World Z". This function returns a position on a plane perpendicular to the camera angle, so it's only accurate for 2D-oriented cameras (facing along the Z axis). It works for 2D-oriented perspective cameras, but will have some small imprecision based on the size of the view depth (farZ - nearZ). For 3D cameras, use `rendercam.screen_to_world_plane` or `rendercam.screen_to_world_ray`. Set the [raw] parameter to true to return raw x, y, and z values instead of a vector. This provides a minor performance improvement since returning a vector creates more garbage for the garbage collector.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X
* __y__ <kbd>number</kbd> - Screen Y
* __delta__ <kbd>bool</kbd> - If `x` and `y` are for a delta (change in) screen position, rather than an absolute screen position.
* __worldz__ <kbd>number</kbd> - World Z position to find the X and Y coordinates at. Defaults to the current camera's "2d World Z" setting.
* __raw__ <kbd>bool</kbd> - If the function should return a vector (nil/false), or return raw x, y, and z values (true)

_RETURNS if raw is nil/false_
* __pos__ <kbd>vector3</kbd> - World position.

_RETURNS if raw is true_
* __x__ <kbd>number</kbd> - World position X.
* __y__ <kbd>number</kbd> - World position Y.
* __z__ <kbd>number</kbd> - World position Z.

### rendercam.screen_to_world_ray(x, y, [raw])
Takes `x` and `y` screen coordinates and returns two points describing the start and end of a ray from the camera's near plane to its far plane, through that point on the screen. You can use these points to cast a ray to check for collisions "underneath" the mouse cursor, or any other screen point. Set the [raw] parameter to true to return raw x, y, and z values instead of vectors. This provides a minor performance improvement since returning vectors creates more garbage for the garbage collector.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X
* __y__ <kbd>number</kbd> - Screen Y
* __raw__ <kbd>bool</kbd> - If the function should return vectors (nil/false), or return raw x, y, and z values (true)

_RETURNS if raw is nil/false_
* __start__ <kbd>vector3</kbd> - Start point on the camera near plane, in world coordinates.
* __end__ <kbd>vector3</kbd> - End point on the camera far plane, in world coordinates.

_RETURNS if raw is true_
* __x1__ <kbd>number</kbd> - X value of start point on the camera near plane, in world coordinates.
* __y1__ <kbd>number</kbd> - Y value of start point on the camera near plane, in world coordinates.
* __z1__ <kbd>number</kbd> - Z value of start point on the camera near plane, in world coordinates.
* __x2__ <kbd>number</kbd> - X value of end point on the camera far plane, in world coordinates.
* __y2__ <kbd>number</kbd> - Y value of end point on the camera far plane, in world coordinates.
* __z2__ <kbd>number</kbd> - Z value of end point on the camera far plane, in world coordinates.

### rendercam.screen_to_world_plane(x, y, planeNormal, pointOnPlane)
Gets the screen-to-world ray and intersects it with a world-space plane. The equivalent of `rendercam.screen_to_world_2d` for 3D cameras. Note: this will return `nil` if the camera angle is exactly parallel to the plane (perpendicular to the normal).

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X
* __y__ <kbd>number</kbd> - Screen Y
* __planeNormal__ <kbd>vector3</kbd> - Normal vector of the plane
* __pointOnPlane__ <kbd>vector3</kbd> - A point on the plane

_RETURNS_
* __pos__ <kbd>vector3 | nil</kbd> - World position or `nil` if the camera angle is parallel to the plane.

### rendercam.screen_to_gui(x, y, adjust, [isSize])
Transforms `x` and `y` from screen coordinates to GUI coordinates. If the window size has changed and your GUI has "Adjust Reference" set to "Per Node", GUI coordinates will no longer match screen coordinates, and they will be different for each adjust mode.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X
* __y__ <kbd>number</kbd> - Screen Y
* __adjust__ <kbd>constant</kbd> - GUI adjust mode to use for calculation.
    * You can use
	    * gui.ADJUST_FIT
		* gui.ADJUST_ZOOM
		* gui.ADJUST_STRETCH
	* Or
	    * rendercam.GUI_ADJUST_FIT
		* rendercam.GUI_ADJUST_ZOOM
		* rendercam.GUI_ADJUST_STRETCH
	* _Or_
		* The result of `gui.get_adjust_mode`
* __isSize__ <kbd>bool</kbd> - Optional argument. If the coordinates to be transformed are a node size rather than a position. False by default.

_RETURNS_
* __x__ <kbd>number</kbd> - GUI X
* __y__ <kbd>number</kbd> - GUI Y

### rendercam.screen_to_gui_pick(x, y)
Transforms screen coordinates to coordinates that will work accurately with `gui.pick_node`. If the window size has changed, the coordinate system used by `gui.pick_node` will not match the screen coordinate system. If you are only picking nodes underneath a touch or the mouse cursor, you don't need this function, just use `action.x` and `action.y` in your `on_input` function. You _will_ need this function to use `gui.pick_node` with an arbitrary point on the screen (if the window has been changed from it's initial setting). The adjust mode of the GUI node does not matter.

_PARAMETERS_
* __x__ <kbd>number</kbd> - Screen X
* __y__ <kbd>number</kbd> - Screen Y

_RETURNS_
* __x__ <kbd>number</kbd> - X
* __y__ <kbd>number</kbd> - Y

### rendercam.world_to_screen(pos, [adjust], [raw])
Transforms the supplied world position into screen (viewport) coordinates. Can take an optional `adjust` parameter to calculate an accurate screen coordinate for a gui node with any adjust mode: Fit, Zoom, or Stretch. Set the [raw] parameter to true to return raw x, y, and z values instead of a vector. This provides a minor performance improvement since returning a vector creates more garbage for the garbage collector.

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
	* _Or_
		* The result of `gui.get_adjust_mode`
* __raw__ <kbd>bool</kbd> - If the function should return a vector (nil/false), or return raw x, y, and z values (true)

_RETURNS if raw is nil/false_
* __pos__ <kbd>vector3</kbd> - Screen position

_RETURNS if raw is true_
* __x__ <kbd>number</kbd> - Screen position X.
* __y__ <kbd>number</kbd> - Screen position Y.
* __z__ <kbd>number</kbd> - Screen position Z.

## Custom Render Scripts
For a lot of projects you will want to write your own custom render script, to mess with material predicates, use render targets, etc. You can definitely do that with Rendercam. Just copy the "rendercam.render_script" out of the rendercam folder, hook it up, and change whatever you want in it. The Rendercam render script is not very complicated, all the real work is done in the rendercam module. As long as you don't change the view, projection, or viewport stuff, you should be able to do whatever you want without interfering with Rendercam.

## GUI and Fixed Aspect Ratios
If you're using a fixed aspect ratio camera, presumably at some point your viewport will be smaller than the actual window (you will have black bars). Unfortunately, if you want your GUI to stay inside the viewport, Defold's nice system of anchors and adjust modes aren't really set up to deal with that. All the automatic GUI adjustments are based on the size of the full window. The best option I've found is to set your game.project display resolution to match your aspect ratio and build your gui inside the guide box that the editor shows you, leaving all the nodes' X and Y anchors set to "None" (i.e. Center). This way, however the display size changes, the GUI nodes should stay at the correct positions inside the viewport.

## Error Messages
If you try to do something that Rendercam doesn't support, you will hopefully get a reasonably clear error message in the console. See below for further explanation of a few of them. If you get errors with Rendercam that you don't understand, please report them in the [forum thread](https://forum.defold.com/t/rendercam-universal-camera-library/12877) or a [Github issue](https://github.com/rgrams/rendercam/issues) so I can help you out and improve Rendercam.

> "NOTE: rendercam - No active camera found this frame...using fallback camera. There will be no more warnings about this."

This is not really an error message, just a notification to make sure you know what's going on. It means that for at least one frame you have left Rendercam without an active camera, so it's using the default fallback camera to render with. This will happen if your game content is all loaded through collection proxes (such as if you are using [Monarch](https://www.defold.com/community/projects/88415/)) because it takes a few frames to load the proxies. It will also happen if you forgot to put a camera in your collection, if you un-checked "active" on your camera's properties, or if you deactivated or deleted all your cameras from a script. This message will only print once, the first time it happens, so it won't spam your console if it's the intended behavior.

> "WARNING: rendercam.activate_camera() - camera [cam_id] not found. "

This means you called `rendercam.activate_camera(cam_id)` with an ID that doesn't match any existing camera. Make sure you are using [`go.get_id`](https://www.defold.com/ref/go/#go.get_id:-path-) with the correct path to get the camera's ID.

>"ERROR: rendercam.camera_init() - Camera name conflict with ID: [cam_id]".
> New camera will overwrite the old! Your cameras must have unique IDs."

This means you have two cameras with identical IDs, you just need to rename one of them. This should only happen if you are using collection proxies, see the section on "Camera Name Conflicts" near the top of this readme.

> "rendercam - get_target_worldViewSize() - camera: [cam_id], scale mode not found."

Hopefully no one will ever get this message. It means something is broken and your camera has an invalid scale mode set. Please let me know if this happens.
