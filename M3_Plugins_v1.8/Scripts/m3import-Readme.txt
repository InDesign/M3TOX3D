M3 Import v0.30 3ds Max 2010 Plug-in
by NiNtoxicated

A Starcraft 2 Model (.M3) importer for 3ds Max 2010. 
Currently Imports:
- Geometry
- Bones
- Materials
- Animation
- Attachments

If you use any of the code in the script, please provide credit where it's due.

============================
=   Install instructions   =
============================
1. Must have 3ds max installed

2a. Extract the script (.ms) into your 3ds max '...\Scripts' directory, optionally you 
can place the script in your '...\Scripts\Startup\' directory to have it automatically load 
when you launch 3ds Max.

2b. Extract sc2_plugins.ms into your 3ds max '...\Plugins' directory to be able to use the
animation user interface.

3. Click on the hammer icon on the default right hand side pane, and click on the MAXScript 
button. If you didn't have 3ds max automatically load it upon launch, click 'Run Script' from 
the rollout dialog and locate the script.

4. Select 'M3 - Import' from the Utilities drop down menu. From there, use the UI to locate 
the M3 you wish to import and so on.

Note: When importing models, .dds maps can be automatically applied to the model but you must first 
setup a map path in 3ds max. To do this, use the menu 'Customize->Configure User Paths...', 
click on the 'External Files' tab and add the path. The script will check each path until it 
finds the correct map.

5. Control the Animation Sequences through 'M3 - Sequences' found in the utilities drop down 
menu.

Enjoy!


==================
=   Known bugs   =
==================
* 3ds Max can be slow importing some of the larger models if you choose to import animation sequences. This is due to the inherently sluggish nature of maxscript, import animations at your own peril.

* Very minor errors in some animations.

* Vertex normals at the moment are SLOW to import due to 3ds max being crappy about how to manually set them. For high poly models it will slow down the import considerably.


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
0.31 - March 5th 2011
Added particle emitter support
Added custom bounding sphere support
Attachment wireframe improved to reflect orientation
Attachment volumes now imported
Animated bitmap settings now imported
UI improvements, added additional options
Miscellaneous code and bug fixes
Lots of code restructuring

0.30 - August 15th 2010
No longer crashes on certain models

0.29 - August 5th 2010
Corrected animation bug

0.28b - 24th July 2010
Improved the way process time is output
Removed conflicting function with the m2 importer
Added sc2_objects.ms error catching

0.28 - July 15th 2010
Rotations now use linear rotation controllers
Gimbal lock no longer affects animations
Added custom map support
Additional bitmap settings now supported
Improved zoom to model after import

0.27 - June 28th 2010
Added decal support
Added terrain (null) material type support
Submeshes now import as multiple meshes
Meshes now skinned with just the bones that affect its vertices
Attachments now import as Starcraft 2 attachment objects
Attachments replace the bone they are attached to on import

0.26 - June 14th 2010
Animations now import correctly for most models
Fixed attachments sometimes not binding to their bones properly
Added some basic message boxes for key events

0.25 - June 9th 2010
Imports additional M3 animation data
Attachments now imported as dummy boxes
Animations now import faster
Small code fixes

0.24 - May 28th 2010
Improved bindpose handling, now includes baseframe
Various code fixes

0.22 - May 17th 2010
Added attachment support
Added sc2objects support, can now use custom materials/maps
Incompatibility error with old 3ds max versions fixed (thanks to MrMoonKr)

0.21 - May 7th 2010
Fixed wrong textures being applied to some models
Fixed missing materials dialog duplicate error
Added reflection map support
Added code to deal with vertex flags
Added vertex normals UI option
Specular level now being set from material data

0.20 - April 30th 2010
Added bindpose buffers for each animation, helps prevent weird translation across animations
Vertex normals now manually set properly (at the expense of processing time :( )
Code syntax improvements

0.18 - April 25th 2010
Added support for new MD34 model format
Bones now animate correctly


0.14 - April 10th 2010
Aligned all submeshes to their appropriate bones 
Skinned vertex positioning now based on all weighted bones (thanks to MD5 documentation)
Improved animation processing times (bones animated before vertex skinning)


0.13 - April 1st 2010
Mesh now binds to bones properly for most models.

0.11 - March 30th 2010
Updated Sequence support
Added Sequence UI for navigating sequences
Shift to more object orientated coding

0.098 - March 26th 2010
Added queryBox error for missing textures before creating any scene objects
Updated some of the code regarding sequence data
Minor code improvements

0.096 - March 22nd 2010
Fixed bump mapping (sets to 100 now)

0.095 - March 21st 2010
Some basic error catching added
Fixed initial bone errors

0.09 - March 20th 2010
Added primitive animation support
Code housekeeping
Updated code, improved processing time

0.06 - March 13th 2010
Added rollout menu

0.05 - March 11th 2010
Added bone support, however mesh not binding to bones properly yet

0.04 - March 6th 2010
Major overhaul of code
Reworked tag reading and reference reading, can now read nested structures
Vastly improved material reading

0.03 - March 4th 2010
Vertice normals added 
Added material importing

0.02 - February 29th 2010 - March 2nd 2010
Made significant improvements to structures and accessing file data
Can now (hopefully) import UV data
Added submesh functionality

0.01 - February 26th 2010
Initial version of M3 import script


