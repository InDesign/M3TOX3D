------------------------------------------------------------------------------------------------
-- Starcraft 2 Model (3ds->M3) Exporter version 0.22
-- by NiNtoxicated (madyavic@gmail.com)
-- Exports M3 models from 3ds max via maxscript
-- Created for 3ds max 2010, but should be backwards compatible (3ds Max 9 SP2 onward)
-- Based on reworked code from my World of Warcraft M2 importer/exporter
--
-- Currently exports:
-- - Geometry
-- - Materials
-- - Skin/Bones
-- - Animations
-- - Attachments
--
-- Setting up an exportable model:
-- 1. Create 'editable_mesh' type meshes
-- 2. Apply materials of type Starcraft 2, Standard or Multimaterial to them
-- 3. Export!
--
-- Big thanks to: 
-- Blue Isle Studios (http://blueislestudios.com/) - Big thanks to the support provided by these guys. Check them out!
-- Teal (starcraft.incgamers.com) - PHP M3 parser
-- Volcore (http://volcore.limbicsoft.com/)  - Helped figure out vertex flags
-- Witchsong (http://code.google.com/p/libm3/) - Awesome M3 library and for help on sequence data
-- Sixen (http://www.sc2mapster.com/) - Providing a good central resource for SC2 tools
-- der_Ton (http://www.doom3world.org/) - Great work on MD5 format which is similar to M3
-- MrMoonKr - Providing a toUpper function to fix 3ds max incompatibility issues
-- Skizot - For testing and providing suggestions to improve the script, very big thanks
-- Phygit - Providing bug fixes and development information to do with the M3 format
-- ufoZ - One of the original people to reverse engineer the M2 format and provide a good maxscript importer
-- 			from which my importer/exporters were originally based
-- Check out http://code.google.com/p/libm3/ for more indepth detail about the M3 format
-- Head to http://www.sc2mapster.com/ for more mod tools and Starcraft 2 content
--
-- If you use any of this code in your own scripts, please credit where it is due.
--
-- Things to do:
-- 1. Clean up messy code
-- 2. Implement 3dsMax GUI properly
-- 3. Add good animation support
-- 4. Improve code functionality
-- 5. Improve processing times
-- 6. Add more feature support
-- 7. Improve error catching and error support
--
------------------------------------------------------------------------------------------------
--
-- Version History:
-- 0.22 - March 5th 2011
-- Added particle emitter support
-- Added custom bounding sphere support
-- Added attachment volume support
-- Added bitmap animation support
-- Improved vertex normal exporting slightly
-- Global animations no longer exported as they aren't currently supported
-- Many miscellaneous fixes and code improvements
--
-- 0.21b - November 22 2010
-- Fixed a bitmap bug that affected cloaking
--
-- 0.21 - August 15th 2010
-- Animation data storage object no longer exported as bone
--
-- 0.20 - August 5th 2010
-- Normals/Smoothing groups are now exported properly
-- Emissive maps should now work properly
--
-- 0.19b - July 24th 2010
-- Improved bounding sphere calculation to include all meshes in the scene
-- Improved the way process time is output
-- Added sc2_objects.ms error catching
-- Fixed vertex weighting bug
--
-- 0.19 - July 15th 2010
-- Fixed zero weights issue
-- Added custom map support
-- Removed redundant 'Use Internal Texture Path' option
-- Fixed crash when hidden objects were used as bones
-- Added scene UI options for frozen and hidden objects
--
-- 0.18 - June 28th 2010
-- Added exporting multiple meshes as submeshes support
-- Added Starcraft 2 attachment object support
-- Added decal support
-- Added terrain (null) material type support
-- Object export code heavily reworked, all objects now export as bones
-- Export no longer requires all bone objects added to skin modifiers
-- Sequences are now exported based on all animation ranges
--
-- 0.17 - June 14th 2010
-- Fixed rotation sometimes not exporting properly
-- Added some basic message boxes for key events
--
-- 0.16b - June 12th 2010
-- Fixed incorrect skin bone assignment
--
-- 0.16 - June 9th 2010
-- Alpha Mask cutout threshold now works correctly
-- Bone animation is now supported
-- Updated bone chain processing
-- Added custom vertex normals support
-- Many code fixes and updates
--
-- 0.14 - May 28th 2010
-- Added Alpha Mask map support
-- Added bone support
-- Added baseframe and bindpose support
-- Added attachment support
-- Vastly improved mesh processing 
--
-- 0.09 - May 17th 2010
-- Incompatibility error with old 3ds max versions fixed (thanks to MrMoonKr)
-- Improved material handling
-- Improved code stability
--
-- 0.08 - May 12th 2010
-- Added support for sc2 material and bitmap plugin objects
-- Fixed error with matid's being out of range crashing exporter
-- Improved material code
-- Added more error catching
--
-- 0.07 - May 5th 2010
-- Added some additional UI elements
-- Fixed texture path processing
--
-- 0.06 - May 1st 2010
-- Basic UI added
-- Some basic error catching added
--
-- 0.04 - April 30th 2010
-- Adapted to new MD34 format
-- Basic geometry exporting implemented
-- Bounding sphere exporting added
--
-- 0.01 - April 12th 2010
-- Initial version of M3 export script
--
------------------------------------------------------------------------------------------------

-- ********************
--  SCRIPT DECLARES
-- ********************
-- globals
global head, mwrite, awrite, bstream, cbones, m3model, m3scene
global scrStart, scrEnd -- For script timeStamps
global twrite		= #()

-- Switches
--global g_UseInternalPath = true -- use internal path
global g_flipuvy = true -- Flips uv.y coords

-- Misc. variables
global g_animObj = "_M3_Anim_Data"
global g_mapchannel = 1
global g_bindposeFrame = 0
global g_baseFrame = 1
global g_exportAnimation = true
global g_exportHidden = true
global g_exportFrozen = false
global g_useFPS = 1000
global g_doCustomVertNormals = true -- redundant now
global g_doPEmitters = true

-- Temp. write file
global texPath = "Assets/Textures/"

-- Function Declares
fn M3E_WriteRef bitStream data reftype flags:0 = ()
fn M3E_WriteArray bitStream data flags:#uint32 reftype:#null = ()

-- ***********
--  HELPERS
-- ***********
-- Liberally stolen from my M2 script
fn echo msg =
(
	format "%\n" (msg) to:listener
)

-- math function for comparing two quaternions
fn qdot q1 q2 = return ((q1.x*q2.x) + (q1.y*q2.y) + (q1.z*q2.z) + (q1.w*q2.w))

-- courtesy of MrMoonKr
-- Converts lower case string to uppercase without needing max 2008
fn M3E_toUpper str =
(
   if str == undefined do return undefined

   upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
   lower = "abcdefghijklmnopqrstuvwxyz"

   outstr = copy str

   for i = 1 to outstr.count do
   (
      j = findString lower outstr[i]
      if j != undefined do outstr[i] = upper[j]
   )
   return outstr
)

fn M3E_ArrayToPoint pntArray =
(
	local pnt
	local pntArrayCount = pntArray.count
	case pntArrayCount of
	(
		2:
		(
			pnt = [0, 0]
			
			pnt.x = pntArray[1]
			pnt.y = pntArray[2]
		)
		3:
		(
			-- initialise array
			pnt = [0, 0, 0]
			
			pnt.x = pntArray[1]
			pnt.y = pntArray[2]
			pnt.z = pntArray[3]
		)
		4:
		(
			pnt = [0, 0, 0, 0]
			
			pnt.x = pntArray[1]
			pnt.y = pntArray[2]
			pnt.z = pntArray[3]
			pnt.w = pntArray[4]
		)
	)
	
	return pnt
)

fn M3E_ColourToPoint4 col =
(
	local p4 = [0, 0, 0, 0]
	p4.x = col.blue
	p4.y = col.green
	p4.z = col.red
	p4.w = col.alpha
	
	return p4
)

fn M3E_BoolToInt bool =
(
	if (bool == true) then return 1 else return 0
)
	
fn LongToString num=
(
	local str = ""
	for i = 1 to 4 do
	(
		str += bit.intAsChar (bit.and num 0xff)
		-- num = bit.shift num -8
		num /= 256
	)
	str
)

fn M3E_Convert_Time t =
(
	t * (1000 / g_useFPS)	
)

fn M3E_isInstance obj =
(
	InstanceMgr.GetInstances obj &instances
	
	local objInd = findItem instances obj
	if (objInd < instances.count) then return true else return false
)

fn M3E_Reset_Globals =
(
	head = mwrite = bstream = m3model = awrite = m3scene = undefined
	twrite = #()
	gc()
)

-- Writing Funcs
-- Helpers

fn M3E_WriteVec bitStream vec flags bflags:#null =
(
	case flags of
	(
		#v2d: (writeFloat bitStream vec.x; writeFloat bitStream vec.y;)
		#v3d: (writeFloat bitStream vec.x; writeFloat bitStream vec.y; writeFloat bitStream vec.z;)
		#v3dshort: (writeShort bitStream vec.x #unsigned; writeShort bitStream vec.y #unsigned; writeShort bitStream vec.z #unsigned;)
		#v3dlong: (writeLong bitStream vec.x #unsigned; writeLong bitStream vec.y #unsigned; writeLong bitStream vec.z #unsigned;)
		#v3dbyte: (writeByte bitStream vec.x #unsigned; writeByte bitStream vec.y #unsigned; writeByte bitStream vec.z #unsigned;)
		#v4d: (writeFloat bitStream vec.x; writeFloat bitStream vec.y; writeFloat bitStream vec.z; writeFloat bitStream vec.w;)
		#v4dshort: (writeShort bitStream vec.x #signed; writeShort bitStream vec.y #signed; writeShort bitStream vec.z #signed; writeShort bitStream vec.w #signed;)
		#v4dbyte: (writeByte bitStream vec.x; writeByte bitStream vec.y; writeByte bitStream vec.z; writeByte bitStream vec.w;)
		#v4dbyteFloat: (writeByte bitStream ((vec.x * 255) as integer) #unsigned; writeByte bitStream ((vec.y * 255) as integer) #unsigned; writeByte bitStream ((vec.z * 255) as integer) #unsigned; writeByte bitStream ((vec.w * 255) as integer) #unsigned;)
		#v4dubyte: (writeByte bitStream vec.x #unsigned; writeByte bitStream vec.y #unsigned; writeByte bitStream vec.z #unsigned; writeByte bitStream vec.w #unsigned;)
		#matrix: (M3E_WriteVec bitStream vec.row1 #v4d; M3E_WriteVec bitStream vec.row2 #v4d; M3E_WriteVec bitStream vec.row3 #v4d; M3E_WriteVec bitStream vec.row4 #v4d;)
		#sphere: (M3E_WriteVec bitStream vec.emin #v3d; M3E_WriteVec bitStream vec.emax #v3d; WriteFloat bitStream vec.rad;)
	)
	if (bflags == #MD34) then WriteLong bitStream 0x00 #unsigned
)

fn M3E_WriteBlank bitStream count flags:#buffer ret:false =
(
	local bm = ftell bitStream
	local bcount = 0 -- buffer count

	if (flags != #blank) then
	(
		bcount = (16 - (mod count 16)) -- calculate buffer bytes
		if (mod count 16 == 0) then bcount -= 16 -- so we don't get rows of 16 buffer bytes
	)
	
	case flags of
	(
		#buffer: 
		(
			count = 0 -- don't let it write null data
		)
	)
	
	for i = 1 to (count as integer) do (WriteByte bitStream 0) -- write blank bytes
	for i = 1 to (bcount as integer) do (WriteByte bitStream 0xAA #unsigned) -- write buffer bytes
	if (ret != false) then fseek bitStream bm #seek_set
)

fn FloatToShort &val = -- Float to Short func
(
	if (val > 0) then (val -= 1) else (val += 1)
	val *= 32767.0
)

fn M3E_getSize type flags:0 =
(
	local size
	case type of
	(
		#REF: size = 0x0C
		#AREF: size = 0x20
		#MD33: size = 0x14
		#MD34: size = 0x18
		#MODL:
		(
			case flags of
			(
				23: size = 0x310
			)
		)
		#SEQS: size = 0x60
		#STC_: size = 0xCC
		#SDEV: size = M3E_getSize #AREF
		#SD2V: size = M3E_getSize #AREF
		#SD3V: size = M3E_getSize #AREF
		#SD4Q: size = M3E_getSize #AREF
		#SDR3: size = M3E_getSize #AREF
		#SDS6: size = M3E_getSize #AREF
		#EVNT: size = 0x68
		#VEC2: size = 0x08
		#VEC3: size = 0x0C
		#QUAT: size = 0x10
		#REAL: size = 0x04
		#STG_: size = 0x18
		#STS_: size = 0x1C
		#BONE: size = 0xA0
		#VERT: size = 0x20
		#U16_: size = 0x02
		#I16_: size = 0x02
		#U32_: size = 0x04
		#I32_: size = 0x04
		#CHAR: size = 0x01
		#DIV_: size = 0x34
		#REGN: size = 0x24
		#BAT_: size = 0x0E
		#MSEC: size = 0x48
		#ATT_: size = 0x14
		#ATVL: size = 0x74
		#PAR_: size = 0x524
		#PARC: size = 0x28
		#MATM: size = 0x08
		#MAT_: size = 0x10C
		#TER_: size = 0x18
		#LAYR: size = 0x164
		#IREF: size = 0x40
	)
	
	return size
)

fn M3E_Name name flt ext:undefined =
(
	-- Filter name from path
	local mn = filterString name flt
	mn = mn[mn.count]
	local mext = substring mn (mn.count-3) (4)
	-- Remove extension if specified
	if (ext != undefined) then
	(
		if (matchPattern mext pattern:ext ignoreCase:true) then mn = substring mn 1 (mn.count-4)
	)
	return mn
)

-- ********************
--  MAX STRUCTURES
-- ********************
struct M3E_Model
(
	anims,
	vflags, verts, skin, bones, skinBones, 
	submeshes, usedMats, materials, attachments, pemits, parcs,
	
	fn init =
	(
		local modl = M3E_Model()
		modl.bones = #()
		modl.skinBones = #()
		modl.materials = #()
		modl.attachments = #()
		modl.pemits = #()
		modl.parcs = #()
		
		return modl
	)
)

struct M3E_SceneObjects 
(
	meshes, materials, 
	skin, bones, 
	attachments, pemits, parcs, parcIDs,
	vertFlags, bndSphere,
	
	fn init =
	(
		local sObjs = M3E_SceneObjects()
		sObjs.meshes = #()
		sObjs.materials = #()
		sObjs.skin = #()
		sObjs.bones = #()
		sObjs.attachments = #()
		sObjs.pemits = #()
		sObjs.parcs = #()
		sObjs.parcIDs = #()
		sObjs.vertFlags = 25297021 -- initial vert flags
		
		return sObjs
	)
)

struct M3E_MaxMaterials 
(
	mats = #(), multimats = #(), fullMatList = #()
)

-- **********************************
--  M3 STRUCTURES & FUNCTIONS
-- ********************************** 
struct M3E_Sphere
(
	emin, emax, rad, flags,
	maxObj,
	
	fn init =
	(
		local sph = M3E_Sphere()
		
		sph.emin = sph.emax = [0, 0, 0]
		sph.rad = 0
		sph.flags = 0
		
		return sph
	),
	fn GetBound objs =
	(
		sph = M3E_Sphere.init()
		clearSelection()
		select objs
		sph.emin = selection.min
		sph.emax = selection.max
		local vec3 = selection.max - selection.center
		clearSelection()
		
		local rad = 0
		for i = 1 to 3 do
		(
			-- set radius to highest x, y or z
			if (vec3[i] > rad) then rad = vec3[i]
		)
		-- increase radius slightly...
		rad *= 1.25
		sph.rad = rad
		
		return sph
	)
)

struct M3E_Matrix
(
	row1, row2, row3, row4,
	
	fn init =
	(
		local mat = M3E_Matrix()
		mat.row1 = [1,0,0,0]
		mat.row2 = [0,1,0,0]
		mat.row3 = [0,0,1,0]
		mat.row4 = [0,0,0,1]
		
		return mat
	),
	fn convObjMatrix objMat =
	(
		m3mat = M3E_Matrix.init()
		for i = 1 to 4 do
		(
			for j = 1 to 3 do
			(
				case i of
				(
					1: (m3mat.row1[j] = objMat.row1[j])
					2: (m3mat.row2[j] = objMat.row2[j])
					3: (m3mat.row3[j] = objMat.row3[j])
					4: (m3mat.row4[j] = objMat.row4[j])
				)
			)
		)
		
		return m3mat
	)
)

fn M3E_Name name flt ext:undefined =
(
	-- Filter name from path
	local mn = filterString name flt
	mn = mn[mn.count]
	-- Remove extension if specified
	if (ext != undefined) then
	(
		local extSize = ext.count
		local mext = substring mn (mn.count-(extSize - 1)) (extSize)
		if (matchPattern mext pattern:ext ignoreCase:true) then mn = substring mn 1 (mn.count-(extSize))
	)
	return mn
)

fn M3E_Open fname flags =
(
	step = "Accessing Model File"
	
	echo ("Writing "+fname+"...")
	local bitStream = fopen fname flags
	if bitStream==undefined then 
	(
		echo "File not found!"
		throw "File not found"
	)
	else return bitStream
)

fn M3E_Close bitStream =
(
	step = "Close"
	fclose bitStream
)

struct M3E_Tag -- Tag data
(
	dataID, ofsData, nData, flags,
	
	fn Write bitStream tag =
	(
		-- head to end of file
		fseek bitStream 0 #seek_end
		
		-- Fix Header info
		head.ofsTag = ftell bitStream
		head.nTag = tag.count
		
		-- write tags
		for i = 1 to tag.count do
		(
			t = tag[i]
			writeString bitStream t.dataID -- Write File ID
			fseek bitStream -1 #seek_cur
			writeLong bitStream t.ofsData #unsigned
			writeLong bitStream t.nData #unsigned
			writeLong bitStream t.flags #unsigned
		)
	),
	fn TagAppend bitStream nameID nData tagar flags:0 =
	(
		tag = M3E_Tag()
		local strID = nameID as string
		local tagID = "BLNK" -- Needs to be 4 chars for modification
		for i = 1 to 4 do
		(
			k = 5 - i
			tagID[i] = strID[k]
		)
		tag.dataID = M3E_toUpper tagID -- Uppercase
		tag.ofsData = ftell bitStream
		tag.nData = nData
		tag.flags = flags
		
		append tagar tag
	)
)

struct M3E_Ref
(
	entries, refid, flags = 0, data = #(),
	
	fn Write bitStream ref =
	(
		writeLong bitStream ref.entries #unsigned
		writeLong bitStream ref.refid #unsigned
		WriteLong bitStream ref.flags #unsigned
	)
)

struct M3E_AnimRef -- Animation Reference
(
	flags, animflags, animid, initValue, nullValue,
	
	fn Write bitStream ar type =
	(
		writeShort bitStream ar.flags #unsigned
		writeShort bitStream ar.animflags #unsigned
		writeLong bitStream ar.animid #unsigned
		
		case type of
		(
			#VEC2D:(M3E_WriteVec bitStream ar.initValue #v2d; M3E_WriteVec bitStream ar.nullValue #v2d;)
			#VEC3D:(M3E_WriteVec bitStream ar.initValue #v3d; M3E_WriteVec bitStream ar.nullValue #v3d;)
			#VEC3DSHRT:(M3E_WriteVec bitStream ar.initValue #v3dshort; M3E_WriteVec bitStream ar.nullValue #v3dshort;)
			#VEC4D:(M3E_WriteVec bitStream ar.initValue #v4d; M3E_WriteVec bitStream ar.nullValue #v4d;)
			#COLOUR:(M3E_WriteVec bitStream ar.initValue #v4dubyte; M3E_WriteVec bitStream ar.nullValue #v4dubyte;)
			#UINT32:(writeLong bitStream ar.initValue #unsigned; writeLong bitStream ar.nullValue #unsigned;)
			#UINT16:(writeShort bitStream ar.initValue #unsigned; writeShort bitStream ar.nullValue #unsigned;)
			#FLOAT:(writeFloat bitStream ar.initValue; writeFloat bitStream ar.nullValue;)
			#SPHERE:(M3E_WriteVec bitStream ar.initValue #sphere; M3E_WriteVec bitStream ar.nullValue #sphere;)
		)
		
		M3E_WriteBlank bitStream 0x04 flags:#blank
	),
	fn init type =
	(
		ar = M3E_AnimRef()
		ar.flags = 0
		ar.animflags = 0
		-- random uint32
		ar.animid = Random 1 1e8
		
		local arValue
		
		case type of
		(
			#VEC2D:(arValue = [0, 0])
			#VEC3D:(arValue = [0, 0, 0])
			#VEC3DSHRT:(arValue = [0, 0, 0])
			#VEC4D:(arValue = [0, 0, 0, 1])
			#COLOUR:(arValue = [255, 255, 255, 255])
			#UINT32:(arValue = 0)
			#UINT16:(arValue = 0)
			#FLOAT:(arValue = 0.0)
			#SPHERE:(arValue = M3E_Sphere.init())
		)
		
		ar.initValue = ar.nullValue = arValue
		if (type == #COLOUR) then ar.nullValue = [0, 0, 0, 0]
		
		return ar
	)
)

struct M3E_Header
(
	fileID, ofsTag, nTag, mref = M3E_Ref(),
	
	fn Write bitStream head =
	(
		step = "Write Header"

		fseek bstream 0 #seek_set -- move to beginning of file
		
		writeString bitStream head.fileID -- Write File ID
		fseek bitStream -1 #seek_cur -- writeString writes null terminator...so have to move cursor back one space
		writeLong bitStream head.ofsTag #unsigned
		writeLong bitStream head.nTag #unsigned
		M3E_Ref.Write bitStream head.mref
	),
	fn init =
	(
		h = M3E_Header()
		-- Fixed file magic ID
		h.fileID = "43DM"
		-- Blank these for now, fix em up during tag writing
		h.ofsTag = 0
		h.nTag = 0
		-- Use fixed MODL ref...
		h.mref.entries = 1
		h.mref.refid = 1
		
		return h
	)
)

struct M3E_MODL
(
	name,  -- max model name
	versID,
	SEQS, STC, STG, vec1, STS,
	bones, nSkinBones,
	vflags, verts, DIV, bonelu,
    bndSphere, attach, attachlu, attachvol, attachvollu,
	matm, mat, ter,
	par, parc,
	IREF,
	
	fn Write bitStream modl vers = 
	(
		-- goto modl offset first
		fseek bitStream twrite[2].ofsData #seek_set
		
		-- Write MODL chunk
		M3E_WriteRef bitStream modl.name #CHAR
		WriteLong bitStream modl.versID #unsigned
		M3E_WriteRef bitStream modl.SEQS #SEQS flags:1
		M3E_WriteRef bitStream modl.STC #STC_ flags:4
		M3E_WriteRef bitStream modl.STG #STG_
		M3E_WriteVec bitStream modl.vec1 #v3d bflags:#MD34
		M3E_WriteRef bitStream modl.STS #STS_
		M3E_WriteRef bitStream modl.bones #BONE flags:1
		WriteLong bitStream modl.nSkinBones #unsigned
		WriteLong bitStream modl.vflags #unsigned
		case of
		(
			(bit.get modl.vflags 19 == true): M3E_WriteRef bitStream modl.verts #VERT subtype:#v36
			default: M3E_WriteRef bitStream modl.verts #VERT
		)
		M3E_WriteRef bitStream modl.DIV #DIV_ flags:2
		M3E_WriteRef bitStream modl.bonelu #U16_ subtype:#uint16
		M3E_WriteVec bitStream modl.bndSphere #sphere bflags:#MD34
		M3E_WriteBlank bitStream 0x3C flags:#blank
		M3E_WriteRef bitStream modl.attach #ATT_ flags:1
		M3E_WriteRef bitStream modl.attachlu #U16_ subtype:#int16
		M3E_WriteBlank bitStream 0x30 flags:#blank
		M3E_WriteRef bitStream modl.MATM #MATM
		M3E_WriteRef bitStream modl.MAT #MAT_ flags:15
		M3E_WriteBlank bitStream 0x18 flags:#blank
		M3E_WriteRef bitStream modl.TER #TER_
		M3E_WriteBlank bitStream 0x24 flags:#blank
		M3E_WriteRef bitStream modl.PAR #PAR_ flags:12
		M3E_WriteRef bitStream modl.PARC #PARC
		M3E_WriteBlank bitStream 0x9C flags:#blank
		M3E_WriteRef bitStream modl.iref #IREF
		M3E_WriteBlank bitStream 0x78 flags:#blank
		M3E_WriteRef bitStream modl.attachvol #ATVL
		M3E_WriteRef bitStream modl.attachvollu #U16_ subtype:#int16
		M3E_WriteRef bitStream modl.attachvollu #U16_ subtype:#int16 -- duplicate lookups? always 0 anyways
	)
)

struct M3E_SEQS
(
	d1, name, animStart, maxframes, moveSpeed, seqFlags, frequency, d3, bndSphere, d4,
	cstart, cend, -- Max variables
	
	fn Write bitStream ad =
	(
		M3E_WriteArray bitStream ad.d1 flags:#int32
		M3E_WriteRef bitStream ad.name #CHAR
		WriteLong bitStream ad.animStart #unsigned
		WriteLong bitStream ad.maxframes #unsigned
		WriteFloat bitStream ad.moveSpeed
		WriteLong bitStream ad.seqFlags #unsigned
		WriteLong bitStream ad.frequency #unsigned
		M3E_WriteArray bitStream ad.d3 flags:#uint32
		M3E_WriteVec bitStream ad.bndSphere #sphere bflags:#MD34
		M3E_WriteArray bitStream ad.d4 flags:#int32
	),
	fn init =
	(
		a = M3E_SEQS()
		
		a.d1 = #(-1, 1)
		a.name = "Stand"
		a.animStart = 0
		a.maxframes = 10000
		a.moveSpeed = 0
		a.seqFlags = 0
		a.frequency = 100
		a.d3 = #(1, 1, 100, 0)
		a.bndSphere = M3E_Sphere.init()
		a.d4 = #(0, 0)
		
		return a
	)
)

struct M3E_Event
(
	name, d1, s1, s2, mat1, d2,
	
	fn Write bitStream evnt =
	(
		M3E_WriteRef bitStream evnt.name #CHAR
		WriteLong bitStream evnt.d1 #signed
		WriteShort bitStream evnt.s1 #signed
		WriteShort bitStream evnt.s2 #unsigned
		M3E_WriteVec bitStream evnt.mat1 #matrix bflags:#null
		M3E_WriteArray bitStream evnt.d2 flags:#uint32
	),
	fn init =
	(
		local evnt = M3E_Event()
		
		evnt.name = "Evt_SeqEnd"
		evnt.d1 = -1
		evnt.s1 = -1
		evnt.s2 = 0
		evnt.mat1 = M3E_Matrix.init()
		evnt.d2 = #(4, 0, 0, 0)
		
		return evnt
	)
)

struct M3E_AnimBlock -- Sequence Data
(
	frames, flags, fend, keys, animid,
	
	fn Write bitStream ablock sdtype flags:0 =
	(
		M3E_WriteRef bitStream ablock.frames #I32_ subtype:#uint32
		WriteLong bitStream ablock.flags #unsigned
		WriteLong bitStream ablock.fend #unsigned
		M3E_WriteRef bitStream ablock.keys sdtype flags:flags
	),
	fn init =
	(
		local ab = M3E_AnimBlock()
		ab.frames = #()
		ab.flags = 0
		ab.fend = 0
		ab.keys = #()
		
		return ab
	),
	fn initEvnt =
	(
		local a = M3E_AnimBlock.init()
		a.frames = #(9999)
		a.flags = 1
		a.fend = 10000
		a.keys = #(M3E_Event.init())
		
		return a
	)
)

struct M3E_Animoffs 
(
	aind, sdind,
	
	fn Write bitStream aoffs =
	(
		WriteShort bitStream aoffs.aind #unsigned
		WriteShort bitStream aoffs.sdind #unsigned
	),
	fn init =
	(
		local ao = M3E_Animoffs()
		ao.aind = 0
		ao.sdind = 0
		
		return ao
	)
)

struct M3E_STC --Sequence Transformations Collection (STC)
(
	name, d1, seqlu, stglu, animid, animref, d2, sdata,
	seqInd, cstart, cend, frequency, moveSpeed, looping,
	
	fn Write bitStream stc =
	(
		-- M3E_WriteRef bitStream stc.name #CHAR
		-- for some reason, Blizzard M3's are written with the animid and animref references first before the name reference
		M3E_WriteBlank bitStream (M3E_getSize #REF) flags:#blank
		
		WriteLong bitStream stc.d1 #unsigned
		WriteShort bitStream stc.seqlu #unsigned
		WriteShort bitStream stc.stglu #unsigned
		M3E_WriteRef bitStream stc.animid #U32_ subtype:#uint32
		M3E_WriteRef bitStream stc.animref #U32_ subtype:#animind
		-- create file bookmark to return to
		local bm = ftell bitStream
		
		-- seek to char reference now...
		fseek bitStream (-0x2C) #seek_cur
		-- and write the char ref
		M3E_WriteRef bitStream stc.name #CHAR
		-- then return to the bookmark
		fseek bitStream bm #seek_set
		
		WriteLong bitStream stc.d2 #unsigned
		for i = 1 to stc.sdata.count do
		(
			sd = stc.sdata[i]
			case i of
			(
				1: M3E_WriteRef bitStream stc.sdata[1] #SDEV
				2: M3E_WriteRef bitStream stc.sdata[2] #SD2V
				3: M3E_WriteRef bitStream stc.sdata[3] #SD3V
				4: M3E_WriteRef bitStream stc.sdata[4] #SD4Q
				6: M3E_WriteRef bitStream stc.sdata[6] #SDR3
				8: M3E_WriteRef bitStream stc.sdata[8] #SDS6
				default: M3E_WriteRef bitStream stc.sdata[i] #null
			)
		)
	),
	fn init =
	(
		local stc = M3E_STC()
		stc.name = "Stand_full"
		stc.d1 = 0
		stc.seqlu = 0
		stc.stglu = 0
		stc.animid = #(Random 1 1e8) -- must be array
		stc.animref = #(M3E_Animoffs.init())
		stc.d2 = 0
		stc.sdata = #()
		-- initialize array
		stc.sdata[1] = #(M3E_AnimBlock.initEvnt())
		
		return stc
	),
	fn Blank =
	(
		local stc = M3E_STC.init()
		stc.d1 = 0
		stc.d2 = 0
		stc.animid = #()
		stc.animref = #()
		stc.sdata[13] = 0
		for i = 1 to 13 do stc.sdata[i] = #()
		
		return stc
	)
)

struct M3E_STG
(
	name, stcind,
	
	fn Write bitStream stg =
	(
		M3E_WriteRef bitStream stg.name #CHAR
		M3E_WriteRef bitStream stg.stcind #U32_ subtype:#uint32
	),
	fn init =
	(
		local stg = M3E_STG()
		stg.name = "Stand"
		stg.stcind = #(0)
		
		return stg
	)
)

struct M3E_STS
(
	animid, d1, s1, s2,
	
	fn Write bitStream sts =
	(
		M3E_WriteRef bitStream sts.animid #U32_ subtype:#uint32
		M3E_WriteArray bitStream sts.d1 flags:#int32
		WriteShort bitStream sts.s1 #signed
		WriteShort bitStream sts.s2 #unsigned
	),
	fn init =
	(
		local sts = M3E_STS()
		sts.animid = #()
		sts.d1 = #(-1,-1,-1)
		sts.s1 = -1
		sts.s2 = 0
		
		return sts
	),
	fn initBlank modl =
	(
		local sts = M3E_STS.init()
		append sts.animid modl.stc[1].animid[1]
		
		return sts
	)
)

struct M3E_MaxBone
(
	name, boneIndex, parentptr, parent, children,
	bindmat, invbindmat, maxObj, iref,
	skinned
)

struct M3E_Bone
(
	d1, name, flags, parent, s1, 
	trans, rot, bscale, ar1,
	iref, maxObj,
	
	fn Write bitStream bone =
	(
		WriteLong bitStream bone.d1 #signed
		M3E_WriteRef bitStream bone.name #CHAR
		WriteLong bitStream bone.flags #unsigned
		WriteShort bitStream bone.parent #signed
		WriteShort bitStream bone.s1 #unsigned
		M3E_AnimRef.Write bitStream bone.trans #VEC3D
		M3E_AnimRef.Write bitStream bone.rot #VEC4D
		M3E_AnimRef.Write bitStream bone.bscale #VEC3D
		M3E_AnimRef.Write bitStream bone.ar1 #UINT32
	),
	fn init =
	(
		b = M3E_Bone()
		
		b.d1 = -1
		b.name = "Main"
		local flags = 0
		flags = bit.set flags 10 true -- Animated
		flags = bit.set flags 12 true -- Skinned
		flags = bit.set flags 14 true -- Unknown
		b.flags = flags
		b.parent = -1
		b.s1 = 0
		
		b.trans = M3E_AnimRef.init #VEC3D
		b.rot = M3E_AnimRef.init #VEC4D
		
		-- setup scale
		b.bscale = M3E_AnimRef.init #VEC3D
		b.bscale.initValue = [1, 1, 1]
		b.bscale.nullValue = [1, 1, 1]
		
		b.ar1 = M3E_AnimRef.init #UINT32
		b.ar1.initValue = 1
		b.ar1.nullValue = 1
		
		b.iref = M3E_Matrix.init()
		
		return b
	)		
)

struct M3E_Vertex
(
	pos, bw, bi, normal, uv, d1, d2,
	faceref, origvertindx, origtvertindx, -- for script purposes only
	
	fn Write bitStream vert =
	(
		M3E_WriteVec bitStream vert.pos #v3d
		M3E_WriteArray bitStream vert.bw flags:#uint8
		M3E_WriteArray bitStream vert.bi flags:#uint8
		M3E_WriteArray bitStream vert.normal flags:#uint8
		M3E_WriteArray bitStream vert.uv flags:#uvshorts
		--WriteLong bitStream vert.d1 #unsigned
		WriteLong bitStream vert.d2 #unsigned
	),
	fn init =
	(
		local v = M3E_Vertex()
		v.pos = [0,0,0]
		v.bw = #(0,0,0,0)
		v.bi = #(0,0,0,0)
		v.normal = #(0,0,0,0)
		v.uv = #()
		v.d1 = 0
		v.d2 = 0
		v.faceref = #()
		
		return v
	)
)

struct M3E_REGN
(
	s1, indvert, nvert, 
	indface, nface, 
	bcount, indbonelu, nbonelu,
	s2, b1, s3,
	verts, faces, vertsList, facesList, skinBones, maxMesh, maxSkin,-- maxscript holders

	fn Write bitStream regn =
	(
		M3E_WriteArray bitStream regn.s1 flags:#uint32
		WriteLong bitStream regn.indvert #unsigned
		WriteLong bitStream regn.nvert #unsigned
		WriteLong bitStream regn.indface #unsigned
		WriteLong bitStream regn.nface #unsigned
		WriteShort bitStream regn.bcount #unsigned
		WriteShort bitStream regn.indbonelu #unsigned
		WriteShort bitStream regn.nbonelu #unsigned
		WriteShort bitStream regn.s2 #unsigned
		M3E_WriteArray bitStream regn.b1 flags:#uint8
		WriteShort bitStream regn.s3 #unsigned
	),
	fn init =
	(
		local r = M3E_REGN()
		r.s1 = #(0,0)
		r.bcount = 1
		r.indbonelu = 0
		r.nbonelu = 1
		r.s2 = 0
		r.b1 = #(1, 1)
		r.s3 = 0
		r.verts = #()
		r.faces = #()
		r.vertsList = #()
		r.facesList = #()
		r.skinBones = #()
		
		return r
	)
)

struct M3E_BAT
(
	d1, subid, d2, matid, s1,
	
	fn Write bitStream bat =
	(
		WriteLong bitStream bat.d1 #unsigned
		WriteShort bitStream bat.subid #unsigned
		WriteLong bitStream bat.d2 #unsigned
		WriteShort bitStream bat.matid #unsigned
		WriteShort bitstream bat.s1 #signed
	),
	fn init =
	(
		local bat = M3E_BAT()
		bat.d1 = 0
		bat.d2 = 0
		bat.s1 = -1
		
		return bat
	)
)

struct M3E_MSEC
(
	d1 = 0, ar1 = M3E_AnimRef.init #SPHERE,
	
	fn Write bitStream msec =
	(
		WriteLong bitStream msec.d1 #unsigned
		M3E_AnimRef.Write bitStream msec.ar1 #SPHERE
	)
)

struct M3E_DIV -- Model divisions
(
	faces, regn, bat, msec, d1,
	
	fn Write bitStream div =
	(
		M3E_WriteRef bitStream div.faces #U16_ subtype:#uint16
		M3E_WriteRef bitStream div.regn #REGN flags:3
		M3E_WriteRef bitStream div.bat #BAT_ flags:1
		M3E_WriteRef bitStream div.msec #MSEC flags:1
		WriteLong bitStream div.d1 #unsigned
	),
	fn init =
	(
		local div = M3E_DIV()
		div.faces = #()
		div.regn = #()
		div.bat = #()
		div.msec = #()
		div.d1 = 1
		
		return div
	)
)

struct M3E_Subref -- Submesh refrences
(
	subid, matid
)

struct M3E_Attachment
(
	flags, name, bone, maxObj,
	
	fn Write bitStream m3attach =
	(
		WriteLong bitStream m3attach.flags #signed
		M3E_WriteRef bitStream m3attach.name #CHAR
		WriteLong bitStream m3attach.bone #unsigned
	),
	fn init =
	(
		local att = M3E_Attachment()
		att.flags = -1
		
		return att
	)
)

struct M3E_AttachVolume
(
	bone, d1, mat, rad,
	
	fn Write bitStream m3attvol =
	(
		for i = 1 to 2 do
		(
			WriteLong bitStream m3attvol.bone #unsigned
		)
		
		WriteLong bitStream m3attvol.d1 #unsigned
		WriteLong bitStream m3attvol.bone #unsigned
		M3E_WriteVec bitStream m3attvol.mat #matrix
		M3E_WriteBlank bitStream 0x18 flags:#blank
		WriteFloat bitStream m3attvol.rad
		M3E_WriteBlank bitStream 0x08 flags:#blank
	),
	fn init =
	(
		local av = M3E_AttachVolume()
		av.d1 = 1
		av.mat = M3E_Matrix.init()
		
		return av
	)
)

struct M3E_MATM
(
	matType, matind,
	
	fn Write bitStream matm =
	(
		WriteLong bitStream matm.matType #unsigned
		WriteLong bitStream matm.matind #unsigned
	),
	fn init =
	(
		local matm = M3E_MATM()
		matm.matType = 1
		
		return matm
	),
	fn Read mats =
	(
		marray = #()
		for i = 1 to mats.count do
		(
			m = M3E_MATM.init()
			m.matind = i - 1
			
			append marray m
		)
		
		return marray
	)
)

struct M3E_LAYR --more work to be done at a later point
(
	name, flags, uvChannel, alphaFlags,
	colour,
	bright_mult, bright_mult2,
	f2, d1, d2,
	UVOffset, UVAngle, UVTiling, 
	d3,
	ar1, ar2, ar3, ar4, ar5,
	brightness, tintStrength, f1,
	maxBitmap,
	
	fn Write bitStream layr =
	(
		WriteLong bitStream 0 #unsigned
		M3E_WriteRef bitStream layr.name #CHAR
		M3E_AnimRef.Write bitStream layr.colour #COLOUR
		WriteLong bitStream layr.flags #unsigned
		WriteLong bitStream layr.uvChannel #unsigned
		WriteLong bitStream layr.alphaFlags #unsigned
		M3E_AnimRef.Write bitStream layr.bright_mult #FLOAT
		M3E_AnimRef.Write bitStream layr.bright_mult2 #FLOAT
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteLong bitStream -1 #signed
		M3E_WriteBlank bitStream 0x08 flags:#blank
		WriteLong bitStream layr.d1 #signed
		M3E_WriteBlank bitStream 0x08 flags:#blank
		M3E_AnimRef.Write bitStream layr.ar1 #UINT32
		M3E_AnimRef.Write bitStream layr.ar2 #VEC2D
		M3E_AnimRef.Write bitStream layr.ar3 #UINT16
		M3E_AnimRef.Write bitStream layr.UVOffset #VEC2D
		M3E_AnimRef.Write bitStream layr.UVAngle #VEC3D
		M3E_AnimRef.Write bitStream layr.UVTiling #VEC2D
		M3E_AnimRef.Write bitStream layr.ar4 #UINT32
		M3E_AnimRef.Write bitStream layr.ar5 #FLOAT
		M3E_AnimRef.Write bitStream layr.brightness #FLOAT
		WriteLong bitStream layr.d3 #signed
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteFloat bitStream layr.tintStrength
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteFloat bitStream layr.f1
		M3E_WriteBlank bitStream 0x04 flags:#blank
		
	),
	fn init =
	(
		local layr = M3E_LAYR()
		
		layr.flags = 236
		layr.uvChannel = 0
		layr.alphaFlags = 0
		layr.colour = M3E_AnimRef.init #COLOUR
		layr.colour.initValue = layr.colour.nullValue = [0, 0, 0, 0]
		layr.bright_mult = M3E_AnimRef.init #FLOAT
		layr.bright_mult.initValue = layr.bright_mult.nullValue = 1.0
		layr.bright_mult2 = M3E_AnimRef.init #FLOAT
		layr.f2 = 1.0
		layr.d1 = 0
		layr.ar1 = M3E_AnimRef.init #UINT32
		layr.ar2 = M3E_AnimRef.init #VEC2D
		layr.ar3 = M3E_AnimRef.init #UINT16
		layr.UVOffset = M3E_AnimRef.init #VEC2D
		layr.UVAngle = M3E_AnimRef.init #VEC3D
		layr.UVTiling = M3E_AnimRef.init #VEC2D
		layr.UVTiling.initValue = layr.UVTiling.nullValue = [1.0, 1.0]
		layr.ar4 = M3E_AnimRef.init #UINT32
		layr.ar5 = M3E_AnimRef.init #FLOAT
		layr.ar5.initValue = layr.ar5.nullValue = 1.0
		layr.brightness = M3E_AnimRef.init #FLOAT
		layr.brightness.initValue = layr.brightness.nullValue = 1.0
		layr.d3 = -1
		layr.tintStrength = 4.0
		layr.f1 = 1.0
		
		return layr
	)
)

struct M3E_Mat
(
	name, flags, blendMode, priority, 
	spec, alphaMaskEnable, spec_mult, emis_mult, cutoutThresh,
	layerBlendType, emisBlendType, emisMode, specType,
	layrs, ar1, ar2,
	maxMat, -- max variable
	
	fn Write bitStream mat =
	(
		M3E_WriteRef bitStream mat.name #CHAR
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteLong bitStream mat.flags #unsigned
		WriteLong bitStream mat.blendMode #unsigned
		WriteLong bitStream mat.priority #unsigned
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteFloat bitStream mat.spec
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteLong bitStream mat.cutoutThresh #unsigned
		WriteFloat bitStream mat.spec_mult
		WriteFloat bitStream mat.emis_mult
		-- Layer Refs
		for i = 1 to 13 do M3E_WriteRef bitStream mat.layrs[i] #LAYR flags:22
			
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteLong bitStream mat.layerBlendType #unsigned
		WriteLong bitStream mat.emisBlendType #unsigned
		WriteLong bitStream mat.emisMode #unsigned
		WriteLong bitStream mat.specType #unsigned
		
		M3E_AnimRef.Write bitStream mat.ar1 #UINT32
		M3E_AnimRef.Write bitStream mat.ar2 #UINT32
	),
	fn init = 
	(
		local mat = M3E_Mat()
		mat.flags = 0
		mat.blendMode = 0
		mat.priority = 0
		mat.spec = 0
		mat.alphaMaskEnable = 0
		mat.spec_mult = 1
		mat.emis_mult = 1
		mat.cutoutThresh = 0
		mat.layerBlendType = 2
		mat.emisBlendType = 2
		mat.emisMode = 2
		mat.specType = 0
		mat.layrs = #()
		
		-- unknown animref's
		mat.ar1 = M3E_AnimRef.init #UINT32
		mat.ar2 = M3E_AnimRef.init #UINT32
		
		return mat
	)
)

struct M3E_Ter
(
	name, map,
	maxMat,
	
	fn Write bitStream ter =
	(
		M3E_WriteRef bitStream ter.name #CHAR
		M3E_WriteRef bitStream ter.map #LAYR flags:22
	),
	fn init =
	(
		local ter = M3E_Ter()
		ter.map = M3E_Layr.init
		
		return ter
	)
)

struct M3E_PAR
(
	-- known values
	bone, matmIndex, 
	initEmissSpeed, speedVar, enableSpeedVar, angleX, angleY, spreadX, spreadY,
	lifespan, decay, enableDecay,
	pemitScale, colour1, enableReverseFlow,
	minParticles, maxParticles, emissRate, partEmit, type, emissArea, pivotSpread,
	enableRotate, pemitRotate, enableColour2, colour2, columns, rows, pemitFlags,
	enableTrailing, enableStreak, enableRadialEmission,
	
	-- unknown values
	emissSpeed2, emissSpeed3, scaleRatio, f1, speedUnk1, lifespanRatio, f2, f3, tailUnk1, spreadUnk1,
	enableScale2, pemitScale2, speedUnk2, f4, f5, i1, f6, f7, ar2, ar3,
	
	-- stupid massive amount of unused anim ref's
	ar4, ar5, ar6, ar7, ar8, ar9, ar10, ar11, ar12, ar13, ar14, 
	ar15, ar16, ar17, ar18, ar19, ar20, ar21, ar22, ar23, ar24,
	
	-- instance ref
	parcRef,
	
	-- maxObject
	maxObj,
	
	fn Write bitStream par =
	(
		WriteLong bitStream par.bone #unsigned
		WriteLong bitStream par.matmIndex #unsigned
		M3E_AnimRef.Write bitStream par.initEmissSpeed #FLOAT
		M3E_AnimRef.Write bitStream par.speedVar #FLOAT
		WriteLong bitStream par.enableSpeedVar #unsigned		
		M3E_AnimRef.Write bitStream par.angleY #FLOAT
		M3E_AnimRef.Write bitStream par.angleX #FLOAT
		M3E_AnimRef.Write bitStream par.spreadX #FLOAT
		M3E_AnimRef.Write bitStream par.spreadY #FLOAT
		M3E_AnimRef.Write bitStream par.lifespan #FLOAT
		M3E_AnimRef.Write bitStream par.decay #FLOAT
		WriteLong bitStream par.enableDecay #unsigned
		
		M3E_WriteBlank bitStream 0x0C flags:#blank
		
		WriteFloat bitStream par.emissSpeed2
		WriteFloat bitStream par.scaleRatio
		
		for i = 1 to 3 do (WriteFloat bitStream par.f1[i])
		
		M3E_AnimRef.Write bitStream par.pemitScale #VEC3D
		M3E_AnimRef.Write bitStream par.speedUnk1 #VEC3D
		
		for i = 1 to 3 do (M3E_AnimRef.Write bitStream par.colour1[i] #COLOUR)
		
		WriteFloat bitStream par.emissSpeed3
		
		M3E_WriteBlank bitStream 0x04 flags:#blank
		
		for i = 1 to 2 do (WriteFloat bitStream par.f2[i])
		
		M3E_WriteBlank bitStream 0x04 flags:#blank
		
		WriteLong bitStream par.enableTrailing #unsigned
		
		M3E_WriteBlank bitStream 0x08 flags:#blank
		
		for i = 1 to 4 do (WriteFloat bitStream par.f3[i])
		
		WriteLong bitStream par.minParticles #unsigned
		WriteLong bitStream par.maxParticles #unsigned
		M3E_AnimRef.Write bitStream par.emissRate #FLOAT
		WriteLong bitStream par.type #unsigned
		M3E_AnimRef.Write bitStream par.emissArea #VEC3D
		M3E_AnimRef.Write bitStream par.tailUnk1 #VEC3D
		M3E_AnimRef.Write bitStream par.pivotSpread #FLOAT
		M3E_AnimRef.Write bitStream par.spreadUnk1 #FLOAT
		WriteLong bitStream par.enableRadialEmission #unsigned
		WriteLong bitStream par.enableScale2 #unsigned
		M3E_AnimRef.Write bitStream par.pemitScale2 #VEC3D
		WriteLong bitStream par.enableRotate #unsigned
		M3E_AnimRef.Write bitStream par.pemitRotate #VEC3D
		WriteLong bitStream par.enableColour2 #unsigned
		
		for i = 1 to 3 do (M3E_AnimRef.Write bitStream par.colour2[i] #COLOUR)
		
		M3E_WriteBlank bitStream 0x04 flags:#blank
		
		M3E_AnimRef.Write bitStream par.partEmit #UINT16
		M3E_WriteVec bitStream par.speedUnk2 #v4dbyteFloat
		WriteFloat bitStream par.lifespanRatio
		WriteShort bitStream par.columns #unsigned
		WriteShort bitStream par.rows #unsigned
		
		for i = 1 to 2 do (WriteFloat bitStream par.f4[i])
		
		M3E_WriteBlank bitStream 0x04 flags:#blank
		WriteFloat bitStream par.f5
		WriteLong bitStream -1 #signed -- prevents model crashing
		
		M3E_WriteBlank bitStream 0x14 flags:#blank
		WriteLong bitStream par.enableStreak #unsigned
		WriteFloat bitStream par.f6
		M3E_WriteBlank bitStream 0x08 flags:#blank
		WriteFloat bitStream par.f7
		
		M3E_WriteBlank bitStream 0x04 flags:#blank
		
		-- a group of bizzare anim ref's that seem to have no purpose
		-- contain an odd aref type, which I think must be a vec3D made of shorts
		-- haven't found any models that use these as of yet
		M3E_AnimRef.Write bitStream par.ar4 #UINT32
		M3E_AnimRef.Write bitStream par.ar5 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar6 #UINT32
		M3E_AnimRef.Write bitStream par.ar7 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar8 #UINT32
		M3E_AnimRef.Write bitStream par.ar9 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar10 #UINT32
		M3E_AnimRef.Write bitStream par.ar11 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar12 #UINT32
		M3E_AnimRef.Write bitStream par.ar13 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar14 #UINT32
		M3E_AnimRef.Write bitStream par.ar15 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar16 #UINT32
		M3E_AnimRef.Write bitStream par.ar17 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar18 #UINT32
		M3E_AnimRef.Write bitStream par.ar19 #VEC3DSHRT
		M3E_AnimRef.Write bitStream par.ar20 #UINT32
		M3E_AnimRef.Write bitStream par.ar21 #UINT32
		M3E_AnimRef.Write bitStream par.ar22 #UINT32
		
		WriteLong bitStream par.pemitFlags #unsigned
		
		M3E_WriteBlank bitStream 0x18 flags:#blank
		
		M3E_AnimRef.Write bitStream par.ar23 #UINT32
		M3E_AnimRef.Write bitStream par.ar2 #FLOAT
		WriteLong bitStream -1 #signed -- prevents model crashing
		
		M3E_WriteBlank bitStream 0x04 flags:#blank
		
		M3E_AnimRef.Write bitStream par.ar24 #UINT32
		WriteLong bitStream -1 #signed
		
		M3E_WriteBlank bitStream 0x10 flags:#blank
		M3E_WriteRef bitStream par.parcRef #U32_ subtype:#uint32
	),
	fn init =
	(
		local p = M3E_PAR()
		
		-- setup animation references
		p.initEmissSpeed = M3E_AnimRef.init #FLOAT
		p.speedVar = M3E_AnimRef.init #FLOAT
		p.angleY = M3E_AnimRef.init #FLOAT
		p.angleX = M3E_AnimRef.init #FLOAT
		p.spreadX = M3E_AnimRef.init #FLOAT
		p.spreadY = M3E_AnimRef.init #FLOAT
		p.lifespan = M3E_AnimRef.init #FLOAT
		p.decay = M3E_AnimRef.init #FLOAT
		p.enableDecay = 1
		p.pemitScale = M3E_AnimRef.init #VEC3D
		p.speedUnk1 = M3E_AnimRef.init #VEC3D
		
		p.colour1 = #()
		for i = 1 to 3 do (p.colour1[i] = M3E_AnimRef.init #COLOUR)

		p.emissRate = M3E_AnimRef.init #FLOAT
		p.emissArea = M3E_AnimRef.init #VEC3D
		p.tailUnk1  = M3E_AnimRef.init #VEC3D
		p.pivotSpread = M3E_AnimRef.init #FLOAT
		p.spreadUnk1 = M3E_AnimRef.init #FLOAT
		p.enableScale2 = 0
		p.pemitScale2 = M3E_AnimRef.init #VEC3D
		p.enableRotate = 1
		p.pemitRotate = M3E_AnimRef.init #VEC3D
		
		p.partEmit = M3E_AnimRef.init #UINT16
		
		p.enableTrailing = p.enableStreak = 0
		
		p.colour2 = #()
		for i = 1 to 3 do (p.colour2[i] = M3E_AnimRef.init #COLOUR)
		
		p.ar2 = M3E_AnimRef.init #FLOAT
		
		p.f1 = #()
		p.f2 = #()
		p.f3 = #()
		p.f4 = #()

		-- damn you blizzard for these unused animation references...
		p.ar4 = M3E_AnimRef.init #UINT32
		p.ar5 = M3E_AnimRef.init #VEC3DSHRT
		p.ar6 = M3E_AnimRef.init #UINT32
		p.ar7 = M3E_AnimRef.init #VEC3DSHRT
		p.ar8 = M3E_AnimRef.init #UINT32
		p.ar9 = M3E_AnimRef.init #VEC3DSHRT
		p.ar10 = M3E_AnimRef.init #UINT32
		p.ar11 = M3E_AnimRef.init #VEC3DSHRT
		p.ar12 = M3E_AnimRef.init #UINT32
		p.ar13 = M3E_AnimRef.init #VEC3DSHRT
		p.ar14 = M3E_AnimRef.init #UINT32
		p.ar15 = M3E_AnimRef.init #VEC3DSHRT
		p.ar16 = M3E_AnimRef.init #UINT32
		p.ar17 = M3E_AnimRef.init #VEC3DSHRT
		p.ar18 = M3E_AnimRef.init #UINT32
		p.ar19 = M3E_AnimRef.init #VEC3DSHRT
		p.ar20 = M3E_AnimRef.init #UINT32
		p.ar21 = M3E_AnimRef.init #UINT32
		p.ar22 = M3E_AnimRef.init #UINT32
		
		p.ar23 = M3E_AnimRef.init #UINT32
		p.ar24 = M3E_AnimRef.init #UINT32
		
		p.parcRef = #()

		return p
	)
)

struct M3E_PARC
(
	emissRate, partEmit, bone,
	origPar,
	maxObj, 
	
	fn Write bitStream parc =
	(
		M3E_AnimRef.Write bitStream parc.emissRate #FLOAT
		M3E_AnimRef.Write bitStream parc.partEmit #UINT16
		WriteLong bitStream parc.bone #unsigned
	),
	fn init = 
	(
		local parc = M3E_PARC()
		parc.emissRate = M3E_AnimRef.init #FLOAT
		parc.partEmit = M3E_AnimRef.init #UINT16
		
		return parc
	)
)

-- ****************
--  EXPORT CODE
-- ****************
---------------------
-- SCENE CODE --
---------------------
fn M3E_getObjects m3objs m3modl objClass =
(
	local mObjs = #()
	local mObjCont
	local mObjClassString
	
	case objClass of
	(
		#attachment: 
		(
			mObjCont = m3objs.attachments
			mObjClassString = "attachments"
		)
		#pemitter: 
		(
			mObjCont = m3objs.pemits
			mObjClassString = "particle emitters"
		)
		#pinstance:
		(
			mObjCont = m3objs.parcs
			mObjClassString = "particle emitter instances"
		)
	)
	
	if (mObjCont != undefined) then
	(
		if (mObjCont.count > 0) then
		(
			echo ("Getting "+mObjClassString+"...")
			for i = 1 to mObjCont.count do
			(
				local maxObj = mObjCont[i]
				local m3Obj
				
				-- get custom parameters
				case objClass of
				(
					#attachment:
					(
						m3Obj = M3E_Attachment.init()
						
						m3Obj.name = maxObj.attachName
					)
					#pemitter:
					(
						-- gather UI parameters
						set time g_baseFrame
						m3Obj = M3E_PAR.init()
						
						m3Obj.matmIndex = (findItem m3objs.materials.fullMatList maxObj.pMaterial) - 1
						m3Obj.initEmissSpeed.initValue = maxObj.initEmissSpeed
						m3Obj.speedVar.initValue = maxObj.speedVar
						m3Obj.enableSpeedVar = M3E_BoolToInt maxObj.enableSpeedVar
						m3Obj.angleX.initValue = maxObj.emissAngleX
						m3Obj.angleY.initValue = maxObj.emissAngleY
						m3Obj.spreadX.initValue = maxObj.emissSpreadX
						m3Obj.spreadY.initValue = maxObj.emissSpreadY
						m3Obj.lifespan.initValue = maxObj.lifespan
						m3Obj.decay.initValue = maxObj.decay
						m3Obj.enableDecay = M3E_BoolToInt maxObj.enableDecay
						
						m3Obj.pemitScale.initValue = [maxObj.pemitScaleStart, maxObj.pemitScaleEnd, maxObj.pemitScaleSpread]
						
						m3Obj.colour1[1].initValue = maxObj.colour1start
						m3Obj.colour1[2].initValue = maxObj.colour1mid
						m3Obj.colour1[3].initValue = maxObj.colour1end
						
						m3Obj.minParticles = maxObj.minParticles
						m3Obj.maxParticles = maxObj.maxParticles
						m3Obj.emissRate.initValue = maxObj.rate
						m3Obj.partEmit.initValue = maxObj.partEmit
						m3Obj.type = maxObj.type - 1
						
						m3Obj.emissArea.initValue = [maxObj.pemitAreaWidth, maxObj.pemitAreaLength, maxObj.pemitAreaSpread]
						
						m3Obj.pivotSpread.initValue = maxObj.pivotSpread
						
						m3Obj.enableRotate = M3E_BoolToInt maxObj.enablePemitRotate
						m3Obj.pemitRotate.initValue = [maxObj.pemitRotateSpread1, maxObj.pemitRotateSpread2, maxObj.pemitRotateSpinSpeed]
						
						m3Obj.enableColour2 = M3E_BoolToInt maxObj.enableColour2
						
						m3Obj.colour2[1].initValue = maxObj.colour2start
						m3Obj.colour2[2].initValue = maxObj.colour2mid
						m3Obj.colour2[3].initValue = maxObj.colour2end
						
						m3Obj.columns = maxObj.columns
						m3Obj.rows = maxObj.rows
						
						m3Obj.enableTrailing = M3E_BoolToInt maxObj.enableTrailing
						m3Obj.enableStreak = M3E_BoolToInt maxObj.enableStreak
						m3Obj.enableRadialEmission = M3E_BoolToInt maxObj.enableRadialEmission
						
						-- particle flags
						--{
						local pflags = 0
						pflags = bit.set pflags 1 maxObj.sort
						pflags = bit.set pflags 2 maxObj.collideTerrain
						pflags = bit.set pflags 3 maxObj.collideObjects
						pflags = bit.set pflags 4 maxObj.spawnOnBounce
						pflags = bit.set pflags 5 maxObj.useInnerShape
						pflags = bit.set pflags 6 maxObj.inheritEmissionParams
						pflags = bit.set pflags 7 maxObj.inheritParentVel
						pflags = bit.set pflags 8 maxObj.sortByZHeight
						pflags = bit.set pflags 9 maxObj.reverseIteration
						pflags = bit.set pflags 10 maxObj.smoothRotation
						pflags = bit.set pflags 11 maxObj.bezSmoothRotation
						pflags = bit.set pflags 12 maxObj.smoothSize
						pflags = bit.set pflags 13 maxObj.bezSmoothSize
						pflags = bit.set pflags 14 maxObj.smoothColour
						pflags = bit.set pflags 15 maxObj.bezSmoothColour
						pflags = bit.set pflags 16 maxObj.litParts
						pflags = bit.set pflags 17 maxObj.randFlipBookStart
						pflags = bit.set pflags 18 maxObj.multiplyByGravity
						pflags = bit.set pflags 19 maxObj.clampTailParts
						pflags = bit.set pflags 20 maxObj.spawnTrailingParts
						pflags = bit.set pflags 21 maxObj.fixLengthTailParts
						pflags = bit.set pflags 22 maxObj.useVertexAlpha
						pflags = bit.set pflags 23 maxObj.modelParts
						pflags = bit.set pflags 24 maxObj.swapYZonModelParts
						pflags = bit.set pflags 25 maxObj.scaleTimeByParent
						pflags = bit.set pflags 26 maxObj.useLocalTime
						pflags = bit.set pflags 27 maxObj.simulateOnInit
						pflags = bit.set pflags 28 maxObj.copy
						
						m3Obj.pemitFlags = pflags
						--}
						
						-- kinda unknowns
						m3Obj.emissSpeed2 = maxObj.emissSpeed1
						m3Obj.emissSpeed3 = maxObj.emissSpeed2
						m3Obj.scaleRatio = maxObj.scaleRatio
						
						m3Obj.speedUnk1.initValue = [maxObj.emissSpeed3X, maxObj.emissSpeed3Y, maxObj.emissSpeed3Z]
						
						m3Obj.lifespanRatio = maxObj.lifespanRatio
						
						m3Obj.tailUnk1.initValue = [maxObj.tailUnkX, maxObj.tailUnkY, maxObj.tailUnkZ]
						m3Obj.spreadUnk1.initValue = maxObj.spreadUnk			
						m3Obj.speedUnk2 = [maxObj.speedUnk1X, maxObj.speedUnk1Y, maxObj.speedUnk1Z, maxObj.speedUnk1W]
						m3Obj.enableScale2 = M3E_BoolToInt maxObj.enableScale2
						m3Obj.pemitScale2.initValue = [maxObj.scale2start, maxObj.scale2end, maxObj.scale2spread]
						
						-- COMPLETE UNKNOWNS
						-- Anim Ref's
						m3Obj.ar2.initValue = maxObj.Unk15
		
						-- Single values
						append m3Obj.f1 maxObj.Unk1
						append m3Obj.f1 maxObj.Unk2
						append m3Obj.f1 maxObj.Unk3
						
						append m3Obj.f2 maxObj.Unk4
						append m3Obj.f2 maxObj.Unk5
						
						append m3Obj.f3 maxObj.Unk6
						append m3Obj.f3 maxObj.Unk7
						append m3Obj.f3 maxObj.Unk8
						append m3Obj.f3 maxObj.Unk9
						
						append m3Obj.f4 maxObj.Unk10
						append m3Obj.f4 maxObj.Unk11
						
						m3Obj.f5 = maxObj.Unk12
						m3Obj.f6 = maxObj.Unk13
						m3Obj.f7 = maxObj.Unk14
						
						-- handle p. emitter copies as PARC index references
						for j = 1 to m3objs.parcIDs.count do
						(
							local parcID = m3objs.parcIDs[j]
							if (parcID == i) then
							(
								local parcRef = j - 1 -- make it zero-based
								append m3Obj.parcRef parcRef
							)
						)
					)
					#pinstance:
					(
						m3Obj = M3E_PARC.init()
						m3Obj.emissRate.initValue = maxObj.rate
						m3Obj.partEmit.initValue = maxObj.partEmit
					)
				)
				
				-- max object reference
				m3Obj.maxObj = maxObj
				
				for j = 1 to m3modl.bones.count do
				(
					b = m3modl.bones[j]
					if (maxObj == b.maxObj) then m3Obj.bone = j - 1
				)
				
				if (m3Obj.bone != undefined) then 
				(
					append mObjs m3Obj
				)
			) -- for i loop
		) -- if mObjCont.count > 0
		
		-- sort by bone parents
		fn comparePar a1 a2 = if (a1.bone > a2.bone) then return 1 else if (a1.bone < a2.bone) then return -1 else return 0
		qsort mObjs comparePar
	)
	
	return mObjs
)

fn M3E_GetBndSphere =
(
	local retSph
	
	if (m3scene.bndSphere != undefined) then
	(
		local bSph = m3scene.bndSphere
		local m3bSph = M3E_Sphere.init()
		
		m3bSph.maxObj = bSph
		m3bSph.emin = bSph.min
		m3bSph.emax = bSph.max
		
		-- check the scale transform...
		local bsScale = bSph.transform.scale
		local lrgScale = 0.0
		for i = 1 to 3 do 
		(
			if (lrgScale < bsScale[i]) then lrgScale = bsScale[i]
		)
		
		local rad = bSph.bndRadius * lrgScale
		
		m3bSph.rad = rad
		
		retSph = m3bSph
	)
	else
	(
		if (m3scene.meshes.count > 0) then
		(
			retSph = M3E_Sphere.GetBound m3scene.meshes
		)
		else 
		(
			retSph = M3E_Sphere.init()
			retSph.rad = 2 -- seems to be default radius in Blizz models
		)
	)
	
	return retSph
)

struct M3E_animFrameKey
(
	stcInd, frame, key
)

fn M3E_findSTCframe frame =
(
	for i = 1 to awrite.count do
	(
		local seq = awrite[i]
		
		if (frame >= seq.cstart and frame <= seq.cend) then
		(
			return i
		)
		
		if (i == awrite.count) do return undefined
	)
)

fn M3E_addArefToSTC aref akeys type = 
(
	-- handle collected keys
	for i = 1 to akeys.count do
	(
		local akey = akeys[i]
		local seq = awrite[akey.stcInd]
		local idFound = findItem seq.animid aref.animid
		
		if (idFound > 0) then
		(
			local animOffs = seq.animref[idFound]
			local stcData = seq.sdata[animOffs.sdind + 1][animOffs.aind + 1] -- arrays not 0-based
			
			local localFrame = akey.frame - seq.cstart
			-- convert to M3 fps
			localFrame = localFrame * (1000 / g_useFPS)
			
			append stcData.frames localFrame
			append stcData.keys akey.key
		)
		else
		(
			-- code for initializing new animblock when I'm not feeling lazy
			append seq.animid aref.animid
			local aoff = M3E_Animoffs.init()
			
			case type of
			(
				#EVENT: aoff.sdind = 0
				#VEC2D: aoff.sdind = 1
				#VEC3D: aoff.sdind = 2
				#QUAT: aoff.sdind = 3
				#COLOUR: aoff.sdind = 4
				#FLOAT: aoff.sdind = 5
				#UINT16: aoff.sdind = 7
			)
			
			local aindcount = seq.sdata[aoff.sdind + 1].count
			aoff.aind = aindcount
			
			append seq.animref aoff

			-- initialise animblock
			local ab = M3E_AnimBlock.init()
			ab.fend = seq.cend - seq.cstart
	
			local localFrame = akey.frame - seq.cstart
			-- convert to M3 fps
			localFrame = localFrame * (1000 / g_useFPS)
			
			append ab.frames localFrame
			append ab.keys akey.key
	
			append seq.sdata[aoff.sdind + 1] ab
		)
		
		-- update original array
		awrite[akey.stcInd] = seq
	)
)

fn M3E_buildArefData aref rootObj props type =
(
	-- collect keys
	local adata = #()
	local propsClass = classOf props as string
	local aprops = #()
	if (propsClass != "Array") then
	(
		-- turn into array if not passed as array
		append aprops props
	) else aprops = props
	
	local frames = #()
	local prevq
	
	if (type == #QUAT) then
	(
		set time g_baseFrame 
		prevq = rootObj.rotation
	)

	for i = 1 to aprops.count do
	(
		local prop = aprops[i]
		local acont
		-- need special cases for translation/rotation/scaling controllers
		case prop of
		(
			#position: acont = rootObj.position.controller
			#rotation: acont = rootObj.rotation.controller
			#scale: acont = rootObj.scale.controller
			default: acont = getPropertyController rootObj prop
		)

		if (acont != undefined) then
		(
			for j = 1 to acont.keys.count do
			(
				local key = acont.keys[j]
				local frame = (key.time/TicksPerFrame) as integer
				
				-- check for found frame
				if (findItem frames frame == 0) then
				(
					local akey = M3E_animFrameKey()
					
					akey.frame = frame
					akey.stcInd = M3E_findSTCframe akey.frame
					
					if (akey.stcInd != undefined) then
					(
						-- append frame to list to check for later
						append frames frame
					
						-- go to key time
						set time key.time
						
						case type of
						(
							#VEC2D:
							(
								local v2d = [0.0, 0.0]
								-- get values of each as point2
								v2d.x = getProperty rootObj props[1]
								v2d.y = getProperty rootObj props[2]
								akey.key = v2d
							)
							#VEC3D:
							(
								case prop of
								(
									#position:
									(
										akey.key = acont.value
									)
									#scale:
									(
										akey.key = acont.value
									)
									default:
									(
										local v3d = [0.0, 0.0, 0.0]
										-- get values of each as point3
										v3d.x = getProperty rootObj props[1]
										v3d.y = getProperty rootObj props[2]
										v3d.z = getProperty rootObj props[3]
										akey.key = v3d
									)
								)
							)
							#VEC4D:
							(
								local v4d = [0.0, 0.0, 0.0, 0.0]
								-- get values of each as point4
								v4d.x = getProperty rootObj props[1]
								v4d.y = getProperty rootObj props[2]
								v4d.z = getProperty rootObj props[3]
								v4d.w = getProperty rootObj props[4]
								akey.key = v4d
							)
							#QUAT: 
							(
								--q = normalize (M3E_getNodeParentRotation mbone.maxObj)
								local mat
								if (rootObj.parent != undefined) then 
								(
									mat = rootObj.transform * (inverse rootObj.parent.transform)
								)
								else
								(
									mat = rootObj.transform
								)
								q = normalize (inverse mat.rotationpart)
								-- if dot product less than one, reverse signs
								if (qdot q prevq < 0) then q = -q
								akey.key = q
								prevq = q
							)
							default: akey.key = getProperty rootObj prop
						)
					
						append adata akey
						
						if (aref.animflags != 6) then
						(
							aref.animflags = 6
							case type of
							(
								#UINT16:
								(
									aref.flags = 0
								)
								default:
								(
									aref.flags = 1
								)
							)

						)
					)
				)
			) -- for j loop
		) -- if != undefined
	) -- for i loop
	
	M3E_addArefToSTC aref adata type
)

fn M3E_buildPemitAnims m3parts =
(
	echo "Building particle emitter animation data..."
	
	for i = 1 to m3parts.count do
	(
		local par = m3parts[i]
		local maxObj = par.maxObj
		
		M3E_buildArefData par.initEmissSpeed maxObj #initEmissSpeed #FLOAT
		M3E_buildArefData par.speedVar maxObj #speedVar #FLOAT
		M3E_buildArefData par.angleX maxObj #emissAngleX #FLOAT
		M3E_buildArefData par.angleY maxObj #emissAngleY #FLOAT
		M3E_buildArefData par.spreadX maxObj #emissSpreadX #FLOAT
		M3E_buildArefData par.spreadY maxObj #emissSpreadY #FLOAT
		M3E_buildArefData par.lifespan maxObj #lifespan #FLOAT
		M3E_buildArefData par.decay maxObj #decay #FLOAT
		
		-- messy but no better way to do it due to the way max handles values and controllers
		local pemitScaleVec3D = #(#pemitScaleStart, #pemitScaleEnd, #pemitScaleSpread)
		M3E_buildArefData par.pemitScale maxObj pemitScaleVec3D #VEC3D
		
		M3E_buildArefData par.emissRate maxObj #rate #FLOAT
		M3E_buildArefData par.partEmit maxObj #partEmit #UINT16
		
		local emissAreaVec3D = #(#pemitAreaWidth, #pemitAreaLength, #pemitAreaSpread)
		M3E_buildArefData par.emissArea maxObj emissAreaVec3D #VEC3D
		
		M3E_buildArefData par.pivotSpread maxObj #pivotSpread #FLOAT
		
		local pemitRotateVec3D = #(#pemitRotateSpread1, #pemitRotateSpread2, #pemitRotateSpinSpeed)
		M3E_buildArefData par.pemitRotate maxObj pemitRotateVec3D #VEC3D
		
		-- colours
		M3E_buildArefData par.colour1[1] maxObj #colour1start #VEC4D
		M3E_buildArefData par.colour1[2] maxObj #colour1mid #VEC4D
		M3E_buildArefData par.colour1[3] maxObj #colour1end #VEC4D
		
		M3E_buildArefData par.colour2[1] maxObj #colour2start #VEC4D
		M3E_buildArefData par.colour2[2] maxObj #colour2mid #VEC4D
		M3E_buildArefData par.colour2[3] maxObj #colour2end #VEC4D
		
		local speedUnk1Vec3D = #(#emissSpeed3X, #emissSpeed3Y, #emissSpeed3Z)
		M3E_buildArefData par.speedUnk1 maxObj speedUnk1Vec3D #VEC3D
		
		M3E_buildArefData par.spreadUnk1 maxObj #spreadUnk #FLOAT
		
		local scale2Vec3D = #(#scale2start, #scale2end, #scale2spread)
		M3E_buildArefData par.pemitScale2 maxObj scale2Vec3D #VEC3D
		
		M3E_buildArefData par.ar2 maxObj #Unk15 #FLOAT
	)
)

fn M3E_buildParcAnims m3parcs =
(
	echo "Building particle emitter instance animation data..."
	
	for i = 1 to m3parcs.count do
	(
		local parc = m3parcs[i]
		local maxObj = parc.maxObj
		
		M3E_buildArefData parc.emissRate maxObj #rate #FLOAT
		M3E_buildArefData parc.partEmit maxObj #partEmit #UINT16
	)
)

fn M3E_buildAttachments m3data m3attachs =
(
	local m3attachslu = #()
	local m3attachsvol = #()
	local m3attachsvollu = #()
	
	for i = 1 to m3attachs.count do
	(
		local m3attach = m3attachs[i]
		local m3attachlu = -1 -- attachment lookup always -1?
		
		if ((matchPattern m3attach.name pattern:"Ref_Target*") or (matchPattern m3attach.name pattern:"Ref_Shield*")) then
		(
			local m3avol = M3E_AttachVolume.init()
			local m3avollu = 0 -- attachment volume lookup always 0?
			
			-- assign volume variables
			m3avol.bone = m3attach.bone
			m3avol.rad = m3attach.maxObj.attachRadius
			
			append m3attachsvol m3avol
			append m3attachsvollu m3avollu
		)
		
		append m3attachslu m3attachlu
	)
	
	-- assign built arrays to main container
	m3data.attach = m3attachs
	m3data.attachlu = m3attachslu
	m3data.attachvol = m3attachsvol
	m3data.attachvollu = m3attachsvollu
)

fn M3E_compareKeys cont1 cont2 =
(
	if (cont1.keys.count != cont2.keys.count) then return false
	for i = 1 to cont1.keys.count do
	(
		local key1 = cont1.keys[i]
		local key2 = cont2.keys[i]
		
		if (key1.time != key2.time) then return false
		if (key2.value != key2.value) then return false
	)
	return true
)

fn M3E_comparePar par1 par2 =
(
	set time g_baseFrame
	local propNames = getPropNames par1
	for i = 1 to propNames.count do
	(
		-- check all the properties/controllers
		-- return false if we find any that don't match
		local propName = propNames[i]
		-- ignore rate and particles emitter, as these are present in PARC structures
		if (propName != #rate and propName != #partEmit and propName != #boxsize and propName != #Dummy) then
		(
			local prop1 = getProperty par1 propName
			local prop2 = getProperty par2 propName
			local prop1cont = getPropertyController par1 propName
			local prop2cont = getPropertyController par2 propName
			
			if (prop1 != prop2) then 
			(
				--echo (propName as string)
				--echo "exit1"
				return false
			)
			
			if (prop1cont == undefined) and (prop2cont != undefined) then 
			(
				--echo (propName as string)
				--echo "exit2"
				return false
			)
			
			if (prop1cont != undefined) and (prop2cont == undefined) then 
			(
				--echo (propName as string)
				--echo "exit3"
				return false
			)
			
			if (prop1cont != undefined) and (prop2cont != undefined) then
			(
				local keyMatch = M3E_compareKeys prop1cont prop2cont
				if (keyMatch == false) then return false
			)
		)
	)
	
	-- return true if we found no differences! yay!
	return true
)

fn M3E_getSceneObjects =
(
	echo "Getting scene objects..."
	
	max modify mode
	set coordsys world
	
	local m3objs = M3E_SceneObjects.init()
	
	if (objects.count < 1) then
	(
		-- throw error if scene is void of objects
		messagebox "No Scene Objects Found!"
		throw "No scene objects found"
	)
	
	-- Mesh sort, deselect unsuitable meshes
	for i = 1 to objects.count do
	(
		local obj = objects[i]
		objClass = classOf obj.baseObject as string
		local addObj = true
		if (obj.isHidden == true and g_exportHidden != true) then addObj = false -- check to see if we're exporting hidden
		if (obj.isFrozen == true and g_exportFrozen != true) then addObj = false -- or frozen
		if (objClass == "sc2boundsphere") then addObj = true -- override checks if we're grabbing the bound sphere
		if (obj.name == "_M3_Anim_Data" and objClass == "Point") then addObj = false -- ignore animation data container
		if (addObj == true) then 
		(
			case objClass of
			(
				"Editable_mesh": 
				(
					-- only grab meshes with assigned materials
					if (obj.material != undefined) then
					(
						local objMatClass = classOf obj.material as string
						-- and only grab meshes with the appropriate material type
						if (objMatClass == "sc2material" or objMatClass == "standardmaterial" or objMatClass == "multimaterial") then
						(
							append m3objs.meshes obj
						)
					)
				)
				"sc2boundsphere": m3objs.bndSphere = obj
				"sc2attachment": append m3objs.attachments obj
				"sc2pemitter": 
				(
					-- only grab particle emitters with assigned materials
					if (obj.pMaterial != undefined) then
					(
						local objMatClass = classOf obj.pMaterial as string
						-- and only grab particle emitters with sc2material types
						if (objMatClass == "sc2material") then
						(
							-- check to see if the p. emitter is a copy
							local parcBool = false
							local parcID
							for j = 1 to m3objs.pemits.count do
							(
								local pemit = m3objs.pemits[j]
								local boolCheck
								boolCheck = M3E_comparePar pemit obj
								
								if (boolCheck == true) then 
								(
									parcBool = true
									parcID = j
								)
							)
							
							
							if (parcBool == true) then
							(
								-- add particle emitter to parc array (particle emitter copies)
								append m3objs.parcs obj
								append m3objs.parcIDs parcID
							)
							else
							(
								-- else it's a fresh particle emitter
								append m3objs.pemits obj
							)
						)
					)
				)
				default: append m3objs.bones obj
			)
		)
	)
	
	clearSelection()
	return m3objs
)

fn M3E_getUsedMats m3objs =
(
	echo "Gathering used materials..."
	local maxMats = M3E_MaxMaterials()
	
	-- gather mesh materials
	for i = 1 to m3objs.meshes.count do
	(
		local mesh = m3objs.meshes[i]
		
		-- If multimaterial used...
		if (parentmatclass == "Multimaterial") then
		(
			local mmats = #()
			for k = 1 to mesh.numfaces do
			(
				-- #MATERIALS/SUBMESHES
				-- Gather Used Materials
				local matid = getfacematid mesh k
			
				-- prevent error for out of range matid's
				if (matid > mesh.material.count) then 
				(
					local subid = (mod matid mesh.material.count) as integer
					if (subid == 0) then subid = mesh.material.count
					matid = subid
				)
				
				if ((findItem mmats mesh.material[matid]) == 0) then 
				(
					append mmats mesh.material[matid]
				)
			)
			
			-- setup multimaterial container
			local mmatInd = findItem maxMats.mats mesh.material
			if (mmatInd == 0) then 
			(
				append maxMats.mats mesh.material
				append maxMats.multimats mmats
			)
			else
			(
				append maxMats.multimats[mmatInd] mmats
			)
		)
		else
		(
			if ((findItem maxMats.mats mesh.material) == 0) then 
			(
				append maxMats.mats mesh.material
				append maxMats.multimats undefined -- set multimaterial component undefined
			)
		)
	)
	
	-- gather particle emitter materials
	for i = 1 to m3objs.pemits.count do
	(
		local pemit = m3objs.pemits[i]
		
		if ((findItem maxMats.mats pemit.pMaterial) == 0) then
		(
			append maxMats.mats pemit.pMaterial
			append maxMats.multimats undefined -- set multimaterial component null
		)
	)
	
	-- build full material list
	for i = 1 to maxMats.mats.count do
	(
		local mmat = maxMats.mats[i]
		local mmatClass = classOf mmat as string
		
		if (mmatClass == "Multimaterial") then
		(
			for j = 1 to maxMats.multimats[i].count do
			(
				local multmat = maxMats.multimats[i][j]
				append maxMats.fullMatList multmat
			)
		)
		else
		(
			append maxMats.fullMatList mmat
		)
	)
	
	return maxMats
)

fn M3E_getSkin m3objs =
(
	--format "Checking for skin..." to:listener
	local cskin = #()
	-- pre-intialize skin array to same size as mesh array
	if (m3objs.meshes.count > 0) then cskin[m3objs.meshes.count] = 0
	-- Find Skin classes for each mesh
	for i = 1 to m3objs.meshes.count do
	(
		local mesh = m3objs.meshes[i]
		local smod
		for j = 1 to mesh.modifiers.count do
		(
			local meshMod = mesh.modifiers[j]
			local modClass = classOf meshMod as string
			
			if (modClass == "Skin") then
			(
				smod = meshMod
			)
		)
		
		if (smod != undefined) then
		(
			if ((skinOps.getNumberBones smod) < 1) then smod = undefined
		)
		
		cskin[i] = smod
	)
	
	return cskin
)

fn M3E_Bone_ParentDepth bind mbones boneDepth =
(
	-- For organising bones based on depth
	local boneParent = mbones[bind].parent + 1
	if boneParent != 0 then 
	(
		boneDepth[boneParent].y += 1
		M3E_Bone_ParentDepth boneParent mbones boneDepth
	)
)

fn M3E_Bone_ChildDepth bind mbones =
(
	-- For organising bones based on depth
	local boneParent = mbones[bind].parent + 1
	if boneParent == 0 then 0
	else return ( 1 + M3E_Bone_ChildDepth boneParent mbones  )
)

fn M3E_Get_Bone_Depth linkBones =
(
	-- sort bones by depth
	bDepth = #()
	bDepth[linkBones.count] = 0
	
	-- do child depth
	for i=1 to linkBones.count do
	(
		-- set parent to 0 for now, update later
		bonerec = [(M3E_Bone_ChildDepth i linkBones), 0, i]
		bDepth[i] = bonerec
	)
	
	-- do parent depth
	for i = 1 to linkBones.count do
	(
		M3E_Bone_ParentDepth i linkBones bDepth
	)

	fn compfn a b = 
	( 
		-- order by child depth criteria
		if a.y < b.y then 
		(
			return 1
		)
		else if a.y > b.y then 
		(
			return -1
		)
		else if a.y == b.y then
		(
			-- order by parent depth criteria
			if a.x < b.x then
			(
				return 1
			)
			else if a.x > b.x then
			(
				return -1
			)
			else return 0
		)
	)
	
	qsort bDepth compfn

	return bDepth
)

fn M3E_buildBoneChain mbones bindex skinArray nonskinArray = 
(
	local mbone = mbones[bindex]
	local obj = mbone.maxObj
	local boneExists = false
	
	-- check for bone in skin array
	for i = 1 to skinArray.count do
	(
		if (obj == skinArray[i]) then boneExists = true
	)
	
	-- check for bone in non-skin array
	if (boneExists == false) then
	(
		for i = 1 to nonskinArray.count do
		(
			if (obj == nonskinArray[i]) then boneExists = true
		)
	)
	
	-- if not found, added it to the appropriate chain
	if (boneExists == false) then
	(
		-- if it's skinned, grow skin array
		if (mbone.skinned == true) then
		(
			append skinArray obj
		)
		else
		(
			-- else grow non skin array
			append nonskinArray obj
		)
		-- if it has children, go down the chain
		for i = 1 to mbone.children.count do
		(
			local cindex = mbone.children[i]
			M3E_buildBoneChain mbones cindex skinArray nonskinArray
		)
	)
)

fn M3E_SetSkinned mbones bindex =
(
	mbones[bindex].skinned = true
	local mb = mbones[bindex]
	local bpar = mb.parent
	if bpar != -1 then
	(
		M3E_SetSkinned mbones (bpar + 1)
	)
)

fn M3E_buildBones m3obj =
(
	echo "Building bone list..."
	
	global mbones = m3obj.bones
	
	-- temp. parents for ordering
	for i = 1 to mbones.count do
	(
		bchild = mbones[i]
		if bchild.parentptr != undefined then
		(
			for j = 1 to mbones.count do
			(
				local bpar = mbones[j]
				if (bchild.parentptr == bpar.maxObj) then (bchild.parent = (j - 1))
			)
		)
		else
		(
			bchild.parent = -1
		)
		
		mbones[i] = bchild
	)

	-- setup skinned chains
	global sknBones = m3obj.skinBones
	for i = 1 to sknBones.count do
	(
		local boneid = sknBones[i]
		M3E_SetSkinned mbones boneid
	)
	
	-- order by child/parent depth
	local boneDepth = M3E_Get_Bone_Depth mbones
	
	-- children assignment for building chains
	for i = 1 to mbones.count do
	(
		local obj = mbones[i].maxObj
		--print obj to:listener
		mbones[i].children = #()
		for j = 1 to obj.children.count do
		(
			local childObj = obj.children[j]
			local childIndex
			for k = 1 to mbones.count do
			(
				if (childObj.name == mbones[k].name) then childIndex = k
			)
			
			if (childIndex != undefined) then 
			(
				append mbones[i].children childIndex
			)
		)
	)
	
	-- build bone chains
	local skinChains = #()
	local nonskinChains = #()
	global finalChain = #()
	for i = 1 to mbones.count do
	(
		-- build chains based on depth
		local j = boneDepth[i].z
		M3E_buildBoneChain mbones j skinChains nonskinChains
	)

	finalChain = join skinChains nonskinChains
	
	-- build proper index
	global realBones = #()
	realBones[finalChain.count] = 0
	for i = 1 to finalChain.count do
	(
		for j = 1 to mbones.count do
		(
			if (finalChain[i] == mbones[j].maxObj) then
			(
				realBones[i] = mbones[j]
			)
		)
	)
	
	-- Setup M3 bone list
	local m3bones = #()
	for i = 1 to realBones.count do
	(
		local m3bone = M3E_Bone.init()
		bchild = realBones[i]
		m3bone.name = bchild.name
		-- setup base pose info
		if bchild.parentptr != undefined then
		(
			for j = 1 to realBones.count do
			(
				bpar = realBones[j]
				-- set correct parent
				if (bchild.parentptr == bpar.maxObj) then 
				(
					m3bone.parent = (j - 1)
					local wbindmat = bchild.bindmat * bpar.invbindmat
					m3bone.rot.initValue = inverse wbindmat.rotationpart
					m3bone.trans.initValue = wbindmat.translation
				)
			)
		)
		else
		(
			m3bone.parent = -1
			m3bone.rot.initValue = inverse bchild.bindmat.rotationpart
			m3bone.trans.initValue = bchild.bindmat.translation
		)
		
		in coordsys parent
		(
			m3bone.bscale.initValue = bchild.maxObj.scale
		)
		
		m3bone.iref = bchild.iref
		m3bone.maxObj = bchild.maxObj
		
		append m3bones m3bone
	)
	
	-- Update skinned bone list
	global newSkinbones = #()
	for i = 1 to sknBones.count do
	(
		local sbone = sknBones[i]
		local newsbone
		for j = 1 to realBones.count do
		(
			local bindex = realBones[j].boneIndex
			if (sbone == bindex) then 
			(
				newsbone = (j - 1)
				local flags = m3bones[j].flags
				flags = bit.set flags 10 true
				flags = bit.set flags 12 true
				m3bones[j].flags = flags
			)
		)
		
		append newSkinbones newsbone
	)
	
	m3obj.skinBones = newSkinbones
	
	-- build M3 list
	m3obj.bones = #()
	for i = 1 to m3bones.count do
	(
		append m3obj.bones m3bones[i]
	)
)

fn M3E_getBones m3objs =
(
	echo "Getting bones..."
	local mbones = #()
	
	-- Add bones for non-skinned meshes
	for i = 1 to m3objs.meshes.count do
	(
		local msh = m3objs.meshes[i]
		local mskin = m3objs.skin[i]
		
		if (mskin == undefined) then
		(
			append m3objs.bones msh
		)
	)
	
	-- add code for attachments too...
	for i = 1 to m3objs.attachments.count do
	(
		local m3attach = m3objs.attachments[i]
		append m3objs.bones m3attach
	)
	
	-- ...and particle emitters
	for i = 1 to m3objs.pemits.count do
	(
		local m3pemit = m3objs.pemits[i]
		append m3objs.bones m3pemit
	)
	
	-- AND particle emitter instances!
	for i = 1 to m3objs.parcs.count do
	(
		local m3parc = m3objs.parcs[i]
		append m3objs.bones m3parc
	)
	
	-- Process scene objects into bones
	for i = 1 to m3objs.bones.count do
	(
		local sbone = m3objs.bones[i]
		local maxBone = M3E_MaxBone()
		
		maxBone.maxObj = sbone
		local maxObjClass = classOf sbone as string
		maxBone.name = sbone.name
		-- if (maxObjClass != "sc2attachment") then maxBone.name = sbone.name else maxBone.name = sbone.attachName
		maxBone.boneIndex = i
		if (sbone.parent != undefined) then 
		(
			local parent = sbone.parent
			maxBone.parentptr = parent
			if (parent.isHidden == true and g_exportHidden != true) then
			(
				throw ("Hidden object ("+parent.name+") found in bone system!\nEither check 'Export Hidden Objects' or unhide the object")
			)
			if (parent.isFrozen == true and g_exportFrozen != true) then
			(
				throw ("Frozen object ("+parent.name+") found in bone system!\nEither check 'Export Frozen Objects' or unfreeze the bone")
			)
		)
		
		-- get IREF transform
		at time g_bindposeFrame
		(
			local mat = inverse sbone.transform
			maxBone.iref = M3E_Matrix.convObjMatrix mat
		)
		
		-- get bindpose transform
		at time g_baseFrame
		(
			maxBone.bindmat = sbone.transform
		)
		
		maxBone.invbindmat = inverse maxBone.bindmat

		append mbones maxBone
	)

	return mbones
)

fn M3E_Get_ssData stringStrm property type:#value =
(
	-- reposition at start of stream
	seek stringStrm 0
	if (skipToString stringStrm property != undefined) then
	(
		local val
		case type of
		(
			#string: val = readLine stringStrm
			#value: val = readValue stringStrm
			#boolean: val = readValue stringStrm as booleanClass
		)

		return val
	)
)

fn M3E_Get_AnimData animss sc2Vers =
(
	local anim = M3E_STC.Blank()
	
	anim.name 		= sc2_Get_ssData animss ".name:" type:#string
	anim.seqInd	= sc2_Get_ssData animss ".seqInd:"
	anim.cstart 	= sc2_Get_ssData animss ".cstart:"
	anim.cend 		= sc2_Get_ssData animss ".cend:"
	if (sc2vers != undefined) then
	(
		case of
		(
			default:
			(
				anim.frequency	= sc2_Get_ssData animss ".freq:"
				anim.moveSpeed 	= sc2_Get_ssData animss ".moveSpeed:"
				anim.looping		= sc2_Get_ssData animss ".looping:" type:#boolean
			)
		)
	)
	else
	(
		anim.frequency	= 100
		anim.moveSpeed 	= 0.0
		anim.looping		= false
	)
	
	return anim
)

fn M3E_getAnimations =
(
	local aObj = getnodebyname g_AnimObj
	local aObjClass = classOf aObj as string
	if (isValidNode aObj == true and aObjClass == "Point") then
	(
		echo "Getting animation scene information..."
		local adata = #()
		local acss = (getAppData aObj 1) as stringstream
		local sc2vers = M3E_Get_ssData acss ".version:"
		local animCount = M3E_Get_ssData acss ".count:"
		
		local animInd = 2 -- where anims start
		
		for i = 1 to animCount do
		(
			local stcss = (getAppData aObj animInd) as stringstream
			local anim = M3E_Get_AnimData stcss sc2vers
			
			-- exclude global animations from being exported for now, since they screw up the model animations
			if ((matchPattern anim.name pattern:"GL*") != true) then
			(
				-- convert bool to integer
				if (anim.looping == true) then anim.looping = 0 else anim.looping = 1
				
				append adata anim
			)
			
			animInd += 1
		)
		
		return adata
	)
	else return undefined
)

fn M3E_getNodeParentRotation theNode = 
( 
	tRot = in coordsys parent theNode.rotation
  	--in coordsys (transmatrix theNode.transform.pos) return theNode.rotation
  	return tRot
)

fn M3E_buildBoneAnims mbones =
(
	echo "Building bone animation data..."
	for i = 1 to mbones.count do
	(
		local mbone = mbones[i]
		local maxObj = mbone.maxObj
		
		-- Gather the Keys 
		for a = 1 to 3 do
		(
			local animType
			local animRef
			local prop

			case a of
			(
				1: 
				(
					animType = #VEC3D
					animRef = mbone.trans
					prop = #position
				)
				2: 
				(
					animType = #QUAT
					animRef = mbone.rot
					prop = #rotation
				)
				3:
				(
					animType = #VEC3D
					animRef = mbone.bscale
					prop = #scale
				)
			)

			M3E_buildArefData animRef maxObj prop animType
		)
	)
)

fn M3E_buildAnimations m3data animData =
(
	-- build SEQ, STG, STS data from STC data
	local SEQs = #()
	local STGs = #()
	local STSs = #()
	
	-- all end events have the same ID
	local evntanimid = Random 1 1e8
	
	-- ...and the same location in the STC data arrays
	local evntanimref = M3E_Animoffs.init()
	evntanimref.sdind = 0
	evntanimref.aind = 0
	
	for i = 1 to animData.count do
	(
		local stc = animData[i]
		local seq = M3E_SEQS.init()
		seq.name = stc.name
		seq.maxframes = stc.cend - stc.cstart
		seq.maxframes = M3E_Convert_Time seq.maxframes
		seq.moveSpeed = stc.moveSpeed
		local seqFlags = 0
		local loopBool
		if stc.looping > 0 then loopBool = true else loopBool = false
		seq.seqFlags = bit.set seqFlags 1 loopBool
		seq.frequency = stc.frequency
		
		-- Gather bound sphere at first frame for each animation
		set time stc.cstart
		seq.bndSphere = M3E_GetBndSphere()
		
		local stg = M3E_STG.init()
		stg.name = seq.name
		local stcind = i - 1
		stg.stcind = #(stcind)
		
		-- Generate end event data
		-- add an end event to each animation
		local evntend = M3E_AnimBlock.initEvnt()
		evntend.frames[1] = seq.maxframes
		evntend.fend = seq.maxframes
		
		-- append generated data to STC
		append stc.animid evntanimid
		append stc.animref evntanimref
		append stc.sdata[1] evntend
		
		-- sort animid's by ascending value
		local animSorted = #()
		local animidSorted = #()
		local animrefSorted = #()
		
		for j = 1 to stc.animid.count do
		(
			local animid = stc.animid[j]
			local animref = stc.animref[j]
			append animSorted #(animid, animref)
		)
		
		-- sort by animid values
		fn compareAnimid a1 a2 = if (a1[1] > a2[1]) then return 1 else if (a1[1] < a2[1]) then return -1 else return 0
		qsort animSorted compareAnimid
		
		for j = 1 to animSorted.count do
		(
			local animid = animSorted[j][1]
			local animref = animSorted[j][2]
			
			-- update animid array as we build animref array
			append animidSorted animid
			append animrefSorted animref
		)
		
		-- update STC with sorted ID's and Offs
		stc.animid = animidSorted
		stc.animref = animrefSorted
		
		local sts = M3E_STS.init()
		sts.animid = stc.animid
		
		stc.name = seq.name + "_full"
		stc.seqlu = stcind
		stc.stglu = stcind
		
		append SEQs seq
		append STGs stg
		append STSs sts
		animData[i] = stc
	)
	
	m3data.SEQS = SEQs
	m3data.STG = STGs
	m3data.STS = STSs
	
	-- assign STC data
	m3data.STC = animData
)

fn M3E_buildFaces obj triindx regn uvChannels =
(
	-- annoyingly complicated!
	vertindices = getface obj triindx
	if (meshop.getMapSupport obj g_mapchannel) then
		tvertindices = meshop.getmapface obj g_mapchannel triindx
	else
		tvertindices = [0,0,0]
	vertindices = #(vertindices.x as integer, vertindices.y as integer, vertindices.z as integer)
	tvertindices = #(tvertindices.x as integer, tvertindices.y as integer, tvertindices.z as integer)
	m3vertindices = #()
	for i=1 to 3 do
	(
		vind = vertindices[i]
		tvind = tvertindices[i]
		-- findItem vastly more efficient over old function method
		local index = findItem regn.vertsList [vind, tvind]
		if (index == 0) then
		(
			v = M3E_Vertex.init()
			v.pos = getVert obj vind
			--v.normal	= getNormal obj vind
			local uvarray = #()
			
			for c = 1 to uvChannels.count do
			(
				local uv
				local uvChan = uvChannels[c]
				if (uvChan != undefined) then
				(
					if (meshop.getMapSupport obj uvChan) then uv = meshop.getmapvert obj uvChan tvind
					else uv = [0,0,0]
				)
				else uv = [0,0,0]
				append uvarray uv
			)
			
			v.uv = uvarray
			v.origvertindx = vind
			v.origtvertindx = tvind
			
			append regn.verts v
			append regn.vertsList [vind, tvind]
			m3vertindices[i] = regn.verts.count - 1
		)
		else
		(
			m3vertindices[i] = index - 1
		)
	)
	
	append regn.faces m3vertindices
	append regn.facesList vertindices
)

fn M3E_buildDIV m3obj =
(
	-- run through submeshes
	echo "Building submeshes..."
	local div = m3obj.submeshes
	for i = 1 to div.regn.count do
	(
		regn = div.regn[i]
		
		-- Order submesh verts and faces
		regn.nvert = regn.verts.count
		regn.nface = regn.faces.count * 3
		if (i > 1) then
		(
			prevregn = div.regn[i-1]
			regn.indvert = prevregn.indvert + prevregn.nvert
			regn.indface = prevregn.indface + prevregn.nface
		)
		else
		(
			regn.indvert = 0
			regn.indface = 0
		)
		
		-- handle skinned bones
		regn.bcount = regn.skinBones.count
		if (i > 1) then 
		(
			local prevregn = div.regn[i - 1]
			regn.indbonelu = prevregn.indbonelu + prevregn.bcount
		)
		else
		(
			regn.indbonelu = 0
		)
		
		regn.nbonelu = regn.bcount
		
		-- build single faces list
		for j = 1 to regn.faces.count do
		(
			for k = 1 to 3 do
			(
				append div.faces regn.faces[j][k]
			)
		)
	)
	
	div.msec = #(M3E_MSEC())
	
	-- assign new div back to main container
	m3obj.submeshes = div
)

fn M3E_getSubmesh m3objs =
(
	echo "Getting submeshes..."
	div = M3E_DIV.init()
	
	max modify mode
	set time g_bindposeFrame
	
	for i = 1 to m3objs.meshes.count do
	(
		-- Create Submeshes
		local mesh = m3objs.meshes[i]
		local matInd = findItem m3scene.materials.mats mesh.material
		local mmatClass = classOf mesh.material as string
		
		if (mmatClass == "Multimaterial") then
		(
			for j = 1 to m3scene.materials.multimats[matInd].count do
			(
				local multiMat = m3scene.materials.multimats[matInd][j]
				r = M3E_REGN.init()
				r.maxMesh = mesh
				b = M3E_BAT.init()
				b.subid = div.regn.count
				b.matid = (findItem m3scene.materials.fullMatList multiMat) - 1
				
				local uvChannels = #()
				append uvChannels g_mapchannel
				local mClass = classOf multiMat as string
				if (mClass == "sc2material") then
				(
					if (bit.get m3objs.vertFlags 19 == true) then
					(
						local DUVchan
						if (multiMat.decalMap != undefined) then
						(
							if (multiMat.decalMap.coords.mapping == 0) then 
							(
								if (multiMat.decalMap.mapChannel > 1) then DUVchan = multiMat.decalMap.coords.MapChannel
							)
						)
						
						append uvChannels DUVchan
					)
				)
				
				for k = 1 to mesh.numfaces do
				(
					local matid = getfacematid mesh k
					if (matid > mesh.material.count) then 
					(
						local subid = (mod matid mesh.material.count) as integer
						if (subid == 0) then subid = mesh.material.count
						matid = subid
					)
					
					if (mesh.material[matid] == multiMat) then
					(
						M3E_buildFaces mesh k r uvChannels
					)
				)
				
				append div.regn r
				append div.bat b
			)
		)
		else
		(
			local mat = mesh.material
			r = M3E_REGN.init()
			r.maxMesh = mesh
			b = M3E_BAT.init()
			b.subid = div.regn.count
			b.matid = (findItem m3scene.materials.fullMatList mat) - 1
			
			local uvChannels = #()
			append uvChannels g_mapchannel
			local mClass = classOf mat as string
			if (mClass == "sc2material") then
			(
				if (bit.get m3objs.vertFlags 19 == true) then
				(
					local DUVchan
					if (mat.decalMap != undefined) then
					(
						if (mat.decalMap.coords.mapping == 0) then 
						(
							if (mat.decalMap.mapChannel > 1) then DUVchan = mat.decalMap.coords.MapChannel
						)
					)
					append uvChannels DUVchan
				)
			)

			for k = 1 to mesh.numfaces do
			(
				M3E_buildFaces mesh k r uvChannels
			)
			
			append div.regn r
			append div.bat b
		)
	)

	return div
)

fn M3E_buildVertices regn =
(
	local varray = #()
	for i = 1 to regn.count do
	(
		local sm = regn[i]
		for j = 1 to sm.verts.count do
		(
			local v = sm.verts[j]
			local cnorm, cuv
				
			-- convert from float to byte
			for k = 1 to 4 do
			(
				v.bw[k] = (v.bw[k] * 255) as integer
			)
			
			-- compress normals
			cnorm = #(0,0,0,0)
			for k = 1 to 3 do
			(
				local cn = 1 + v.normal[k]
				cn = (cn / 2) * 255
				cnorm[k] = cn as integer
			)
			v.normal = cnorm
			
			-- compress UV's
			local cuvarray = #()
			for k = 1 to v.uv.count do
			(
				local vuv = copy v.uv[k]
				cuv = #(0,0)
				if (g_flipuvy) then vuv[2] = 1 - vuv[2]
				for h = 1 to 2 do
				(
					cuv[h] = (vuv[h] * 2046) as integer
				)
				append cuvarray cuv
			)
			
			v.uv = cuvarray
			
			append varray v
		)
	)
	
	return varray
)

struct M3E_faceNorm
(
	normal, area
)

fn M3E_getFaceSmoothGroupB obj face =
(
	local sgroup_val=getFaceSmoothGroup obj face
	local sg_bitarray=#{}

	if sgroup_val < 0 do
	(
		sg_bitarray[32] = true
		sgroup_val -= 2^31
	)

	for i = 1 to 31 do
	(
		sg_bitarray[i]= (mod sgroup_val 2 > .5)
		sgroup_val /= 2
	)

	(sg_bitarray as array)
)


fn M3E_getVertexNormals regn =
(
	local lastAnimRange, lastSliderTime
	
	if (g_doCustomVertNormals == true) then
	(
		-- setup time for edit_normals modifier
		lastAnimRange = animationRange
		lastSliderTime = sliderTime
		
		local int1 = g_bindposeFrame
		local int2 = int1 + 1
		animationRange = interval int1 int2
		sliderTime = int1
	)
	
	for r = 1 to regn.count do
	(
		local sm = regn[r]
		local mesh = sm.maxMesh

		local en
		local en_GetNormalID
		local en_GetNormal
		if (g_doCustomVertNormals == true) then
		(
			en = edit_normals()
			addModifier mesh en
			modPanel.setCurrentObject en
			en_GetNormalID = en.GetNormalID
			en_GetNormal = en.GetNormal
		)
		
		local usedVerts = #() -- used for FindItem
		local usedVertsNormals = #() -- used for normal comparison
		local newVertsReference = #()
		local newVertsList = #() -- used for building new vertex list
		for i = 1 to sm.faces.count do
		(
			local faces = getFace mesh i
			local m3faces = sm.faces[i]
			local faceSG = M3E_getFaceSmoothGroupB mesh i
			
			-- echo ("Face " + i as string)
			
			for v = 1 to 3 do
			(
				-- echo ("Vert " + v as string)
				local vInd = faces[v]
				local m3vInd = (m3faces[v] + 1)
				local m3vert = copy sm.verts[m3vInd]
				local my_vert = #{vInd}
				
				local vFaces = meshop.getFacesUsingVert mesh my_vert
				vFaces = vFaces as array

				--echo ("Shared faces: " + vFaces as string)
				local vertNormal = [0,0,0]
				
				if (g_doCustomVertNormals == true) then
				(
					local normID = en_GetNormalID i v
					--vertNormal = normalize (en_GetNormal normID)
					vertNormal = en_GetNormal normID
				)
				else
				(
					-- old smoothing group method
					if (faceSG.count > 0) then
					(
						for n = 1 to vFaces.count do
						(
							local vFace = vFaces[n]
							local vFaceSG = M3E_getFaceSmoothGroupB mesh vFace
							local vFaceProc = false
							
							for s = 1 to vFaceSG.count do
							(
								local vFaceInd = findItem faceSG vFaceSG[s]
								if (vFaceInd > 0 and vFaceProc == false) then
								(
									--echo ("Face: " + vFace as string)
									local faceNormal = getFaceNormal mesh vFace
									--echo ("Face Normal: "+ faceNormal as string)
									vertNormal = normalize (vertNormal + faceNormal)
									vFaceProc = true
								)
							)
						)
					)
					else
					(
						local faceNormal = getFaceNormal mesh i
						vertNormal = normalize (vertNormal + faceNormal)
					)
				)
				
				-- echo ("vertNormal: "+vertNormal as string)

				local usedVertsInd = findItem usedVerts m3vInd
				local vertNormalInd = 0
				
				if (usedVertsInd > 0) then
				(
					local uVertNormals = usedVertsNormals[usedVertsInd]
					-- max can't compare float values properly sometimes (what the hell???)
					-- must compare the point3's as strings to bypass the error
					vertNormalInd = findItem uVertNormals (vertNormal as string)
				)
				
				if (vertNormalInd > 0) then 
				(
					local vRef = newVertsReference[usedVertsInd][vertNormalInd]
					sm.faces[i][v] = (vRef - 1)
				)
				else
				(
					-- copy original vertex and update the normal
					local newm3vert = copy m3vert
					newm3vert.normal = vertNormal
					
					append newVertsList newm3vert
					
					sm.faces[i][v] = newVertsList.count - 1 -- update original array
					
					-- for searching for the same vertex with the same normal purposes
					local vListInd = findItem usedVerts m3vInd
					
					if (vListInd > 0) then
					(
						append usedVertsNormals[vListInd] vertNormal -- append new normal to nested array
						append newVertsReference[vListInd] newVertsList.count
					)
					else
					(
						append usedVerts m3vInd
						append usedVertsNormals #(vertNormal as string) -- create nested array with normal (needs to be string for comparison!!!)
						append newVertsReference #(newVertsList.count) -- create same nested array with vertex reference
					)
				)
			) -- end v for loop
		) -- end faces for loop
			
		/*
		echo ("new vert list: "+newVertsList as string)
		echo ("usedVertNormals: "+usedVertsNormals as string)
		echo ("vertReferences: "+newVertsReference as string)
		echo ("used verts: "+usedVerts as string)
		*/
		if (en != undefined) then deleteModifier mesh mesh.modifiers[1]
		
		sm.verts = newVertsList

		-- update original array
		regn[r] = sm
	) -- end regn for loop
	
	if (g_doCustomVertNormals == true) then
	(
		-- return to original time if edit_normals modifier used
		animationRange = lastAnimRange
		sliderTime = lastSliderTime		
	)
)

fn M3E_normWeights weights =
(
	local bw = #()
	local totalWeight = 0
	
	-- get total
	for i = 1 to 4 do
	(
		total += weights[i]
	)
	
	-- get ratio out of 1
	for i = 1 to 4 do
	(
		local normWeight = weights[i] / totalWeight
		append bw normWeight
	)
	
	return bw
)

fn M3E_getVertices m3objs m3modl =
(
	echo "Getting vertex list..."
	local varray = #()
	
	local regn = m3modl.submeshes.regn
	
	for i = 1 to regn.count do
	(
		local sm = regn[i]
		local smMesh = sm.maxMesh
		local meshInd = findItem m3objs.meshes smMesh
		local smSkin
		if (meshInd > 0) then smSkin = m3objs.skin[meshInd]
		
		if (smSkin != undefined) then
		(
			modPanel.setCurrentObject smSkin
		)
		
		for j = 1 to sm.verts.count do
		(
			local v = sm.verts[j]
			local vIndex = v.origvertindx
			
			local weights
			local bIndices
			if (smSkin != undefined) then
			(
				weights = #()
				bIndices = #()
				
				local nWeights = skinops.getvertexweightcount smSkin vIndex
				for w = 1 to nWeights do
				(
					local weightval = skinops.getvertexweight smSkin vIndex w
					
					-- only process non-zero weights
					if (weightval > 0) then
					(
						local boneid = skinops.getvertexweightboneid smSkin vIndex w
						local bname = skinops.getBoneName smSkin boneid 1
						local vboneid
						local skinBoneid
						
						for b = 1 to m3modl.bones.count do
						(
							local m3bone = m3modl.bones[b]
							if (bname == m3bone.maxObj.name) then vboneid = b
						)
					
						if (vboneid != undefined) then
						(
							skinBoneid = (findItem sm.skinBones vboneid) - 1
						)
						else throw "Vertex weighted to undefined bone!"
						
						if (skinBoneid == -1) then 
						(
							-- create local list
							append sm.skinBones vboneid
							-- create global list
							append m3modl.skinBones vboneid
							-- adjust boneid to be based on local list for verts
							skinBoneid = (sm.skinBones.count - 1)
						)
						
						append weights weightval
						append bIndices skinBoneid
					)
				)
				
				-- Sort weights into 4
				local newWeights = #(0,0,0,0)
				local newBindices = #(0,0,0,0)
	
				for k = 1 to 4 do
				(
					local weight = 0
					local bIndex = 0
					if (k <= weights.count) do
					(
						for w = 1 to weights.count do
						(
							if (k == 1) then
							(
								if (weights[w] > weight) then (weight = weights[w]; bIndex = bIndices[w])
							)
							else
							(
								if (weights[w] > weight and weights[w] <= newWeights[k-1]) then 
								(
									if ((findItem newBindices bIndices[w]) == 0) then
									(
										weight = weights[w]
										bIndex = bIndices[w]
									)
								)
							)
						)
					)
					
					newWeights[k] = weight
					newBindices[k] = bIndex
				)
				
				weights = newWeights
				bIndices = newBindices
			)
			else --if (smSkin != undefined) ... else
			(
				local bname = smMesh.name
				local vboneid
				local skinBoneid
				
				weights = #(1,0,0,0)
				bIndices = #(0,0,0,0)
				
				for b = 1 to m3modl.bones.count do
				(
					local m3bone = m3modl.bones[b]
					if (bname == m3bone.maxObj.name) then vboneid = b
				)
			
				if (vboneid != undefined) then
				(
					skinBoneid = (findItem sm.skinBones vboneid) - 1
				)
				else throw "Vertex weighted to undefined bone!"
				
				if (skinBoneid == -1) then 
				(
					-- create local list
					append sm.skinBones vboneid
					-- create global list
					append m3modl.skinBones vboneid
					-- adjust boneid to be based on local list for verts
					skinBoneid = (sm.skinBones.count - 1)
				)
				
				bIndices[1] = skinBoneid
			)
			
			v.bw = weights
			v.bi = bIndices
			
			-- update sm verts in array
			sm.verts[j] = v
		)
		
		regn[i] = sm
	)
	
	-- get proper normals
	echo "Getting vertex normals..."
	M3E_getVertexNormals regn
		
	-- build vertices for export
	echo "Building vertex list..."
	varray = M3E_buildVertices regn

	return varray
)

fn M3E_checkPath cPath =
(
	local modPath = cPath
	-- check for type of path 
	-- hard disk 
	if (matchPattern modPath pattern:"*:\\*") then
	(
		-- check if hard disk path has end backslash, add it if not
		if (modPath[modPath.count] != "\\") then modPath += "\\"
	)
	else
	(
		-- internal MPQ
		if (modPath[modPath.count] != "/") then modPath += "/"
	)
	
	return modPath
)

fn M3E_getMaterials m3mats =
(
	echo "Getting materials..."
	
	mtlarray = #()

	for i = 1 to m3mats.fullMatList.count do
	(
		local mmat = m3mats.fullMatList[i]
		local matType = mmat.materialType
		
		local mtl
		case matType of
		(
			1: mtl = M3E_Ter.init()
			2: mtl = M3E_Mat.init()
		)
		
		mtl.name = mmat.name

		local matclass = classOf mmat as string
		
		if (matclass != "Standardmaterial" and matclass != "sc2material") then
		(
			--messagebox "Materials must be of Standard or Starcraft 2 type!"
			throw "Materials must be of Standard or Starcraft 2 type"				
		)
		
		-- Export UI settings
		-- 1. Standard Material
		if (matType == 2) then
		(
			if (matclass == "Standardmaterial") then
			(
				mtl.spec	= mmat.specularLevel
			)
			
			-- 2. Starcraft 2 Material
			if (matclass == "sc2material") then
			(
				-- Flag set
				local flags = 0
				--{
				flags = bit.set flags 3 mmat.Unfogged
				flags = bit.set flags 4 mmat.TwoSided
				flags = bit.set flags 5 mmat.Unshaded
				flags = bit.set flags 6 mmat.NoShadowsCast
				flags = bit.set flags 7 mmat.NoHitTest
				flags = bit.set flags 8 mmat.NoShadowsReceived
				flags = bit.set flags 9 mmat.DepthPrepass
				flags = bit.set flags 10 mmat.UseTerrainHDR
				flags = bit.set flags 12 mmat.SplatUVfix
				flags = bit.set flags 13 mmat.SoftBlending
				--}
				
				mtl.flags				= flags
				mtl.blendMode 	= (mmat.blendMode - 1) -- -1 due to using 1 based index
				mtl.priority			= mmat.priority
				mtl.spec				= mmat.specVal
				mtl.spec_mult		= mmat.specMult
				mtl.emis_mult		= mmat.emisMult
				mtl.cutoutThresh = mmat.cutoutThresh
				mtl.layerBlendType = (mmat.layerBlendType - 1)
				mtl.emisBlendType = (mmat.emissiveBlendType - 1)
			)
			
			-- Map handling
			for k = 1 to 13 do
			(
				local layr = M3E_LAYR.init()
				local fullPath = ""
				local layrBitmap
				local curMap

				-- Different Material Handling
				-- 1. Standard Material
				if (matclass == "Standardmaterial") then
				(
					case k of
					(
						1: curMap = mmat.diffuseMap
						3: curMap = mmat.specularMap
						4: curMap = mmat.selfIllumMap
						6: curMap = mmat.reflectionMap
						10: curMap = mmat.bumpMap
					)
				)
				
				-- 2. Starcraft 2 Material
				if (matclass == "sc2material") then
				(
					case k of
					(
						1: curMap = mmat.diffuseMap
						2: curMap = mmat.decalMap
						3: curMap = mmat.specularMap
						4: curMap = mmat.selfIllumMap
						5: curMap = mmat.emisMap2
						6: curMap = mmat.envioMap
						7: curMap = mmat.envioMaskMap
						8: curMap = mmat.alphaMaskMap
						10: curMap = mmat.bumpMap
						11: curMap = mmat.heightMap
					)
				)
				
				if (curMap != undefined) then
				(
					layr.maxBitmap = curMap
					local mapClass = classOf curMap as string
					
					if (mapClass == "sc2bitmap") then
					(
						local scBitmap
						local bool_CM = false
						
						try
						(
							if (curMap.scCustomMap.count > 0) then 
							(
								scBitmap = curMap.scCustomMap
								bool_CM = true
							)
							else if (curMap.scbitmap != undefined) then 
							(
								scBitmap = curMap.scbitmap.filename
								bool_CM = false
							)
						)
						catch
						(
							scBitmap = undefined
						)
						
						if (scBitmap != undefined) then
						(
							set time g_baseFrame
							layrBitmap = scBitmap
							
							local aflags = 0
							aflags = bit.set aflags 1 curMap.TeamColour
							aflags = bit.set aflags 2 curMap.TexAlphaOnly
							layr.alphaFlags = aflags
							
							layr.flags = bit.set layr.flags 3 curMap.U_Tile
							layr.flags = bit.set layr.flags 4 curMap.V_Tile
							
							layr.UVOffset.initValue = [curMap.U_Offset, curMap.V_Offset]
							layr.UVTiling.initValue = [curMap.U_Tiling, curMap.V_Tiling]
							layr.bright_mult.initValue = curMap.Bright_Mult
							
							if (bool_CM) then
							(
								layr.flags = bit.set layr.flags 10 true
								layr.d1 = -1
								layr.d2 = 1
							)
							
							if (curMap.mapChannel > 1) then layr.uvChannel = bit.set layr.uvChannel 1 true
							
							/*
							-- handling certain maps
							if (k > 2) then
							(
								layr.d3 = 0
							)
							*/
							
							-- setup vert flags for decals
							if (k == 2) then
							(
								if (curMap.coords.mapping == 0) then 
								(
									if (curMap.mapChannel > 1) then
									(
										if (bit.get m3scene.vertFlags 19 == false) then m3scene.vertFlags = bit.set m3scene.vertFlags 19 true
									)
								)
							)
						)
						else layrBitmap = undefined
					)
					else if (mapClass == "Bitmaptexture") then
					(
						layrBitmap = curMap.bitmap.filename
					)
					else
					(
						--messageBox "Map textures must be of Bitmap or Starcraft 2 Bitmap type!"
						throw "Map textures must be of Bitmap or Starcraft 2 Bitmap type"
					)
				)
				
				/*
				if (g_UseInternalPath == false) then
				(
					fullPath = layrBitmap
				)
				else
				(
				*/
					if (layrBitmap != undefined) then
					(
						fullPath = (M3E_checkPath texPath) + (M3E_Name layrBitmap "\\")
					)
					else
					(
						fullPath = undefined
					)
				--)
					
				layr.name = fullPath
				append mtl.layrs #(layr)
			)
		)

		mtl.maxMat = mmat
		append mtlarray mtl
	)
	
	--echo ("nMaterials: "+mtlarray.count as string)
	return mtlarray
)

fn M3E_buildMaterials m3data m3materials =
(
	-- initialise containers
	m3data.matm = #()
	m3data.mat = #()
	m3data.ter = #()
	for i = 1 to m3materials.count do
	(
		local m3mat = m3materials[i]
		local matm
		matm = M3E_MATM.init()
		
		if ((isKindOf m3mat M3E_Mat) == true) then 
		(
			matm.matType = 1
			matm.matInd = m3data.mat.count
			
			append m3data.mat m3mat
		)
		if ((isKindOf m3mat M3E_Ter) == true) then 
		(
			matm.matType = 4
			matm.matInd = m3data.ter.count
			
			append m3data.ter m3mat
		)

		append m3data.matm matm
	)
	
	-- need to fix material flags for particle emitter materials
	for i = 1 to m3data.par.count do 
	(
		local par = m3data.par[i]
		local parRC = par.columns + par.rows -- need to check to see if the material has rows and columns
		
		if (parRC > 0) then
		(
			local matm = m3data.matm[par.matmIndex + 1]
			for j = 1 to 13 do 
			(
				if (m3data.mat[matm.matInd + 1].layrs[j][1].maxBitmap != undefined) then
				(
					m3data.mat[matm.matInd + 1].layrs[j][1].uvChannel = 6
				)
			)
		)
	)
)

fn M3E_buildBitmapAnims m3mats =
(
	echo "Building material bitmap animation data..."
	
	for i = 1 to m3mats.count do
	(
		local mat = m3mats[i]
		
		for j = 1 to mat.layrs.count do
		(
			local layr = mat.layrs[j][1]
			local maxBitmap = layr.maxBitmap
			
			if (maxBitmap != undefined) then
			(
				local mb = maxBitmap
				M3E_buildArefData layr.bright_mult maxBitmap #Bright_Mult #FLOAT
				
				local UVoffsetVec2D = #(#U_Offset, #V_Offset)
				M3E_buildArefData layr.UVOffset maxBitmap UVoffsetVec2D #VEC2D
				
				local UVtilingVec2D = #(#U_Tiling, #V_Tiling)
				M3E_buildArefData layr.UVTiling maxBitmap UVtilingVec2D #VEC2D
			)
			
			-- update original array
			m3mats[i].layrs[j][1] = layr
		)
	)
)

---------------------
-- M3 HELPERS  --
---------------------

fn M3E_WriteRef bitStream data reftype subtype:#none flags:0  =
(
	local ref = M3E_Ref()
	-- Make sure it isn't a null reference...
	-- Determine if data is in array or singular
	local dclass = (classOf data) as string
	
	local dcount
	if (dclass != "Array" and dclass != "String") then dcount = 1 else dcount = data.count
	if (dclass == "String") then dcount += 1 -- for null-terminated string increase string size by 1
	if (data != undefined and dcount > 0 and reftype != #null) then
	(
		-- MODL bookmark
		local bm = ftell bitStream
		
		-- head to end of file to write reference data
		fseek bitStream 0 #seek_end
		
		-- Calculate chunk size
		local byte_size = (M3E_getSize reftype) * dcount
		
		-- Append to Tags
		-- need special VERT clause
		case reftype of
		(
			#VERT: 
			(
				case subtype of
				(
					#v36: byte_size += (dcount * 4)
				)
				M3E_Tag.TagAppend bitStream #U8__ (byte_size) twrite flags:flags
				ref.entries = byte_size
			)
			default: M3E_Tag.TagAppend bitStream reftype (dcount) twrite flags:flags
		)
		M3E_WriteBlank bitStream byte_size flags:#none ret:true
		ref.refid = twrite.count - 1 -- convert to base 0
		
		-- ** REF DEBUG **
		/* 
		echo ("reftype: "+reftype as string)
		echo ("refid: "+ref.refid as string)
		echo ("data.count: "+data.count as string)
		echo ("byte_size: "+byte_size as string)
		echo ("ftell: "+(ftell bitstream) as string)
		*/
		
		if (reftype != #CHAR) then
		(
			for i = 1 to dcount do
			(
				if (dclass != "Array") then d = data else d = data[i]
				case reftype of
				(
					#SEQS: M3E_SEQS.Write bitStream d
					#STC_: M3E_STC.Write bitStream d
					#SDEV: M3E_AnimBlock.Write bitStream d #EVNT flags:1
					#EVNT: M3E_Event.Write bitStream d
					#SD2V: M3E_AnimBlock.Write bitStream d #VEC2
					#VEC2: M3E_WriteVec bitStream d #v2d
					#SD3V: M3E_AnimBlock.Write bitStream d #VEC3
					#VEC3: M3E_WriteVec bitStream d #v3d
					#SD4Q: M3E_AnimBlock.Write bitStream d #QUAT
					#QUAT: M3E_WriteVec bitStream d #v4d
					#SDR3: M3E_AnimBlock.Write bitStream d #REAL
					#REAL: M3E_WriteArray bitStream d flags:#float
					#SDS6: M3E_AnimBlock.Write bitStream d #I16_
					#STG_: M3E_STG.Write bitStream d
					#STS_: M3E_STS.Write bitStream d
					#BONE: M3E_Bone.Write bitStream d
					#VERT: M3E_Vertex.Write bitStream d
					#REGN: M3E_REGN.Write bitStream d
					#BAT_: M3E_BAT.Write bitStream d
					#MSEC: M3E_MSEC.Write bitStream d
					#PAR_: M3E_PAR.Write bitStream d
					#PARC: M3E_PARC.Write bitStream d
					#ATT_: M3E_Attachment.Write bitStream d
					#ATVL: M3E_AttachVolume.Write bitStream d
					#MATM: M3E_MATM.Write bitStream d
					#MAT_: M3E_MAT.Write bitStream d
					#TER_: M3E_TER.Write bitStream d
					#LAYR: M3E_LAYR.Write bitStream d
					#DIV_: M3E_DIV.Write bitStream d
					#IREF: M3E_WriteVec bitStream d #matrix
					#I16_: M3E_WriteArray bitStream d flags:#uint16
					#U16_: M3E_WriteArray bitStream d flags:subtype
					#U32_: M3E_WriteArray bitStream d flags:subtype
					#I32_: M3E_WriteArray bitStream d flags:subtype
				)
			)
		)
		else
		(
			WriteString bitStream data
			-- fix tag entry
			twrite[twrite.count].nData = byte_size
			ref.entries = byte_size
		)
		
		if (ref.entries == undefined) then ref.entries = dcount
		-- return to MODL bookmark
		fseek bitStream bm #seek_set
	)
	else
	(
		-- setup blank reference
		ref.entries = 0
		ref.refid = 0
	)
	
	-- write reference 
	M3E_Ref.Write bitStream ref
)

fn M3E_WriteArray bitStream data flags:#uint32 reftype:#null =
(
	-- if not array...
	local dclass = (classOf data) as string
	if (dclass != "Array") then icount = 1 else icount = data.count
	for i = 1 to icount do
	(
		local d
		if (dclass != "Array") then d = data else d = data[i]
		case flags of
		(
			#Ref: M3E_WriteRef bitStream d reftype
			#uint32: writeLong bitStream d #unsigned
			#int32: WriteLong bitStream d #signed
			#uint16: writeShort bitStream d #unsigned
			#int16: writeShort bitStream d #signed
			#uint8: writeByte bitStream d #unsigned
			#int8: writeByte bitStream d #signed
			#float: writeFloat bitStream d
			#v3d: M3E_WriteVec bitStream d #v3d
			#animind: M3E_AnimOffs.Write bitStream d
			#uvshorts: for uv = 1 to 2 do (writeShort bitStream d[uv] #unsigned)
		)
	)
)

fn M3E_GetMODL m3obj =
(
	m3 = M3E_MODL()
	
	-- grab bound sphere for SEQS and MODL structs
	set time g_baseFrame
	m3.bndSphere = M3E_GetBndSphere()
	
	m3.versID = 1576275
	if (awrite != undefined) then 
	(
		M3E_buildAnimations m3 awrite
	)
	else
	(
		m3.SEQS = #(M3E_SEQS.init())
		m3.STC = #(M3E_STC.init())
		m3.STG = #(M3E_STG.init())
		m3.STS = #(M3E_STS.initBlank m3)
	)
	m3.vec1 = [0,0,0]
	m3.bones = m3obj.bones

	local nSkinBones = 0
	for i = 1 to m3obj.skinBones.count do
	(
		local skinBoneInd = m3obj.skinBones[i] + 1
		if (skinBoneInd > nSkinBones) then nSkinBones = m3obj.skinBones[i] + 1
	)
	m3.nSkinBones = nSkinBones

	-- grab submeshes first
	m3.DIV = m3obj.submeshes
	
	-- build verts based on submesh list
	m3.verts = m3obj.verts
	m3.vflags = m3obj.vflags
	m3.bonelu = m3obj.skinBones
	
	if (m3obj.attachments != undefined) then
	(
		M3E_buildAttachments m3 m3obj.attachments
	)
	
	m3.PAR = m3obj.pemits
	m3.PARC = m3obj.parcs
	M3E_buildMaterials m3 m3obj.materials
	
	m3.iref = #()
	for i = 1 to m3.bones.count do
	(
		append m3.iref m3.bones[i].iref
	)

	return m3
)

fn M3E_getScene =
(
	step = "Gathering Scene Objects"
	echo "Gathering scene objects..."

	m3model = M3E_Model.init()
	m3scene = M3E_getSceneObjects()
	m3scene.skin = M3E_getSkin m3scene
	m3model.bones = M3E_getBones m3scene
	m3scene.materials = M3E_getUsedMats m3scene
	m3model.materials = M3E_getMaterials m3scene.materials

	m3model.submeshes = M3E_getSubmesh m3scene
	m3model.verts = M3E_getVertices m3scene m3model
	m3model.vflags = m3scene.vertFlags
	
	M3E_buildDIV m3model 	-- Build REGN's for model DIV

	M3E_buildBones m3model -- Construct bone array

	m3model.attachments = M3E_getObjects m3scene m3model #attachment -- Get attachments
	m3model.pemits = M3E_getObjects m3scene m3model #pemitter -- Get particle emitters
	m3model.parcs = M3E_getObjects m3scene m3model #pinstance -- Get particle emitter instances
	
	if (g_exportAnimation == true) then awrite = M3E_getAnimations()
	
	if (awrite != undefined) then
	(
		M3E_buildBoneAnims m3model.bones
		M3E_buildPemitAnims m3model.pemits
		M3E_buildParcAnims m3model.parcs
		M3E_buildBitmapAnims m3model.materials
	)
	echo "Gathering scene data done!"
)

fn M3E_buildM3 m3obj =
(
	step = "Build M3"
	format "Building M3 structures..." to:listener
	head = M3E_Header.init()
	-- Gather MODL data
	-- assign global, will update this structure throughout export
	mwrite = M3E_GetMODL m3obj
	
	echo "done!"
)

fn M3E_Start_Write bitStream =
(
	step = "Start Model Write"

	-- write Header and blank bytes and tag reference
	echo "Writing buffers..."
	M3E_Tag.TagAppend bitStream #MD34 1 twrite flags:11
	M3E_WriteBlank bstream (M3E_getSize #MD34) flags:#none
	
	-- Create MODL tag, write MODL blank bytes
	-- using model version 23
	M3E_Tag.TagAppend bitStream #MODL 1 twrite flags:23	
	M3E_WriteBlank bstream (M3E_getSize #MODL flags:23) flags:#none
	
	echo "Writing model data..."
	-- Write Model Data first
	M3E_MODL.Write bitStream mwrite 23	

	echo "Writing tag data..."
	-- Write Tags second...
	M3E_Tag.Write bitStream twrite
	
	echo "Writing header data..."
	-- ... and write Header last
	M3E_Header.Write bitStream head
	echo "Model writing done!\n"
)

fn M3E_ScriptTime start end =
(
	local totTime = (end - start) / 1000.0
	local totMinutes = (totTime / 60) as integer
	if (totMinutes > 0) then 
	(
		local strMinutes
		if (totMinutes > 1) then strMinutes = " minutes" else strMinutes = " minute"
		local totRemainder = mod totTime 60.0
		totTime = (totMinutes as string) + strMinutes + " " + (totRemainder as string) + " seconds"
	)
	else
	(
		totTime = (totTime as string) + " seconds"
	)
	
	return totTime
)

fn M3E_Main file =
(
	try 
	(
		if (SC2PLUGIN_VERS == undefined) then
		(
			throw ("Starcraft 2 Object definition file not found\nMake sure sc2_objects.ms is loaded before trying to export")
		)
		
		echo "\n====== Export Starting ======\n"
		M3E_Reset_Globals()
		scrStart = TimeStamp() -- start tracking script processing time
		M3E_getScene()
		M3E_buildM3(m3model)
		local mname = (M3E_Name file "\\" ext:".m3") + ".max"
		mwrite.name = mname
	
		echo "\n==== Model Information ===="
		echo ("Mesh Name: "+mwrite.name)
		if (awrite != undefined) then (echo ("Animations: "+awrite.count as string))
		echo ("Vertices: "+mwrite.verts.count as string)
		--echo ("Faces: "+m3model.mesh.numfaces as string)
		echo ("Submeshes: "+m3model.submeshes.regn.count as string)
		echo ("Materials: "+m3model.materials.count as string)
		echo ("Bones: "+m3model.bones.count as string)
		echo ("Skinned bones: "+m3model.skinBones.count as string)
		echo "" -- spacer
		
		bstream = M3E_Open file "wb"
		M3E_Start_Write bstream
		M3E_Close bstream
		
		-- Calculate Script Execution time
		scrEnd = TimeStamp()
		local scrTime = M3E_ScriptTime scrStart scrEnd
			
		format "Export took %\n" scrTime
		echo "====== Export Successful ======\n"
		messageBox ("Export Successful\nExport took "+scrTime) title:"Export successful"
	)
	catch
	(
		echo ("****"+getCurrentException()+"****")
		echo "====== Export Failed ======\n"
		messageBox ("Export failed!\n"+getCurrentException() as string) title:"Export failed"
	)
	
	clearSelection()
	setCommandPanelTaskMode #utility
	--M3E_Reset_Globals()
)

-- *********************************
--  USER INTERFACE FUNCTIONS
-- *********************************
-- Glob UI Funcs
fn M3E_GetFile ftypes =
(
	local ret = getSaveFileName types:ftypes
	if ret != undefined then return ret
)

utility M3E_export "M3 - Export"
(
	group "Scene Options"
	(
		checkbox chkExpHidden "Export Hidden Objects" checked:(g_exportHidden)
		checkbox chkExpFrozen "Export Frozen Objects" checked:(g_exportFrozen)
	)
	
	group "Texture Options"
	(
		label	lblTexPath "Internal Texture Path:" align:#left
		edittext tTexPath text:texPath
		--button bBrowsePath "Browse"
		--checkbox chkUseInternalPath "Use Internal Path" checked:(g_UseInternalPath)
		checkbox chkFlipUVY "Flip UV Y-coord" checked:(g_flipuvy)
	)
	
	group "Animation Options"
	(	
		label lblPoses "Pose Frames" align:#left
		spinner spnBindposeFrame "Bindpose:" range:[0,1e8,0] type:#integer
		spinner spnBaseFrame "Base:" range:[0,1e8,1] type:#integer
		checkbox chkExpAnim "Export Animation" checked:(g_exportAnimation)
		spinner spnUseFPS "FPS:" range:[0,1e8,1000] type:#integer
	)
	
	button bExport "Export" height:35 width:100 offset:[0,5]
	button bAbout "About" offset:[0,5]
	
	on M3E_export open do
	(
		/*
		if (chkUseInternalPath.checked == true) then
		(
			tTexPath.enabled = true
			--bBrowsePath.enabled = true
		)
		else
		(
			tTexPath.enabled = false
			--bBrowsePath.enabled = false			
		)
		*/
		if (chkExpAnim.checked == true) then spnUseFPS.enabled = true else spnUseFPS.enabled = false
	)
	on bBrowsePath pressed do
	(
		local tPath = getSavePath caption:"Texture Path"
		if (tPath != undefined) then tTexPath.text = tPath
	)
	/*
	on chkUseInternalPath changed state do
	(
		if state == on then
		(
			tTexPath.enabled = true
			--bBrowsePath.enabled = true
		)
		else
		(
			tTexPath.enabled = false
			--bBrowsePath.enabled = false
		)
	)
	*/
	on chkExpAnim changed state do
	(
		if state == on then
		(
			spnUseFPS.enabled = true
		)
		else
		(
			spnUseFPS.enabled = false
		)
	)
	on bExport pressed do
	(
		local fname = getSaveFileName types:"M3 model (*.m3)|*.m3|All Files|*.*|"
		if fname != undefined then
		(
			g_exportHidden = chkExpHidden.checked
			g_exportFrozen = chkExpFrozen.checked
			--g_UseInternalPath = chkUseInternalPath.checked
			g_flipuvy = chkFlipUVY.checked
			texPath = tTexPath.text
			g_bindposeFrame = spnBindposeFrame.value
			g_baseFrame = spnBaseFrame.value
			g_exportAnimation = chkExpAnim.checked
			g_useFPS = spnUseFPS.value
			M3E_Main(fname)
		)
	)
	on bAbout pressed do
	(
		messagebox "M3 Exporter v0.22 - 05-03-2011\n\xa9 2010, NiNtoxicated (madyavic@gmail.com)\nVisit www.sc2mapster.com for updates and more information\nHead to the forum for support. Feedback is appreciated!" title:"About"
	)
)