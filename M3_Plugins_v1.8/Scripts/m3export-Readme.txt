M3 Export v0.22 3ds Max 2010 Plug-in
by NiNtoxicated

A Starcraft 2 Model (.M3) exporter for 3ds Max 2010. 
Currently Exports:
- Geometry
- Materials
- Skin/Bones
- Animation
- Attachments

If you use any of the code within the script, please provide credit where it's due.

============================
=   Install instructions   =
============================
1. Must have 3ds max installed
2a. Extract the m3_import script (.ms) into your 3ds max '...\Scripts' directory, optionally you can place the script in your '...\Scripts\Startup\' directory to have it automatically load when you launch 3ds Max.
2b. If you want to use Starcraft 2 objects in max (custom materials, maps) then place 'sc2_objects.ms' into your 3ds max '...\Plugins' directory.
3. Click on the hammer icon on the default right hand side pane, and click on the MAXScript button. If you didn't have 3ds max automatically load it upon launch, click 'Run Script' from the rollout dialog and locate the script.
4. Select 'M3 - Export' from the Utilities drop down menu. 
5. Click the 'Export' button!

Enjoy!


========================================
=    Setting up an exportable model    =
========================================
* Exported geometry must be of 'Editable Mesh' type
* Attachments can be added to a scene through the Create tab within the Helpers tab in the 'Starcraft 2 Objects' group.
* Material type must be 'Starcraft 2', 'Standard',  or 'Multimaterial' type.
* Use the 'Starcraft 2' Material for extra tweakable settings. Same goes for 'Starcraft 2 Map' for bitmaps. (Highly Recommended that you use these!)
* A 'Skin' modifier must be applied to your mesh to weight vertices to bones for animations.
* When exporting bones, the base frame represents the frame vertices are bound to their bones and the bind pose frame represents the standard pose of the model for animations.
* When animating, ensure you have a start frame and an end frame animation for the bone you wish to animate to avoid unwanted interpolations.
* For rotation keyframes, ensure you have a keyframe every 90 degrees or less of rotation.


======================
=   Special Thanks   =
======================
Blue Isle Studios (http://blueislestudios.com/)
Big thanks to the support provided by these guys. Check them out!

Volcore (http://volcore.limbicsoft.com/):
For help with vertice flags and initial architecture of the M3 format

Teal (starcraft.incgamers.com):
For UV's and his PHP converter source, helped with geometry importing

Witchsong (http://code.google.com/p/libm3/):
Providing a great open source library for documenting the M3 file format and designing the 
M3->Obj converter. Head to http://code.google.com/p/libm3/ for more M3 file spec details.
Helped immensely figuring out the details of the M3 file format.

Sixen (http://www.sc2mapster.com/):
An awesome website for hosting SC2 development tools and vast XML documentation.
Head there and check it out!

der_ton (http://www.doom3world.org/):
Has done some incredible work with the MD5 format. Alot of his work has been adapted for
the M3 file format with great success. Big thanks goes out to him!

Skizot: For testing and providing suggestions to improve the script, very big thanks

Phygit: Providing bug fixes and development information to do with the M3 format

MrMoonKr: Providing a toUpper function to fix 3ds max incompatibility issues

ufoZ: One of the original crew to reverse engineer the M2 format and provide a good maxscript importer from which my importer/exporters are based. Huge thanks to his efforts.


=======================
=   Version History   =
=======================
0.22 - March 5th 2011
Added particle emitter support
Added custom bounding sphere support
Added attachment volume support
Added bitmap animation support
Improved vertex normal exporting slightly
Global animations no longer exported as they aren't currently supported
Many miscellaneous fixes and code improvements

0.21b - November 22 2010
Fixed a bitmap bug that affected cloaking

0.21 - August 15th 2010
Animation data storage object no longer exported as bone

0.20 - August 5th 2010
Normals/Smoothing groups are now exported properly
Emissive maps should now work properly

0.19b - July 24th 2010
Improved bounding sphere calculation to include all meshes in the scene
Improved the way process time is output
Added sc2_objects.ms error catching
Fixed vertex weighting bug

0.19 - July 15th 2010
Fixed zero weights issue
Added custom map support
Removed redundant 'Use Internal Texture Path' option
Fixed crash when hidden objects were used as bones
Added scene UI options for frozen and hidden objects

0.18 - June 28th 2010
Added exporting multiple meshes as submeshes support
Added Starcraft 2 attachment object support
Added decal support
Added terrain (null) material type support
Object export code heavily reworked, all objects now export as bones
Export no longer requires all bone objects added to skin modifiers
Sequences are now exported based on all animation ranges

0.17 - June 14th 2010
Fixed rotation sometimes not exporting properly
Added some basic message boxes for key events

0.16b - June 12th 2010
Fixed incorrect skin bone assignment

0.16 - June 9th 2010
Alpha Mask cutout threshold now works correctly
Bone animation is now supported
Updated bone chain processing
Added custom vertex normals support
Many code fixes and updates

0.14 - May 28th 2010
Added Alpha Mask map support
Added bone support
Added baseframe and bindpose support
Added attachment support
Vastly improved mesh processing

0.09 - May 17th 2010
Incompatibility error with old 3ds max versions fixed (thanks to MrMoonKr)
Improved material handling
Improved code stability

0.08 - May 12th 2010
Added support for sc2 material and bitmap plugin objects
Fixed error with matid's being out of range crashing exporter
Improved material code
Added more error catching

0.07 - May 5th 2010
Added some additional UI elements
Fixed texture path processing

0.06 - May 1st 2010
Basic UI added
Some basic error catching added

0.04 - April 30th 2010
Adapted to new MD34 format
Basic geometry exporting implemented
Bounding sphere exporting added

0.01 - April 12th 2010
Initial version of M3 export script

