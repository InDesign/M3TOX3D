-- m2 -> 3ds max importer v0.304 by NiNtoxicated
-- For 3ds Max 9 and above
-- Original script found at 3d-inferno.com
-- http://3d-inferno.com/Diverse/index.php?v0=Diverse&v1=Wow%20Importer&v2=0
-- updated with textures, bones and animation by ufo
-- updated further by NiNtoxicated (madyavic@hotmail.com)
--
-- Works with 3.* and above World of Warcraft models as of 22-07-2010
-- Designed to work with WotLK models, but tested to work with Cataclysm models too
-- Currently imports:
-- - Geometry
-- - Materials
-- - Skin/Bones
-- - Animation
-- - Attachments
--
-- Special thanks to:
-- ufoZ - For originally creating the script a long time ago
-- WoWModelViewer team - for updating the program to work with Lich King models
-- sc2mapster.com - for providing motivation to update the script
-- Blizzard's art team - for creating great models
-- Jon-Huhn from CGTalk - Borrowed his code from this forum thread http://forums.cgsociety.org/showthread.php?t=598014
-- Fixes bug in dotnet ListView controls.
--
-- Version History:
-- 0.304 - July 25th 2010
-- Converted activeX controls to dotnet for 64-bit OS compatibility
--
-- 0.303 - July 24th 2010
-- Revamped original script to work with new model format
-- Vastly improved UI for importing geometry and animations
-- Animations no longer suffer from gimbal lock
-- Added Import as M3 option
-- Vertex normals are now applied semi-properly
-- Added basic conversion principles for converting M2 properties to M3
-- Added basic error catching
--
-- Head to http://www.sc2mapster.com/ for more information and support

--
-- Script to import m2 files as included in the mpq files of world of warcraft into GMax/3dsmax
--

--
-- GLOBALS AND STRUCTURES
--

-- UI SETTINGS - Default Settings (Replaced by INI file if present or created by user via UI)
-- Paths
global WOW2_DBCPath		= "Locate DBC Path"

global AnimDataDBC = "AnimationData.dbc"

global WOW2_Dialog
global WOW2_ModelUI

-- some options
global WOW2_ImportAsM3 		= true
global WOW2_doVertexNormals 	= true
global WOW2_useFPS 				= 1000	-- fps to rescale animations to
global WOW2_M3Scale				= 0.5
global WOW2_flipuv_y 				= true  -- change this if textures appear upside down

-- INI file
global m2impini = ((GetDir #plugcfg)+"\\m2import.ini")

-- model files (overwritten by UI)
global filename
global sknFile
global dbcFile


-- globals
global mdata, skndata, dbcdata, m2bones, mstream, sknstream, step

-- LOOKUP TABLE INFORMATION
-- Attachment String Table
global WOW2_attachid = #("Left wrist (shield) / Mount", "Right Palm", "Left Palm", "Right Elbow", "Left Elbow", -- 0 - 4
					"Right Shoulder", "Left Shoulder", "Right Knee", "Left Knee", "Right Hip", -- 5 - 9
					"Left Hip", "Helmet", "Back", "Right Shoulder Horizontal", "Left Shoulder Horizontal", -- 10 - 14
					"Front Hit Region", "Rear Hit Region", "Mouth", "Head Region", "Base", -- 15 - 19
					"Above", "Pre-Cast 1 L", "Pre-Cast 1 R", "Pre-Cast 2 L", "Pre-Cast 2 R", -- 20 - 24
					"Pre-Cast 3", "Upper Back Sheath R", "Upper Back Sheath L", "Middle Back Sheath", "Belly", -- 25 - 29
					"Reverse Back, Up Back L", "Right Back", "Left Hip Sheath", "Right Hip Sheath", "Spell Impact", -- 30 - 34
					"Right Palm (Unk1)", "Right Palm (Unk2)") -- 35 - 36
	

-- Block F - Bone lookup table.	(Reference taken from the .exe, help from Model Viewer also)	
global WOW2_keyboneid = #(
							"ArmL",				-- 0, Left upper arm
							"ArmR",				-- 1, Right upper arm
							"ShoulderL",		-- 2, Left Shoulder / deltoid area
							"ShoulderR",		-- 3, Right Shoulder / deltoid area
							"SpineLow",			-- 4, (upper?) abdomen
							"Waist",				-- 5, (lower abdomen?) waist
							"Head",				-- 6, head
							"Jaw",				-- 7, jaw/mouth
							"IndexFingerR",	-- 8, (Trolls have 3 "fingers", this points to the 2nd one.
							"MiddleFingerR",	-- 9, center finger - only used by dwarfs.. don't know why
							"PinkyFingerR",		-- 10, (Trolls have 3 "fingers", this points to the 3rd one.
							"RingFingerR",		-- 11, Right fingers -- this is -1 for trolls, they have no fingers, only the 3 thumb like thingys
							"ThumbR",			-- 12, Right Thumb
							"IndexFingerL",	-- 13, (Trolls have 3 "fingers", this points to the 2nd one.
							"MiddleFingerL",	-- 14, Center finger - only used by dwarfs.
							"PinkyFingerL",		-- 15, (Trolls have 3 "fingers", this points to the 3rd one.
							"RingFingerL",		-- 16, Left fingers
							"ThumbL",			-- 17, Left Thumb
							"$BTH",				-- 18, Upper-Mouth
							"$CSR",				-- 19, ? Mouth2? Right Palm on characters??
							"$CSL",				-- 20, ? Above Character? Right Palm again on characters??
							"_Breath",			-- 21, ? Mouth on characters (seems like a sound origin?)
							"_Name",			-- 22, Above Character (Not linked to other bones)
							"_NameMount",	-- 23, Infront of chest (Not linked) 
							"$CHD",				-- 24, Conn to Central Head Bone, used by Event $CHD (Character Head)
							"$CCH",				-- 25, Conn to Upper Chest bone, used by Event $CCH (Character Chest)
							"Root",				-- 26, The "Root" bone,  this controls rotations, transformations, etc of the whole model and all subsequent bones.
							"Wheel1",			-- 27.
							"Wheel2",			-- 28.
							"Wheel3",			-- 29.
							"Wheel4",			-- 30.
							"Wheel5",			-- 31.
							"Wheel6",			-- 32.
							"Wheel7",			-- 33.
							"Wheel8"			-- 34.
						)				
					
global meshTypes = 	#(
									"Mesh", "Facial1", "Facial2", "Facial3", "Braces", "Boots", "Mesh", "Ears",
									"Wristbands", "Kneepads", "Pants", "Pants", "Tabard", "Trousers", "Mesh", "Cape",
									"Mesh", "Eyeglows", "Belt", "Hairstyles"
								)

-- Version Numbers
global M2_V2 = 260 -- M2 v2.0+
								
-- M3 variables
global WOW2_sc2vers = 0.05
global WOW2_m3bone

-- INI Control
--
-- Check INI setting
fn ReadINI INIFile flag Directory Setting globSett =
(
	-- flag (read as): 1-string 2-bool 3-integer 4-float
	local c = getINISetting (INIFile) (Directory) (Setting)
	
	if (c != "") then
	(
		case flag of
		(
			#string: return c
			#bool: return c as booleanClass
			#int: return c as integer
			#float: return c as float
		)
	)
	else
	(
		format "Setting % \\ % not found! Using default setting...\n" Directory Setting
		return globSett
	)
)

-- Read
global ini_section = #("Settings", "Paths")
if (doesFileExist m2impini) then
(
	-- Options
	WOW2_ImportAsM3 = ReadINI m2impini #bool ini_section[1] "M3"			WOW2_ImportAsM3
	WOW2_useFPS	= ReadINI m2impini #int ini_section[1] "FPS"				WOW2_useFPS
	WOW2_flipuv_y	= ReadINI m2impini #bool ini_section[1] "FlipUV_Y"		WOW2_flipuv_y
	WOW2_doVertexNormals = ReadINI m2impini #bool ini_section[1] "VertexNormals"	WOW2_doVertexNormals
	WOW2_M3Scale = ReadINI m2impini #float ini_section[1] "M3Scale" WOW2_M3Scale
	
	-- Paths
	WOW2_DBCPath	= ReadINI m2impini #string ini_section[2] "DBC"			WOW2_DBCPath
)
else
(
	format "% not found! Using default settings...\n" m2impini
)

-- INI Write Function
fn WriteINI INIFile =
(
	--Default Settings
	setINISetting (INIFile)	ini_section[1] ("M3")				(WOW2_ImportAsM3 as string)
	setINISetting (INIFile) 	ini_section[1] ("FPS")				(WOW2_useFPS as string)
	setINISetting (INIFile)	ini_section[1] ("FlipUV_Y")			(WOW2_flipuv_y as string)
	setINISetting (INIFile)	ini_section[1] ("VertexNormals")	(WOW2_doVertexNormals as string)
	setINISetting (INIFile)	ini_section[1] ("M3Scale")			(WOW2_M3Scale as string)
	
	--Path Settings
	setINISetting (INIFile) 	ini_section[2]	("DBC")				(WOW2_DBCPath)
)
-- INI control end!

-- *******************************************
-- **			M2 Reading Code				**
-- *******************************************
--

fn WOW2_Convert_Time t =
(
	t / (1000 / WOW2_useFPS)
)

fn WOW2_Reset_Globals =
(
	-- RESET GLOBALS
	mdata = skndata = dbcdata = m2bones = mstream = sknstream = step = undefined
	gc()
)

--
-- HELPERS
fn echo msg =
(
	format "%\n" (msg) to:listener
)

fn WOW2_toUpper str =
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

fn ReadFixedString bitStream fixedLen =
(
	local str = ""
	for i = 1 to fixedLen do
	(
		str += bit.intAsChar (ReadByte bitStream #unsigned)
	)
	return str
)

fn WOW2_ShortToFloat val = -- Short to Float func
(
	if (val > 0) then (val -= 32767) else (val += 32768)
	val /= 32767.0
	return val
)

fn WOW2_ReadVec bitStream flag array:0 =
(
	local va = #()
	local vec = [0,0,0]
	
	-- Check if array of vectors or single vector
	if array == 0 then 
	(
		count = 1
	)
	else 
	(
		count = array
		-- Initialize array
		va[count] = 0
	)
	
	for i = 1 to count do
	(
		case flag of
		(
			#v3dshort: (vec.x = ReadShort bitStream #unsigned; vec.y = ReadShort bitStream #unsigned; vec.z = ReadShort bitStream #unsigned;)
			#v3dlong: (vec.x = ReadLong bitStream #unsigned; vec.y = ReadLong bitStream #unsigned; vec.z = ReadLong bitStream #unsigned;)
			#v3dbyte: (vec.x = ReadByte bitStream #unsigned; vec.y = ReadByte bitStream #unsigned; vec.z = ReadByte bitStream #unsigned;)
			#quat: (vec = quat 0 0 0 1; vec.x = ReadFloat bitStream; vec.y = ReadFloat bitStream; vec.z = ReadFloat bitStream; vec.w = ReadFloat bitStream;)
			#quatShort: 
			(
				vec = quat 1
				vec.x = WOW2_ShortToFloat (ReadShort bitStream #signed)
				vec.y = WOW2_ShortToFloat (ReadShort bitStream #signed)
				vec.z = WOW2_ShortToFloat (ReadShort bitStream #signed)
				vec.w = WOW2_ShortToFloat (ReadShort bitStream #signed)
			)
			#v4dshort: (vec = [0,0,0,0]; vec.x = ReadShort bitStream #signed; vec.y = ReadShort bitStream #signed; vec.z = ReadShort bitStream #signed; vec.w = ReadShort bitStream #signed;)
			#v4dbyte: (vec = [0,0,0,0]; vec.x = ReadByte bitStream; vec.y = ReadByte bitStream; vec.z = ReadByte bitStream; vec.w = ReadByte bitStream;)
			#v3d: (vec = [0.0,0.0,0.0]; vec.x = ReadFloat bitStream; vec.y = ReadFloat bitStream; vec.z = ReadFloat bitStream;)
			#matrix: 
			(
				vma = #()
				vma[4] = 0
				for j = 1 to 4 do
				(
					local vm = [0,0,0,0]
					vm.x = ReadFloat bitStream; vm.y = ReadFloat bitStream; vm.z = ReadFloat bitStream; vm.w = ReadFloat bitStream;
					vma[j] = vm
				)
				vec = matrix3 vma[1] vma[2] vma[3] vma[4]
			)
		)
		if (array != 0) then (va[i] = vec) else (va = vec)
	)
	
	return va
)

fn SkipBytes bitStream count =
(
	local unknown
	case count of
	(
		2: unknown = ReadShort bitStream #unsigned
		4: unknown = ReadLong bitStream #unsigned
		default:
		(
			for i = 1 to count do
			(
				unknown = ReadByte bitStream #unsigned
			)
		)
	)
)
	
fn WOW2_CompareStructs struct1 struct2 =
(
	local structClasses = #(classOf struct1 as string, classOf struct2 as string)
	if (structClasses[1] != structClasses[2]) then return false

	local structProps = getPropNames struct1
	local propCount = structProps.count
	for i = 1 to propCount do
	(
		local propClass = classOf (getProperty struct1 structProps[i]) as string
		if (propClass != "MAXScriptFunction") then
		(
			if ((getProperty struct1 structProps[i]) != (getProperty struct2 structProps[i])) then 
			(
				return false
			)
		)
	)
	
	return true
)

--
-- WOW M2 FUNCTIONS

-- ****************************************
-- **			DBC Reading Code			**
-- ****************************************
--
struct WOW2_DBC
(
	head, records
)

struct WOW2_DBC_Header
(
	fileID, nRecords, nFields, recordSize, stringBlockSize,
	
	fn Read bitStream =
	(
		local head = WOW2_DBC_Header()
		head.fileID = ReadFixedString bitStream 4
		head.nRecords = ReadLong bitStream #unsigned
		head.nFields = ReadLong bitStream #unsigned
		head.recordSize = ReadLong bitStream #unsigned
		head.stringBlockSize = ReadLong bitStream #unsigned
		
		return head
	)
)

struct WOW2_DBC_AnimField
(
	animID, name, WeaponState, flags, d1, parentAnimID, realID, aGroup,
	
	fn Read bitStream head =
	(
		local dbcrecords = #()
		dbcrecords[head.nRecords] = 0
		str_ofs = (head.recordSize * head.nRecords) + 20 --header size
		for i = 1 to head.nRecords do
		(
			local af = WOW2_DBC_AnimField()
			af.animID = ReadLong bitStream #unsigned
			af.name = ReadLong bitStream #unsigned
			af.WeaponState = ReadLong bitStream #unsigned
			af.flags = ReadLong bitStream #unsigned
			af.d1 = ReadLong bitStream #unsigned
			af.parentAnimID = ReadLong bitStream #unsigned
			af.realID = ReadLong bitStream #unsigned
			af.aGroup = ReadLong bitStream #unsigned
			
			local bm = ftell bitStream
			local nameOfs = (str_ofs + af.name)
			fseek bitStream nameOfs #seek_set 
			af.name	= ReadString bitStream
			fseek bitStream bm #seek_set

			dbcrecords[i] 	= af
		)
		
		return dbcrecords		
	)
)

fn WOW2_DBC_AnimDBC dbcfile =
(
	local dbcstream
	try
	(
		dbcstream = fopen dbcfile "rb"
		if dbcstream==undefined then 
		(
			echo (dbcfile + " not found!")
			return undefined
		)
		
		local adbc = WOW2_DBC()
		adbc.head = WOW2_DBC_Header.Read dbcstream
		if (adbc.head.fileID != "WDBC") then
		(
			echo (dbcfile + " invalid DBC file!")
			if (dbcstream != undefined) then fclose dbcstream
			return undefined
		)
		adbc.records = WOW2_DBC_AnimField.Read dbcstream adbc.head
		
		if (dbcstream != undefined) then fclose dbcstream
		
		return adbc
	)
	catch
	(
		echo (dbcfile + " unreadable! DBC file not used")
		if dbcstream != undefined then fclose dbcstream
		return undefined
	)
)

-- ****************************************
-- **			Model Reading Code			**
-- ****************************************
--

struct WOW2_Sphere
(
	vmin, vmax, rad,
	
	fn Read bitStream =
	(
		local s = WOW2_Sphere()
		s.vmin = WOW2_ReadVec bitStream #v3d
		s.vmax = WOW2_ReadVec bitStream #v3d
		s.rad = ReadFloat bitStream
		
		return s
	)
)

struct WOW2_Entry
(
	nEntry, ofsEntry,
	
	fn Read bitStream =
	(
		local entry = WOW2_Entry()
		entry.nEntry = ReadLong bitStream #unsigned
		entry.ofsEntry = ReadLong bitStream #unsigned
		
		return entry
	),
	fn Setup bitStream entry =
	(
		local earray = #()
		if (entry.nEntry > 0) then
		(
			earray[entry.nEntry] = 0
			fseek bitStream entry.ofsEntry #seek_set
		)
		
		return earray
	)
)

fn WOW2_ReadData bitStream entry type =
(
	local darray
	local bm = ftell bitStream
	if (type != #string) then
	(
		darray = WOW2_Entry.Setup bitStream entry
	)
	else
	(
		darray = ""
		fseek bitStream entry.ofsEntry #seek_set
	)
	
	for i = 1 to entry.nEntry do
	(
		case type of
		(
			#string:
			(
				darray += bit.intAsChar (ReadByte bitStream #unsigned)
			)
			#vertProps:
			(
				local vprops = #()
				for j = 1 to 4 do
				(
					local vp = ReadByte bitStream #unsigned
					
					append vprops vp
				)
				darray[i] = vprops
			)
			#int16: darray[i] = ReadShort bitStream #signed
			#uint16: darray[i] = ReadShort bitStream #unsigned
			#uint32: darray[i] = ReadLong bitStream #unsigned
			#frames: darray[i] = WOW2_Convert_Time (ReadLong bitStream #unsigned)
			#v3d: darray[i] = WOW2_ReadVec bitStream #v3d
			#quat: darray[i] = WOW2_ReadVec bitStream #quatShort
		)
	)
	
	fseek bitStream bm #seek_set
	
	return darray
)

struct WOW2_Header
(
	fileID, version,
	name,
	type,
	GlobalSequences,
	anims, animsLU,
	Bones, KeyBones,
	Verts,
	nViews,
	Colours, Textures, Trans,
	TexAnims, TexReplace,
	RenderFlags,
	BonesLU,
	TexLU, TexUnitsLU, TransLU, TexAnimsLU,
	collisionSphere, boundSphere,
	BoundTris, BoundVerts, BoundNorms,
	Attachs, AttachsLU,
	Events, 
	Lights,
	Cameras, CamerasLU,
	Ribbons,
	Particles,
	
	fn Read bitStream =
	(
		local header = WOW2_Header()
		
		header.fileID = (ReadFixedString bitStream 4)
		header.version = ReadLong bitStream #unsigned
		-- echo ("Version: "+(header.version as string))
		header.name = WOW2_Entry.Read bitStream
		header.type = ReadLong bitStream #unsigned
		header.GlobalSequences = WOW2_Entry.Read bitStream
		header.anims = WOW2_Entry.Read bitStream
		header.animsLU = WOW2_Entry.Read bitStream
		header.Bones = WOW2_Entry.Read bitStream
		header.KeyBones = WOW2_Entry.Read bitStream
		header.Verts = WOW2_Entry.Read bitStream
		header.nViews = ReadLong bitStream #unsigned
		header.Colours = WOW2_Entry.Read bitStream
		header.Textures = WOW2_Entry.Read bitStream
		header.Trans = WOW2_Entry.Read bitStream
		header.TexAnims = WOW2_Entry.Read bitStream
		header.TexReplace = WOW2_Entry.Read bitStream
		header.RenderFlags = WOW2_Entry.Read bitStream
		header.BonesLU = WOW2_Entry.Read bitStream
		header.TexLU = WOW2_Entry.Read bitStream
		header.TexUnitsLU = WOW2_Entry.Read bitStream
		header.TransLU = WOW2_Entry.Read bitStream
		header.TexAnimsLU = WOW2_Entry.Read bitStream
		header.collisionSphere = WOW2_Sphere.Read bitStream
		header.boundSphere = WOW2_Sphere.Read bitStream
		header.boundTris = WOW2_Entry.Read bitStream
		header.boundVerts = WOW2_Entry.Read bitStream
		header.boundNorms = WOW2_Entry.Read bitStream
		header.Attachs = WOW2_Entry.Read bitStream
		header.AttachsLU = WOW2_Entry.Read bitStream
			
		return header
	)
)

struct WOW2_Bezier
(
	pos = [0,0,0], inTan = [0,0,0], outTan = [0,0,0]
)

struct WOW2_Vertex
(
	pos,bw = #(),bi = #(),normal,uv,n2floats,
	
	fn Read bitStream entry =
	(
		local varray = WOW2_Entry.Setup bitStream entry
		for i = 1 to entry.nEntry do
		(
			local vert = WOW2_Vertex()
			vert.pos = WOW2_ReadVec bitStream #v3d
			
			-- Weights
			m2weights = #()
			for j = 1 to 4 do 
			(
				local bWeight = ReadByte bitStream #unsigned
				append m2weights bWeight
			)
			
			-- Bone Indices
			m2bindices = #()
			for j = 1 to 4 do 
			(
				local bIndice = ReadByte bitStream #unsigned
				bIndice = bIndice
				append m2bindices bIndice
			)
			
			-- Build true weights/bone indices
			vert.bi = #()
			vert.bw = #()
			for j = 1 to 4 do
			(
				local weight = m2weights[j]
				local bind = m2bindices[j]
				if (weight > 0) then
				(
					local w = weight / 255.0
					local b = bind + 1 -- maxscript arrays are 1-based
					
					append vert.bw w
					append vert.bi b
				)
			)
			
			vert.normal = WOW2_ReadVec bitStream #v3d
			
			-- UV coordinates
			-- must be point3 when building mesh
			vert.uv = [0,0,0]
			for j = 1 to 2 do
			(
				local uv = ReadFloat bitStream
				if (j == 2 and WOW2_flipuv_y == true) then uv = 1 - uv
				vert.uv[j] = uv
			)
			
			vert.n2floats = #()
			for j = 1 to 2 do
			(
				local f = ReadFloat bitStream
				append vert.n2floats f
			)
			
			varray[i] = vert
		)
		
		return varray
	)
)

struct WOW2_M3SEQS
(
	name, seqInd, cstart, cend, moveSpeed, looping, freq
)

struct WOW2_Animation
(
	animID, subanimID, frames, 
	moveSpeed, flags, rarity, playSpeed, 
	boundSphere, animLink, index,
	name, cstart, cend, animFile, process = true,
	uiIndex, order,
	
	fn Read bitStream entry =
	(
		local animArray = WOW2_Entry.Setup bitStream entry
		for i = 1 to animArray.count do
		(
			local anim = WOW2_Animation()
			
			anim.animID = ReadShort bitStream #unsigned
			anim.subanimID = ReadShort bitStream #unsigned
			local frames = ReadLong bitStream #unsigned
			anim.frames = WOW2_Convert_Time frames
			anim.moveSpeed = ReadFloat bitStream
			anim.flags = ReadLong bitStream #unsigned
			local rarity = ReadShort bitStream #unsigned
			rarity = (rarity / 32767.0) * 100
			anim.rarity = rarity as integer
			SkipBytes bitStream 10
			anim.playSpeed = ReadLong bitStream #unsigned
			anim.boundSphere = WOW2_Sphere.Read bitStream
			anim.animLink = ReadShort bitStream #signed
			anim.index = ReadShort bitStream #unsigned
			anim.uiIndex = i - 1
			anim.order = i
			
			animArray[i] = anim
		)
		
		return animArray
	)
)

struct WOW2_AnimBlock
(
	type, seq, times, keys,
	
	fn Read bitStream =
	(
		local ab = WOW2_AnimBlock()
		
		ab.type = ReadShort bitStream #unsigned
		ab.seq = ReadShort bitStream #signed
		ab.times = WOW2_Entry.Read bitStream
		ab.keys = WOW2_Entry.Read bitStream
		
		return ab
	),
	fn GetData bitStream anims abdata flags =
	(
		tarray = #()
		if (abdata.nEntry > 0) then
		(
			tarray = WOW2_Entry.Setup bitStream abdata
			-- Grab entries
			for i = 1 to tarray.count do
			(
				tarray[i] = WOW2_Entry.Read bitStream
			)
			
			-- Fill data from entries
			for i = 1 to tarray.count do
			(
				local anim = anims[i]
				local ent = tarray[i]
				
				if (ent.nEntry > 0 and anim.process == true) then
				(
					local dataStream
					if anim.animFile != undefined then
					(
						if (getFileSize anim.animFile > ent.ofsEntry) then dataStream = fopen anim.animFile "rb"
						if (dataStream != undefined) then tarray[i] = WOW2_ReadData dataStream tarray[i] flags
					)
					
					if (dataStream == undefined) then
					(
						tarray[i] = WOW2_ReadData bitStream tarray[i] flags
					)
					else
					(
						fclose dataStream
					)
				)
				else
				(
					tarray[i] = #()
				)
			)
		)
		return tarray
	),
	fn Fill bitStream anims ablock flags =
	(
		-- do time entries first
		ablock.times = WOW2_AnimBlock.GetData bitStream anims ablock.times #frames
		ablock.keys = WOW2_AnimBlock.GetData bitStream anims ablock.keys flags
	)
)

struct WOW2_Bone
(
	keyIndex, flags, parent, s1, abtrans, abrot, abscale, pivot,
	maxObj,
	
	fn Read bitStream entry =
	(
		local barray = WOW2_Entry.Setup bitStream entry
		for i = 1 to entry.nEntry do
		(
			local m2bone = WOW2_Bone()
			
			m2bone.keyIndex = (ReadLong bitStream #signed) + 1
			m2bone.flags = ReadLong bitStream #unsigned
			m2bone.parent = (ReadShort bitStream #signed) + 1
			local s1a = #()
			for j = 1 to 3 do append s1a (ReadShort bitStream #unsigned)
			m2bone.s1 = s1a
			m2bone.abtrans = WOW2_AnimBlock.Read bitStream
			m2bone.abrot = WOW2_AnimBlock.Read bitStream
			m2bone.abscale = WOW2_AnimBlock.Read bitStream
			m2bone.pivot = WOW2_ReadVec bitStream #v3d
			
			barray[i] = m2bone
		)
		
		return barray
	)
)

struct WOW2_Submesh
(
	id, indverts, nverts, indfaces, nfaces,
	nbones, indbones,
	s1,b1,
	boundSphere,
	m2verts = #(), maxMesh, process = true,
	name, uiIndex, order, -- for UI only
	
	fn Read bitStream entry =
	(
		local smarray = WOW2_Entry.Setup bitStream entry
		for i = 1 to entry.nEntry do
		(
			local submesh = WOW2_Submesh()
			
			submesh.id = ReadLong bitStream #unsigned
			submesh.indverts = ReadShort bitStream #unsigned
			submesh.nverts = ReadShort bitStream #unsigned
			submesh.indfaces = ReadShort bitStream #unsigned
			submesh.nfaces = ReadShort bitStream #unsigned
			submesh.nbones = ReadShort bitStream #unsigned
			submesh.indbones = ReadShort bitStream #unsigned
			submesh.s1 = ReadShort bitStream #unsigned
			submesh.b1 = ReadShort bitStream #unsigned
			submesh.boundSphere = WOW2_Sphere.Read bitStream
			submesh.uiIndex = i - 1
			submesh.order = i
			
			local subid = submesh.id / 100
			if (subid == 0) then
			(
				-- Hairstyles
				if ((mod subid 100) > 0) then subid = 21 else subid += 1 
			)
			else
			(
				subid += 1
			)
			submesh.name = meshTypes[subid]
			
			smarray[i] = submesh
		)
		
		return smarray
	)
)
	
struct WOW2_TexUnit
(
	texFlags, shaderFlags,
	SubInd, SubInd2,
	ColourInd, renderFlagsInd,
	TexUnitInd, Mode, TexInd, TexUnitInd2,
	TransInd, TexAnimInd,
	maxMaterial,
	
	fn Read bitStream entry =
	(
		local tuarray = WOW2_Entry.Setup bitStream entry
		
		for i = 1 to entry.nEntry do
		(
			local TexUnit = WOW2_TexUnit()
			
			TexUnit.texFlags = ReadShort bitStream #unsigned
			TexUnit.shaderFlags = ReadShort bitStream #unsigned
			TexUnit.SubInd = (ReadShort bitStream #unsigned) + 1
			TexUnit.SubInd2 = (ReadShort bitStream #unsigned) + 1
			TexUnit.ColourInd = (ReadShort bitStream #signed) + 1
			TexUnit.renderFlagsInd = (ReadShort bitStream #unsigned) + 1
			TexUnit.TexUnitInd = (ReadShort bitStream #unsigned) + 1
			TexUnit.Mode = ReadShort bitStream #unsigned
			TexUnit.TexInd = (ReadShort bitStream #unsigned) + 1
			TexUnit.TexUnitInd2 = (ReadShort bitStream #unsigned) + 1
			TexUnit.TransInd = (ReadShort bitStream #unsigned) + 1
			TexUnit.TexAnimInd = (ReadShort bitStream #unsigned) + 1
			
			tuarray[i] = TexUnit
		)
		
		return tuarray
	)
)

struct WOW2_SkinHeader 
(
	fileID, 
	Indices, Faces, VertInds,
	Submeshes, TexUnits,
	nSkinnedBones,
	
	fn Read bitStream =
	(
		local shead = WOW2_SkinHeader()
		
		shead.fileID = (ReadFixedString bitStream 4)
		if (shead.fileID != "SKIN") then throw "Invalid SKIN file!"
		shead.Indices = WOW2_Entry.Read bitStream
		shead.Faces = WOW2_Entry.Read bitStream
		shead.VertInds = WOW2_Entry.Read bitStream
		shead.Submeshes = WOW2_Entry.Read bitStream
		shead.TexUnits = WOW2_Entry.Read bitStream
		shead.nSkinnedBones = ReadLong bitStream #unsigned
		
		return shead
	),
	fn Fill bitStream skinData =
	(
		skinData.Indices = WOW2_ReadData bitStream skinData.Indices #uint16
		skinData.Faces = WOW2_ReadData bitStream skinData.Faces #uint16
		skinData.VertInds = WOW2_ReadData bitStream skinData.VertInds #vertProps
		skinData.Submeshes = WOW2_Submesh.Read bitStream skinData.Submeshes
		skinData.TexUnits = WOW2_TexUnit.Read bitStream skinData.TexUnits
	)
)

struct WOW2_Texture
(
	-- type:
	--0  Texture given in filename
	--1  Body + clothes
	--2  Cape
	--6  Hair, beard
	--8  Tauren fur
	--11  Skin for creatures
	--12  Skin for creatures #2
	--13  Skin for creatures #3

	type, flags, texFile,
	filename, convfilename,
	
	fn Read bitStream entry =
	(
		local texArray = WOW2_Entry.Setup bitStream entry
		
		for i = 1 to entry.nEntry do
		(
			local tex = WOW2_Texture()
			
			tex.type = ReadLong bitStream #unsigned
			tex.flags = ReadLong bitStream #unsigned
			tex.texFile = WOW2_Entry.Read bitStream
			tex.texFile = WOW2_ReadData mstream tex.texFile #string
			
			texArray[i] = tex
		)
		
		return texArray
	)
)

struct WOW2_Attachment
(
	id, bone, flags, pos, vis, -- vis = Animation Block for visibility, assuming (Short Keys: 0 = off, 1 = on)
	maxObj,
	name, uiIndex, order,
	
	fn Read bitStream entry =
	(
		local attarray = WOW2_Entry.Setup bitStream entry
		
		for i = 1 to entry.nEntry do
		(
			local mattach = WOW2_Attachment()
			mattach.id = (ReadLong bitStream #unsigned) + 1
			mattach.bone = ReadShort bitStream #unsigned
			mattach.flags = ReadShort bitStream #unsigned
			mattach.pos = WOW2_ReadVec bitStream #v3d
			mattach.vis = WOW2_AnimBlock.Read bitStream
			
			try
			(
				if (mattach.id < WOW2_attachid.count) then
				(
					mattach.name = WOW2_attachid[mattach.id]
				)
				else
				(
					mattach.name = ("Attachment" + ((i - 1) as string))
				)
			)
			catch
			(
				mattach.name = ("Attachment" + ((i - 1) as string))
			)
			
			attarray[i] = mattach
		)
		
		return attarray
	)
)

struct WOW2_RenderFlags
(
	flags, blendmode,
	
	fn Read bitStream entry =
	(
		local rfarray = WOW2_Entry.Setup bitStream entry
		
		for i = 1 to entry.nEntry do
		(
			local rf = WOW2_RenderFlags()
			
			rf.flags = ReadShort bitStream #unsigned
			rf.blendmode = ReadShort bitStream #unsigned
			
			rfarray[i] = rf
		)
		
		return rfarray
	)
)

fn WOW2_Open fname =
(
	step = "Accessing File"
	-- check to see if this is a real path
	
	local fileBStream = fopen fname "rb"
	if fileBStream==undefined then 
	(
		echo "File not found!"
		throw "File not found"
	)
	
	return fileBStream
)

fn WOW2_Close bitStream =
(
	if (bitStream != undefined) then fclose bitStream
)

-- ****************************************
-- **			Max Scene Code			      **
-- ****************************************
--

fn WOW2_SetVertexNormals mesh verts =
(
	max modify mode
	addmodifier mesh (edit_normals name:"vnorms")
	en = mesh.modifiers[#vnorms]
	modPanel.setCurrentObject en

	en.displaylength = 0.05
	
	-- speeds up processing
	en_SetExplicit = en.SetNormalExplicit
	en_SetNormal = en.SetNormal
	en_SetNormalID = en.SetNormalID
	en_ConvVert	= en.ConvertVertexSelection
	en_SetSelection = en.SetSelection
	en_Unify = en.unify
	en_Move = en.move
	
	-- Method: 1
	for i = 1 to verts.count do
	(
		my_vert = #{i}
		my_norm = #{}
		en_ConvVert &my_vert &my_norm
		en_SetSelection my_norm node:mesh
		en_Unify node:mesh
		en_Move verts[i].normal
	)


	/*
	-- Method 2:
	-- way too slow...but sets normal ID to vertex ID's
	for i = 1 to en.GetNumFaces() do
	(
		for j = 1 to 3 do
		(
			vind = en.getVertexID i j
			en_SetNormalID i j vind
			en_SetExplicit vind
			en_SetNormal vind verts[vind].normal
		)
	)
	en.RebuildNormals()
	*/

	local nNormals = en.getNumNormals node:mesh
	en.select #{1..nNormals} node:mesh -- select all normals
	en.MakeExplicit node:mesh -- make them explicit
	en.select #{1..nNormals} node:mesh invert:true -- deselect them

	
	-- collapse edit_normal modifier
	collapseStack mesh
)

fn WOW2_Create_Submesh smesh skinIndices skinFaces mVerts smName =
(
	local faceList = #()
	local vertList = #()
	local tvertList = #()
	
	-- Building the Submeshes
	-- build faces by submesh
	--echo ("sm_"+s as string+".nfaces: "+smesh.nfaces as string +" indfaces:" + sm.indfaces as string)

	local nFaces = smesh.nfaces
	if ((mod (nFaces) 3) != 0.0 ) then echo "#ERROR sm.tris not a multiple of 3!"
	--else echo "#INFO sm.tris check passed!"
	
	--echo ("Creating Submesh_" + s as string)
	for i = 1 to nFaces by 3 do
	(
		local face = [0,0,0]
		for j = 1 to 3 do
		(
			local k = smesh.indfaces + i + j - 1
			face[j] = skinFaces[k] - smesh.indverts + 1
		)
		
		append faceList face
	)
	
	for i = 1 to smesh.nverts do
	(
		local Ind = smesh.indverts + i
		local vertInd = skinIndices[Ind] + 1
		local m2vert = mVerts[vertInd]
		local vpos = m2vert.pos
		local vuv = m2vert.uv
		
		append smesh.m2verts m2vert
		append vertList vpos
		append tvertList vuv
	)
	
	local msh = mesh vertices:vertList faces:faceList name:smName

	if (WOW2_doVertexNormals == true) then
	(
		try
		(
			WOW2_SetVertexNormals msh smesh.m2verts
		)
		catch
		(
			echo ("ERROR# Setting vertex normals failed! " + getCurrentException())
		)
	)
	
	Update msh
	redrawViews()
	
	-- tvert faces
	if vertList.count != 0 then
	(
		-- setup map channels
		meshOp.setMapSupport msh 1 true
		meshOp.defaultMapFaces msh 1 
		
		-- setup uv coords for each channel
		for t = 1 to tvertList.count do
		(
			local tv = tvertList[t]
			
			meshop.setMapVert msh 1 t tv
		)
	)
	Update msh

	smesh.maxMesh = msh
)

fn WOW2_Create_Bones mbones =
(
	step = "Create Bones"
	echo "Creating bones..."
	
	if (WOW2_ImportAsM3 == true) then
	(
		-- create bone to be scaled down
		WOW2_m3bone = Bonesys.createBone [0,0,0] [0,0,0] [0,0,0.1]
		WOW2_m3bone.width = 0
		WOW2_m3bone.height = 0
		WOW2_m3bone.name = mdata.name + "_m3bone_root"	
	)
	
	for i = 1 to mbones.count do
	(
		local b = mbones[i]
		--echo ("Creating bone_" + i as string + ": " + b.name)
		
		local cb = BoneSys.createBone [0,0,0] [0,0,0] [0,0,0.1]
		
		local bname
		if (i / 10 == 0) then
		(
			bname = mdata.name + "_Bone0" + ((i - 1) as string)
		)
		else
		(
			bname = mdata.name + "_Bone" + ((i - 1) as string)
		)
		
		if (b.keyIndex > 0) then bname += "_" + WOW2_keyboneid[b.keyIndex]
		
		cb.name 		= bname
		cb.width 		= 0
		cb.height		= 0
		cb.showLinks	= true
		cb.position		= b.pivot
		cb.rotation.controller = Linear_Rotation()

		cb.boneScaleType = #none
		
		b.maxObj = cb -- assign max bone
		
		-- update original array
		mbones[i] = b
	)
	max views redraw
	
	echo "Setting up bone hierarchy"
	for i=1 to mbones.count do
	(
		b = mbones[i]
		if b.parent!=0 then
		(
			-- echo ("Setting parent of " + i as string + " to " + (bones_read[i].par+1) as string)
			b.maxObj.parent = mbones[b.parent].maxObj
		)
		else if (WOW2_ImportAsM3 == true) then
		(
			b.maxObj.parent = WOW2_m3bone
		)
	)

	max views redraw
)

fn WOW2_Fill_Bones bitStream anims mbones =
(
	for i = 1 to mbones.count do
	(
		local mbone = mbones[i]
		
		WOW2_AnimBlock.Fill bitStream anims mbone.abtrans #v3d
		WOW2_AnimBlock.Fill bitStream anims mbone.abrot #quat
		WOW2_AnimBlock.Fill bitStream anims mbone.abscale #v3d
	)
)

-- Scene data funcs
fn WOW2_SeqsToStringStream seqs =
(
	local ss = stringStream ""
	format ".name:%\n" seqs.name to:ss
	format ".seqInd:%\n" seqs.seqInd to:ss
	format ".cstart:%\n" seqs.cstart to:ss
	format ".cend:%\n" seqs.cend to:ss
	format ".freq:%\n" seqs.freq to:ss
	format ".moveSpeed:%\n" seqs.moveSpeed to:ss
	format ".looping:%\n" seqs.looping to:ss
	return ss
)

fn WOW2_Integer_to_String int buffer =
(
	local strResult = ""
	for i = 1 to buffer do
	(
		strResult += "0"
	)		
	strint = int as string
	if (strint.count < buffer) then
	(
		for i = 1 to strint.count do
		(
			local strInd = i - 1
			strResult[strResult.count-strInd] = strint[strint.count-strInd]
		)
	)
	return strResult
)

fn WOW2_Get_Anims anims =
(
	local m3seqList = #("Stand", "Attack*", "Death", "Run")
	
	for i = 1 to anims.count do
	(
		local anim = anims[i]
		if (dbcdata != undefined) then
		(
			anim.name = (dbcdata.records[anim.animID + 1].name)
			if (WOW2_ImportAsM3 == true) then
			(
				local afound = false
				for j = 1 to m3seqList.count do
				(
					local apatt = m3seqList[j]
					-- if importing as M3, switch on specific animations
					if ((matchPattern anim.name pattern:apatt) == true) then 
					(
						anim.process = true
						afound = true
					)
					else if (afound != true) then 
					(
						anim.process = false
					)
				)
			)
		)
		else
		(
			anim.name = "Animation_" + ((i - 1) as string)
		)
		
		-- update original array
		anims[i] = anim
	)
)

fn WOW2_Set_Anims anims =
(	
	local m3seqList = #()
	local m3seqCounter = #()

	-- Start time
	local astart = 3
	local abuffer = WOW2_Convert_Time 2000
	
	local ad
	if (WOW2_ImportAsM3 == true) then
	(
		-- Initiate Scene Object
		if ($_M3_Anim_Data == undefined) then
		(
			-- Create scene object to house animation information
			ad = point size:0.001 pos:[0,0,0]
			ad.name = "_M3_Anim_Data"
			ad.renderable = off
			ad.isHidden = true
			ad.wirecolor = color 8 8 136
		)
	)
	
	local m3seqssInd = 2
	local animList = #()
	for i = 1 to anims.count do
	(
		local anim = anims[i]
		
		if (anim.process == true) then
		(
			--update old array
			anim.cstart = astart
			anim.cend = astart + anim.frames
			
			astart = anim.cend + abuffer
			
			-- Check for external .anim files in same directory
			-- convert animID to four digit string
			local strAnimID = WOW2_Integer_to_String anim.animID 4
			local strSubID = WOW2_Integer_to_String anim.subanimID 2
			
			local mpath = getFilenamePath filename
			local mfile = getFilenameFile filename
			afile = mpath + mfile + strAnimID + "-" + strSubID + ".anim"
			
			-- find external .anim files, check by three criteria
			if ((doesFileExist afile) == true) then 
			(
				anim.animFile = afile
			)
			else if (dbcdata != undefined) then
			(
				local newanimID = dbcdata.records[anim.animID + 1].parentAnimID
				strAnimID = WOW2_Integer_to_String newanimID 4
				afile = mpath + mfile + strAnimID + "-" + strSubID + ".anim"
				if ((doesFileExist afile) == true) then 
				(
					anim.animFile = afile
				)
				else
				(
					if (anim.index != (i - 1)) then
					(
						local aind = anim.index + 1
						if (anims[aind].animFile != undefined) then anim.animFile = anims[aind].animFile
					)
				)
			)
			
			if (WOW2_ImportAsM3 == true) then
			(
				local m3seq = WOW2_M3SEQS()
				-- asterix eliminates spaces interfering with string matching
				-- fix attack names
				local apatArray = #("Attack", "EmoteDance", "Run", "Walk")
				local aname
				
				-- grab loop switch so we can check if it's on for attack sequence
				m3seq.looping = bit.get anim.flags 6
				
				for a = 1 to apatArray.count do
				(
					local apat = "*" + apatArray[a] + "*"
					if ((matchPattern anim.name pattern:apat) == true) then 
					(
						case apatArray[a] of
						(
							"Attack": 
							(
								-- flip looping switch if attack animation
								aname = "Attack"
								if (m3seq.looping == true) then m3seq.looping = false
							)
							"EmoteDance": 
							(
								aname = "Stand Dance"
								if (m3seq.looping == false) then m3seq.looping = true
							)
							"Run":
							(
								aname = "Walk"
							)
							"Walk":
							(
								aname = "Walk Slow"
							)
						)
					)
				)
				
				if aname == undefined then aname = anim.name
				
				-- Add index numbers to sequences
				local aInd = findItem m3seqList aname
				if (aInd > 0) then
				(
					local counter = m3seqCounter[aInd]
					if (counter / 10 == 0) then 
					(
						aname = aname + " 0" + (counter as string)
					)
					else
					(
						aname = aname + " " + (counter as string)
					)
					
					m3seqCounter[aInd] += 1
				)
				else
				(
					append m3seqList aname
					append m3seqCounter 1
				)
				
				m3seq.name = aname
				m3seq.seqInd = (i - 1)
				m3seq.cstart = anim.cstart
				m3seq.cend = anim.cend
				m3seq.freq = anim.rarity
				m3seq.moveSpeed = anim.moveSpeed
				if (ad != undefined) then
				(
					local m3seqss = WOW2_SeqsToStringStream m3seq
					setAppData ad m3seqssInd m3seqss
					m3seqssInd += 1
				)
			)
			
			anims[i] = anim
			append animList anim
		)
	)
	
	if (ad != undefined) then
	(
		local adss = stringStream ""
		format ".version:%\n" WOW2_sc2vers to:adss
		format ".count:%\n" animList.count to:adss
		setAppData ad 1 adss
	)
	frameRate = WOW2_useFPS
)

fn WOW2_Bone_Depth mbones b =
(
	if b.parent == 0 then return 0
	else return ( 1 + WOW2_Bone_Depth mbones mbones[b.parent] )
)

fn WOW2_Sort_Bones mbones =
(
	local ba = #()
	for i = 1 to mbones.count do
	(
		bonerec = [(WOW2_Bone_Depth mbones mbones[i]), i]
		append ba bonerec
	)
	fn compfn a b = (if a.x<b.x then return 1; if a.x>b.x then return -1; return 0;)
	qsort ba compfn
	return ba
)

fn WOW2_qdot q1 q2 = return ((q1.x*q2.x) + (q1.y*q2.y) + (q1.z*q2.z) + (q1.w*q2.w))

fn WOW2_setNodeWorldRotation theNode theRot = 
( 
	local tmat = transmatrix theNode.transform.pos
	in coordsys tmat (theNode.rotation = theRot)
) 

fn WOW2_Transform_Bone anims mbone ablock flags =
(
	local obj = mbone.maxObj
	local objrot = obj.rotation
	local origPos
	if (flags == #trans) then
	(
		set time 0
		in coordsys parent origPos = copy obj.pos
	)
	
	for i = 1 to ablock.times.count do
	(
		local anim = anims[i]
		
		if anim.process == true then
		(
			local times, keys

			with animate on -- start making keyframes
			(
				times = ablock.times[i]
				keys = ablock.keys[i]
				prevq = quat 1
				
				for t = 1 to times.count do
				(
					local atime = times[t]
					local akey = keys[t]
					local maxFrame = anim.cstart + atime
					
					set time maxFrame -- move to keyframe
					-- animate according to flags
					case flags of
					(
						#trans:
						(
							in coordsys parent obj.pos = origPos + akey
						)
						#rot:
						(
							WOW2_setNodeWorldRotation obj akey
							local newq = copy obj.rotation
							if (WOW2_qdot newq prevq < 0 and t > 1) then obj.rotation = -newq
							prevq = obj.rotation
						)
						#scale:
						(
							obj.scale = akey
						)
					)
				)
			) -- stop making keyframes
		) -- if anim.process == true
	)
)

fn WOW2_Bones_Bindpose mbones origFrame newFrame =
(
	local bd = WOW2_Sort_Bones mbones
	for i=1 to mbones.count do
	(
		local bind = bd[i].y
		local b = mbones[i]
		
		local origTrans
		set time origFrame 
		origTrans = copy b.maxObj.transform
		with animate on
		(
			set time newFrame
			b.maxObj.transform = origTrans
		)
	)
)

fn WOW2_Animate_Bones anims mbones =
(
	local bd = WOW2_Sort_Bones mbones
	
	for i = 1 to mbones.count do
	(
		local bind = bd[i].y
		local mbone = mbones[bind]
		
		-- Rotation
		WOW2_Transform_Bone anims mbone mbone.abrot #rot
		-- Translation
		WOW2_Transform_Bone anims mbone mbone.abtrans #trans
		-- Scale
		WOW2_Transform_Bone anims mbone mbone.abscale #scale
	)
	
	-- setup bindposes between animations
	-- prevents funky interpolations between animations
	for i = 1 to anims.count do
	(
		local anim = anims[i]
		
		if (anim.process == true) then
		(
			local aprev, anext
			aprev = anim.cstart - 1
			anext = anim.cend + 1
			
			local poseFrames = #()
			if (aprev > 0) then append poseFrames aprev
			append poseFrames anext
			
			for j = 1 to poseFrames.count do
			(
				WOW2_Bones_Bindpose mbones 0 poseFrames[j]
			)

			for j = 1 to poseFrames.count do
			(
				WOW2_Bones_Bindpose mbones anim.cstart poseFrames[j]
			)
		)
	)
)

fn WOW2_Create_Attachments mattachs mbones =
(
	local m3attachStr = #("Ref_Center", "Ref_Damage", "Ref_Hardpoint", "Ref_Head", "Ref_Origin", "Ref_Overhead", "Ref_Target", "Ref_Weapon", "Ref_Weapon Left", "Ref_Weapon Right")
	local m3attachid = #(	m3attachStr[3], "Ref_Weapon Right", "Ref_Weapon Left", m3attachStr[3], m3attachStr[3], -- 0 - 4
											m3attachStr[3], m3attachStr[3], m3attachStr[3], m3attachStr[3], m3attachStr[3], -- 5 - 9
											m3attachStr[3], m3attachStr[3], m3attachStr[3], m3attachStr[3], m3attachStr[3], -- 10 - 14
											"Ref_Target", "Ref_Target", m3attachStr[3], "Ref_Head", "Ref_Origin", -- 15 - 19
											"Ref_Overhead"
										)
	
	local m3attCounter = #()
	
	if (WOW2_ImportAsM3 == true) then
	(
		m3attCounter[m3attachStr.count] = 0
		for i = 1 to m3attachStr.count do
		(
			m3attCounter[i] = 0
		)
	)
	
	for i = 1 to mattachs.count do
	(
		local mattach = mattachs[i]
		
		if (WOW2_ImportAsM3 == true and sc2attachment != undefined) then
		(
			local sc2att = sc2attachment pos:mattach.pos name:mattach.name
			local aInd
			
			try 
			(
				if (mattach.id < m3attachid.count) then
				(
					sc2att.attachName = m3attachid[mattach.id]
				)
				else
				(
					sc2att.attachName = "Ref_Hardpoint"
				)
			)
			catch
			(
				sc2att.attachName = "Ref_Hardpoint"
			)
			
			local attInd = findItem m3attachStr sc2att.attachName
			if (attInd > 0) then
			(
				local counter = m3attCounter[attInd]
				if (counter > 0) then
				(
					if (counter / 10 == 0) then 
					(
						sc2att.attachName = sc2att.attachName + " 0" + (counter as string)
					)
					else
					(
						sc2att.attachName = sc2att.attachName + " " + (counter as string)
					)
				)
				
				m3attCounter[attInd] += 1
			)
			
			--sc2att.scale *= 2 -- counterbalanced for future scaledown
			sc2att.parent = mbones[mattach.bone + 1].maxObj
			mattachs[i].maxObj = sc2att
		)
		else
		(
			local m2att = dummy pos:mattach.pos boxsize:[0.15, 0.15, 0.15] name:mattach.name
			m2att.parent = mbones[mattach.bone + 1].maxObj
			mattachs[i].maxObj = m2att
		)
	)
)

fn WOW2_Assign_Map texMap =
(
	local filePath = getFilenamePath filename
	local fName = getFilenameFile texMap
	local extCheck = #(".dds", ".tga", ".png")
	
	for j = 1 to extCheck.count do
	(
		local chkFile = filePath + fName + extCheck[j]
		if ((doesFileExist chkFile) == true) then
		(
			return chkFile
		)
	)
	
	return undefined
)

fn WOW2_Create_Materials =
(
	local texStr = #("Body", "Items", "Type3", "Type4", "Type5", "Hair", "Type7", "Tauren Fur", "Inv1", "Type10", "Skin1", "Skin2", "Skin3", "Inv2")
	
	local texunits = skndata.TexUnits
	local submeshes = skndata.Submeshes
	local textures = mdata.textures
	local texLU = mdata.texLU
	local texUnitLU = mdata.TexUnitsLU
	
	-- Material editor slot counter
	-- quite alot of arrays we got going here!
	local maxMatInd = 1
	local usedTex = #() -- tex units w/ max material
	local usedTexCompare = #() -- tex units w/ zero'd submesh and no max material
	
	for i = 1 to texunits.count do
	(
		local texunit = copy texunits[i]
		
		-- grab the base texture only
		if (TexUnitLU[texunit.TexUnitInd] == 0) then
		(
			local texName
			local texInd = (texLU[texunit.TexInd]) + 1
			local texture = textures[texInd]
			local submesh = submeshes[texunit.SubInd]
			local renderFlags = mdata.renderFlags[texunit.renderFlagsInd]
			
			local texSearch = 0
			for j = 1 to usedTexCompare.count do
			(
				local usedTexunit = usedTexCompare[j]
				if (usedTexunit.texind == texunit.texind) then 
				(
					local usedRenderFlags = mdata.renderFlags[usedTexunit.renderFlagsInd]
					if ((WOW2_CompareStructs usedRenderFlags renderFlags) == true) then texSearch = j
				)
			)
			
			if (texSearch > 0) then
			(
				-- assign pointer with found material
				texunits[i].maxMaterial = usedTex[texSearch].maxMaterial
			)
			else
			(
				if (texture.type == 0) then 
				(
					texName = getFilenameFile texture.texFile
				)
				else
				(
					texName = texStr[texture.type]
				)
				
				local subMaterial
				local count = maxMatInd
				if ((count / 10) == 0) then count = "0" + count as string else count = count as string
				local matName = mdata.name + "Mat_" + count
				
				if (WOW2_ImportAsM3 == true and sc2material != undefined) then
				(
					subMaterial = sc2material name:matName
					
					-- Blendmode
					/*
					M2:
					blend:
					Value    Mapped to       Meaning
					0               0                       Combiners_Opaque
					1               1                       Combiners_Mod
					2               1                       Combiners_Decal
					3               1                       Combiners_Add
					4               1                       Combiners_Mod2x
					5               4                       Combiners_Fade
					
					M3:
					#("Opaque", "Alpha Blend", "Add", "Alpha Add",  "Mod", "Mod 2x")
					*/
					local bmode
					case renderFlags.blendmode of
					(
						0: bmode = 1
						1: bmode = 1
						2: bmode = 1
						3: bmode = 3
						4: bmode = 1
						5: bmode = 1
						default: bmode = 1
					)
					subMaterial.blendmode = bmode
					
					-- Render Flags
					subMaterial.unshaded = bit.get renderFlags.flags 1
					subMaterial.unfogged = bit.get renderFlags.flags 2
					subMaterial.TwoSided = bit.get renderFlags.flags 3
					subMaterial.DepthPrepass = bit.get renderFlags.flags 4
					
					local m3diffuseMap = sc2bitmap name:texName
					
					-- check if tga or dds matching file found in directory of model
					if (texture.type == 0) then
					(
						local bitmapChk = WOW2_Assign_Map texName
						if (bitmapChk != undefined) then
						(
							try (m3diffusemap.scbitmap = openBitmap bitmapChk) catch ()
						)
					)
					
					subMaterial.diffuseMap = m3diffuseMap
						
					if (renderFlags.blendmode == 1) then
					(
						local m3alphaMap = sc2bitmap name:texName
						m3alphaMap.TexAlphaOnly = true
						if (m3diffuseMap.scbitmap != undefined) then m3alphaMap.scbitmap = m3diffuseMap.scbitmap
						
						subMaterial.alphaMaskMap = m3alphaMap
						subMaterial.cutoutThresh = 200
					)
				)
				else
				(
					subMaterial = Standard name:matName
					
					subMaterial.TwoSided = bit.get renderFlags.flags 3
					
					local m2diffuseMap = BitmapTexture name:texName
					if (texture.type == 0) then
					(
						local bitmapChk = WOW2_Assign_Map texName
						if (bitmapChk != undefined) then
						(
							try (m2diffuseMap.bitmap = openBitmap bitmapChk) catch ()
						)
					)
					
					subMaterial.diffuseMap = m2diffuseMap
					
					if (renderFlags.blendmode == 1) then
					(
						local m2alphaMap = BitmapTexture name:texName
						m2alphaMap.monoOutput = 1
						if (m2diffuseMap.bitmap != undefined) then m2alphaMap.bitmap = m2diffuseMap.bitmap
						
						subMaterial.opacityMap = m2alphaMap
					)
				)
				
				showTextureMap subMaterial subMaterial.diffuseMap on
					
				-- Put material in material editor slot
				setMeditMaterial maxMatInd subMaterial
				-- Move slot index ahead one for future materials
				maxMatInd += 1
				
				append usedTexCompare texunit
				
				-- Assign max material pointer
				texunits[i].maxMaterial = subMaterial
				append usedTex texunits[i]
			)

			if (submesh.process == true and submesh.maxMesh != undefined) then
			(
				submesh.maxMesh.material = texunits[i].maxMaterial
			)
		)
	)
)

fn WOW2_Create_Mesh =
(
	step = "Create Mesh"

	echo "Creating submeshes..."
	local submeshes = skndata.submeshes
	
	cmesh = #()
	for s = 1 to submeshes.count do
	(
		local smesh = submeshes[s]
		
		if (smesh.process == true) then
		(
			local smtype = smesh.id / 100
			if (smtype == 0) then
			(
				if ((mod smtype 100) > 0) then smtype = 21 else smtype = 1
			)
			else
			(
				smtype += 1
			)
			local smname = (mdata.name + ((s - 1) as string) + "_" + smesh.name)
			format "Creating submesh %..." smname to:listener
			WOW2_Create_Submesh smesh skndata.Indices skndata.faces mdata.verts smname
			echo ("done!")
		)
	)

	step = "Create Mesh Done"
	echo "Submeshes done\n"
)

fn WOW2_Apply_Skin mesh mbones skinBones verts =
(
	max modify mode
	
	-- #Skin
	sk = Skin name:"Skin"
	addModifier mesh sk
	modPanel.setCurrentObject sk

	-- add bones to skin
	for i = 1 to skinBones.count do
	(
		skinOps.addBone sk skinBones[i].maxObj 0
	)
	
	update mesh
	max views redraw

	disableSceneRedraw() -- speeds up weight assignment
	try
	(
		-- 4. Set vertex weights
		for i = 1 to verts.count do
		(
			local vert = verts[i]
			
			-- Fix weight bone reference to locally skinned bones index
			for w = 1 to vert.bw.count do
			(
				if (vert.bw[w] > 0.0) then
				(
					local vBone = vert.bi[w]
					local bIndex = findItem skinBones mbones[vBone]
					if (bIndex > 0) then vert.bi[w] = bIndex else vert.bi[w] = 0
				)
			)
			skinOps.ReplaceVertexWeights sk i vert.bi vert.bw
		)
	)
	Catch
	(
		echo "#ERROR Vertex Weighting failed"
	)
	enableSceneRedraw()

	update mesh
	redrawViews()
)

fn WOW2_Create_Skin submeshes mbones mbonesLU =
(
	echo "Creating skin..."
	for i = 1 to submeshes.count do
	(
		local smesh = submeshes[i]
		
		if (smesh.process == true) then
		(
			-- Gather skinned bones
			local boneList = #()
			for i = 1 to smesh.nbones do
			(
				local bListInd = smesh.indbones + i
				local bInd = mbonesLU[bListInd] + 1
				local sbone = mbones[bInd]
				append boneList sbone
			)
			
			WOW2_Apply_Skin smesh.maxMesh mbones boneList smesh.m2verts
		)
	)
)

-- ****************************************
-- **				Main Code			    		**
-- ****************************************
--

fn WOW2_PreStart =
(
	if (WOW2_ImportAsM3 == true and SC2PLUGIN_VERS == undefined) then
	(
		throw ("Starcraft 2 Object definition file not found\nMake sure sc2_objects.ms is loaded before trying to import as M3")
	)
	
	mdata = WOW2_Header.Read mstream
	if (mdata.fileID != "MD20") then throw ("Invalid model file!")
	if (mdata.version < 263) then throw ("Old model format detected. 3.* models and above supported only")
	skndata = WOW2_SkinHeader.Read sknstream
	if (skndata.fileID != "SKIN") then throw ("Invalid SKIN file!")
	-- check that model and skin vert counts are the same
	if (mdata.verts.nEntry != skndata.indices.nEntry) then 
	(
		echo ("#WARNING Indices in SKIN file do not match model vertices!")
		--throw ("Invalid SKIN file!")
	)
	WOW2_SkinHeader.Fill sknstream skndata

	mdata.name = WOW2_ReadData mstream mdata.name #string
	mdata.anims = WOW2_Animation.Read mstream mdata.anims
	WOW2_Get_Anims mdata.anims
	
	mdata.verts = WOW2_Vertex.Read mstream mdata.verts
	m2bones = WOW2_Bone.Read mstream mdata.bones
	mdata.bonesLU = WOW2_ReadData mstream mdata.bonesLU #uint16
	
	-- Materials
	mdata.Textures = WOW2_Texture.Read mstream mdata.Textures
	mdata.RenderFlags = WOW2_RenderFlags.Read mstream mdata.RenderFlags
	
	-- Texture lookups
	mdata.TexLU = WOW2_ReadData mstream mdata.TexLU #uint16
	mdata.TexUnitsLU = WOW2_ReadData mstream mdata.TexUnitsLU #int16
	
	mdata.Attachs = WOW2_Attachment.Read mstream mdata.attachs
)

fn WOW2_ScriptTime start end =
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

fn WOW2_Start =
(
	local scrStart = TimeStamp()
	
	echo ("Model Name: "+mdata.name)
	WOW2_Create_Bones m2bones
	
	try
	(
		echo ("Setting up animation data...")
		WOW2_Set_Anims mdata.anims
		echo ("Getting bone animation data...")
		WOW2_Fill_Bones mstream mdata.anims m2bones 
		echo ("Animating bones...")
		WOW2_Animate_Bones mdata.anims m2bones
	)
	catch
	(
		echo "#ERROR Animating bones failed!"
	)
	
	WOW2_Create_Mesh()
	
	try 
	(
		WOW2_Create_Materials()
	)
	catch
	(
		echo "#ERROR Creating materials failed!"
	)
	
	try
	(
		echo ("Creating attachment helpers...")
		WOW2_Create_Attachments mdata.Attachs m2bones
	)
	catch
	(
		echo "#ERROR Creating attachments failed!"
	)
	
	try
	(
		echo ("Creating submesh skins...")
		WOW2_Create_Skin skndata.submeshes m2bones mdata.bonesLU
	)
	catch
	(
		echo "#ERROR Creating submesh skins failed!"
	)
	
	-- fix up model rotation and scale if importing as M3
	if (WOW2_ImportAsM3 == true) then
	(
		rotate WOW2_m3bone (eulerangles 0 0 -90)
		WOW2_m3bone.scale *= WOW2_M3Scale
	)

	local scrEnd = TimeStamp()
	local scrTime = WOW2_ScriptTime scrStart scrEnd
	format "Import took %\n" scrTime
	messageBox ("Import successful\nImport took "+scrTime)
	
	max select all
	
	-- Only once doesn't do a proper zoom
	for i = 1 to 3 do
	(
		max zoomext sel all
	)
	
	max views redraw
	ClearSelection()
	
	format "======== Done ========\n" to:listener
)

-- Import
fn WOW2_PreMain =
(	
	WOW2_Reset_Globals()
	if (dbcFile != undefined) then
	(
		if ((doesFileExist dbcFile) == true) then dbcdata = WOW2_DBC_AnimDBC dbcFile
	)
	mstream = WOW2_Open filename
	sknstream = WOW2_Open sknFile
	WOW2_PreStart()
	WOW2_Close bstream
)

fn WOW2_Main =
(	
	WOW2_Reset_Globals()
	dbcdata = WOW2_DBC_AnimDBC dbcFile
	mstream = WOW2_Open filename
	sknstream = WOW2_Open sknFile
	WOW2_Start()
	WOW2_Close bstream
)

-- ************************************
-- **		User Interface Code			**
-- ************************************
--

-- Glob UI Funcs
fn uiOpenFile ftypes &fname =
(
	local ret = getOpenFileName types:ftypes filename:fname
	if ret != undefined then fname = ret
)

fn sortSpreadsheet data dataField type =
(
	fn sortStrings s1 s2 =
	(
		local ups1 = WOW2_toUpper s1[1]
		local ups2 = WOW2_toUpper s2[1]
		
		case of
		(
			(ups1 < ups2): return -1
			(ups1 > ups2): return 1
			default: return 0
		)
	)
	
	fn sortValues v1 v2 =
	(
		case of
		(
			(v1[1] < v2[1]): return -1
			(v1[1] > v2[1]): return 1
			default: return 0
		)
	)
	
	local dataOrder = #()
	dataOrder[data.count] = 0
	for i = 1 to data.count do
	(
		dataOrder[i] = data[i].order
	)
	
	local newOrder = #()
	newOrder[data.count] = 0
	for i = 1 to data.count do
	(
		local val
		case dataField of
		(
			#name: val = data[i].name
			#uiIndex: val = data[i].uiIndex
			#verts: val = data[i].nverts
			#faces: val = data[i].nfaces
			#bones: val = data[i].nbones
			#frames: val = data[i].frames
			#rarity: val = data[i].rarity
			#moveSpeed: val = data[i].moveSpeed
		)
		newOrder[i] = #(val, dataOrder[i])
	)
	
	case type of
	(
		#string: qsort newOrder sortStrings
		#value: qsort newOrder sortValues
	)
	
	for i = 1 to newOrder.count do
	(
		local dind = findItem dataOrder newOrder[i][2]
		data[dind].order = i
	)
)

rollout WOW2_Dialog_Settings "M2 Model Import Settings" width:400 height:350
(
	group "Paths"
	(
		label			lSettDBCPath "DBFilesClient Path: " align:#left
		edittext	tDBCPath width:360 text:WOW2_DBCPath align:#left
		button		bDBCPath "Browse..." tooltip:"Locate your DBC files path" align:#center
	)
	
	group "Settings"
	(
		checkbox chkImportAsM3 "Import as M3" checked:(WOW2_ImportAsM3) align:#left across:2
		spinner spnM3Scale "M3 Scale:" range:[0,1e8,WOW2_M3Scale] align:#right width:75
		checkbox chkFlipUV_Y "Flip UV Y-Coord" checked:(WOW2_flipuv_y) align:#left across:2
		spinner spnUseFPS "FPS:" range:[0,1e8,WOW2_UseFPS] type:#integer align:#right width:75
		checkbox chkVertexNormals "Import Vertex Normals" checked:(WOW2_doVertexNormals) align:#left
	)
	
	label		lblSettINIFile "Config File Location (Saves M2 Import settings): " align:#center offset:[0,20]
	edittext	tINIFile align:#center text:(m2impini) readOnly:true width:360
	label		lblINIFileStatus "" align:#center
	
	button bSettSave "Save" align:#center height:30 width:70 tooltip:"Save your settings" across:2 offset:[40,10]
	button bSettCancel "Cancel" align:#center height:30 width:70 tooltip:"Close the settings options without saving" offset:[-40,10]
	
	-- Option Functions
	fn CheckSett inifile = 
	(
		if (doesFileExist inifile) then
		(
			lblINIFileStatus.text = ""
		)
		else
		(
			lblINIFileStatus.text = "Settings file not found! Please save a new one"
		)
	)
	
	on WOW2_Dialog_Settings open do
	(
		CheckSett tINIFile.text
		if (chkImportAsM3.checked == true) then
		(
			spnM3Scale.enabled = true
		)
		else
		(
			spnM3Scale.enabled = false
		)
	)
	on chkImportAsM3 changed val do
	(
		if (val == true) then
		(
			spnM3Scale.enabled = true
		)
		else
		(
			spnM3Scale.enabled = false
		)
	)
	on bDBCPath pressed do
	(
		local ret = getSavePath initialDir:WOW2_DBCPath
		if ret != undefined then 
		(
			if (ret[ret.count] != "\\") then ret += "\\"
			tDBCPath.text = ret
		)
	)
	on bSettSave pressed do
	(
		local saveGo = true
		local strDBCPath = tDBCPath.text
		if (strDBCPath[strDBCPath.count] != "\\") then strDBCPath += "\\"
		
		local strQuery
		
		if ((matchPattern strDBCPath pattern:"*:\\*") == true) then 
		(
			local adfile = strDBCPath + AnimDataDBC
			if ((doesFileExist adfile) == false) then
			(
				local strQuery = AnimDataDBC + " not found in " + strDBCPath + "\nAnimations won't be named. Continue?"
				saveGo = queryBox strQuery title:(AnimDataDBC + " error")
			)
		)
		else
		(
			local strQuery = "An invalid DBC path has been supplied. \nDBC files won't be loaded. Continue?"
			saveGo = queryBox strQuery title:"DBC path error"
		)
		
		if (saveGo == true) then
		(
			-- assign to Globals
			-- Options
			
			-- Paths
			WOW2_DBCPath				= tDBCPath.text
			WOW2_ImportAsM3			= chkImportAsM3.checked
			WOW2_flipuv_y				= chkFlipUV_Y.checked
			WOW2_UseFPS				= spnUseFPS.value
			WOW2_doVertexNormals	= chkVertexNormals.checked
			WOW2_M3Scale				= spnM3Scale.value
			
			--Write Settings to INIFile
			WriteINI tINIFile.text
			
			DestroyDialog WOW2_Dialog_Settings
		)
	)
	on bSettCancel pressed do
	(
		DestroyDialog WOW2_Dialog_Settings
	)
)

rollout WOW2_AnimUI "M2 Animation" width:480 height:500
(
	fn initListView lv =
	(
		lv.gridLines = true  
		lv.View = (dotNetClass "System.Windows.Forms.View").Details
		lv.fullRowSelect = true 
		lv.Sorting = (dotNetClass "System.Windows.Forms.SortOrder").None
		lv.Checkboxes = true

		layout_def = #(#("Import", 50), #("Animation", 120), #("Frames", 60), #("Rarity", 60), #("Move Speed", 80))

		for i in layout_def do
		(
			lv.Columns.add i[1] i[2] --add column with name and optional width
		)
	)

	fn fillInSpreadSheet lv anims =
	(
		local animOrder = #()
		animOrder[anims.count] = 0
		for i = 1 to anims.count do
		(
			animOrder[i] = anims[i].order
		)
		
		lv.Items.Clear()
		theRange = #() -- array to collect the list items
		
		for i = 1 to anims.count do
		(
			local aind = findItem animOrder i
			local anim = anims[aind]
			
			li = dotNetObject "System.Windows.Forms.ListViewItem" (anim.uiIndex as string)
			li.checked = anim.process
			
			sub_li = li.SubItems.add anim.name
			sub_li = li.SubItems.add (anim.frames as string)
			sub_li = li.SubItems.add (anim.rarity as string)
			sub_li = li.SubItems.add (anim.moveSpeed as string)
			
			append theRange li
		)
		
		lv.Items.AddRange theRange -- when done, we populate the ListView
	)
	
	fn checkAllSpreadSheet lv bool =
	(
		for i = 0 to (lv.Items.count - 1) do
		(
			lv.Items.Item[i].checked = bool
		)
	)
	
	fn checkSelected lv bool =
	(
		for i = 0 to (lv.Items.count - 1) do
		(
			local listItem = lv.Items.Item[i]
			if (listItem.selected == true) then
			(
				lv.Items.Item[i].checked = bool
			)
		)
	)
	
	fn SaveAnim lv animdata =
	(
		for i = 0 to (lv.Items.count - 1) do
		(
			local listItem = lv.Items.Item[i]
			local aind = (listItem.text as integer) + 1
			animdata[aind].process = listItem.checked
		)
	)

	-- activeXControl lvAnimation "MSComctlLib.ListViewCtrl" width:430 height:380 align:#center
	dotNetControl lvAnimation "System.Windows.Forms.ListView" width:430 height:380 align:#center
	local selNums = #(), checkStates = #()
	
	button btnCheckAll "Check All" across:4 align:#left
	button btnCheckNone "Uncheck All" align:#left
	button btnCheckSelected "Check Selected" align:#left
	button btnUncheckSelected "Uncheck Selected" align:#left
	
	on WOW2_AnimUI open do 
	(
		-- List view init
		initListView lvAnimation
		
		if (dbcdata != undefined) then
		(
			sortSpreadsheet mdata.anims #name #string
		)
		else
		(
			sortSpreadsheet mdata.anims #uiIndex #value
		)
		
		fillInSpreadSheet lvAnimation mdata.anims
	)
	on WOW2_AnimUI close do
	(
		-- save into animations
		SaveAnim lvAnimation mdata.anims
	)
	-- code borrowed from Jon-Huhn of CGTalk, fixes a bug with the dotnet listview control
	on lvAnimation MouseUp e do 
	(
		for x = 1 to selNums.count do lvAnimation.items.item[selNums[x]].checked=checkStates[x] -- correct the checkboxes
		selNums=#(); checkStates=#() -- clear the record
	)
	on lvAnimation ItemSelectionChanged e do 
	(
		-- record the states of the checkboxes so we can correct them at MouseUp	
		selNums=for x=0 to lvAnimation.selectedIndices.count-1 collect lvAnimation.selectedIndices.item[x]
		checkStates=for x=1 to selNums.count collect lvAnimation.items.item[selNums[x]].checked	
	)
	on lvAnimation ColumnClick arg val do
	(
		SaveAnim lvAnimation mdata.anims
		case (val.column as integer) of
		(
			0: sortSpreadsheet mdata.anims #uiIndex #value
			1: sortSpreadsheet mdata.anims #name #string
			2: sortSpreadsheet mdata.anims #frames #value
			3: sortSpreadsheet mdata.anims #rarity #value
			4: sortSpreadsheet mdata.anims #moveSpeed #value
		)
		
		-- update list
		fillInSpreadSheet lvAnimation mdata.anims
	)
	on btnCheckAll pressed do
	(
		checkAllSpreadSheet lvAnimation true
	)
	on btnCheckNone pressed do
	(
		checkAllSpreadSheet lvAnimation false
	)
	on btnCheckSelected pressed do
	(
		checkSelected lvAnimation true
	)
	on btnUncheckSelected pressed do
	(
		checkSelected lvAnimation false
	)
)

rollout WOW2_GeoUI "M2 Geometry" width:480 height:500
(
	fn initListView lv =
	(
		lv.gridLines = true  
		lv.View = (dotNetClass "System.Windows.Forms.View").Details
		lv.fullRowSelect = true 
		lv.Sorting = (dotNetClass "System.Windows.Forms.SortOrder").None
		lv.Checkboxes = true

		layout_def = #(#("Import", 50), #("Submesh Type", 110), #("Verts", 60), #("Faces", 60), #("Skinned Bones", 90))

		for i in layout_def do
		(
			lv.Columns.add i[1] i[2] --add column with name and optional width
		)
	)

	fn fillInSpreadSheet lv submeshes =
	(
		local smOrder = #()
		smOrder[submeshes.count] = 0
		for i = 1 to submeshes.count do
		(
			smOrder[i] = submeshes[i].order
		)
		
		lv.Items.Clear()
		theRange = #() -- array to collect the list items
		for i = 1 to submeshes.count do
		(
			local smind = findItem smOrder i
			local submesh = submeshes[smind]
			li = dotNetObject "System.Windows.Forms.ListViewItem" (submesh.uiIndex as string)
			li.checked = submesh.process
			
			sub_li = li.SubItems.add submesh.name
			sub_li = li.SubItems.add (submesh.nverts as string)
			sub_li = li.SubItems.add (submesh.nfaces as string)
			sub_li = li.SubItems.add (submesh.nbones as string)
			
			append theRange li -- we add the list item to the array
		)

		lv.Items.AddRange theRange -- when done, we populate the ListView
	)
	
	fn checkAllSpreadSheet lv bool =
	(
		for i = 0 to (lv.Items.count - 1) do
		(
			lv.Items.Item[i].checked = bool
		)
	)
	
	fn checkSelected lv bool =
	(
		for i = 0 to (lv.Items.count - 1) do
		(
			local listItem = lv.Items.Item[i]
			if (listItem.selected == true) then
			(
				lv.Items.Item[i].checked = bool
			)
		)
	)
	
	fn SaveGeo lv smdata =
	(
		for i = 0 to (lv.Items.count - 1) do
		(
			local listItem = lv.Items.Item[i]
			local smind = (listItem.text as integer) + 1
			smdata[smind].process = listItem.checked
		)
	)
	
	--activeXControl lvGeometry "MSComctlLib.ListViewCtrl" width:430 height:380 align:#center
	dotNetControl lvGeometry "System.Windows.Forms.ListView" width:430 height:380 align:#center
	local selNums = #(), checkStates = #()
	
	button btnCheckAll "Check All" across:4 align:#left
	button btnCheckNone "Uncheck All" align:#left
	button btnCheckSelected "Check Selected" align:#left
	button btnUncheckSelected "Uncheck Selected" align:#left
	
	on WOW2_GeoUI open do 
	(
		-- List view init
		initListView lvGeometry
		fillInSpreadSheet lvGeometry skndata.submeshes
	)
	on WOW2_GeoUI close do
	(
		-- save into geometry
		SaveGeo lvGeometry skndata.submeshes
	)
	-- code borrowed from Jon-Huhn of CGTalk, fixes a bug with the dotnet listview control
	on lvGeometry MouseUp e do 
	(
		for x = 1 to selNums.count do lvGeometry.items.item[selNums[x]].checked=checkStates[x] -- correct the checkboxes
		selNums=#(); checkStates=#() -- clear the record
	)
	on lvGeometry ItemSelectionChanged e do 
	(
		-- record the states of the checkboxes so we can correct them at MouseUp	
		selNums=for x=0 to lvGeometry.selectedIndices.count-1 collect lvGeometry.selectedIndices.item[x]
		checkStates=for x=1 to selNums.count collect lvGeometry.items.item[selNums[x]].checked	
	)
	on lvGeometry ColumnClick arg val do
	(
		SaveGeo lvGeometry skndata.submeshes
		case (val.column as integer) of
		(
			0: sortSpreadsheet skndata.submeshes #uiIndex #value
			1: sortSpreadsheet skndata.submeshes #name #string
			2: sortSpreadsheet skndata.submeshes #verts #value
			3: sortSpreadsheet skndata.submeshes #faces #value
			4: sortSpreadsheet skndata.submeshes #bones #value
		)
		
		-- update spreadsheet
		fillInSpreadSheet lvGeometry skndata.submeshes
	)
	on btnCheckAll pressed do
	(
		checkAllSpreadSheet lvGeometry true
	)
	on btnCheckNone pressed do
	(
		checkAllSpreadSheet lvGeometry false
	)
	on btnCheckSelected pressed do
	(
		checkSelected lvGeometry true
	)
	on btnUncheckSelected pressed do
	(
		checkSelected lvGeometry false
	)
)

rollout WOW2_ModelUI "M2 Model Overview" width:500 height:550
(	
	-- activeXControl tbsMain "MSComctlLib.TabStrip.2" height:20 align:#left visible:true
	dotNetControl tabMain "System.Windows.Forms.TabControl" height:20 width:200 align:#left
	Subrollout subWindow width:450 height:450 align:#center
	button btnImport "Import" align:#center height:35 width:75 across:2 offset:[45,10]
	button btnCancel "Cancel" align:#center height:35 width:75 offset:[-45,10]
	
	fn initTabs tab labels:#() =
	(
		--Clear any existing tabs incase we do an update of them at some point. 
		tab.tabPages.clear()
		--Set the size mode so that we can control their width. 
		tab.sizeMode=tab.sizeMode.fixed
		--Set the width of every tab.
		tab.itemSize=dotnetObject "System.Drawing.Size" ((tab.width/labels.count)-2) 25
		
		--Loop through all the labels that we pass to the function and add a tab by the same name. 
 		for x in labels do tab.tabPages.add x
	)
	
	fn addTabRollout subRoll index =
	(
		--Remove any existing rollouts first. 
 		for x in subRoll.rollouts do removeSubRollout subRoll x
		
		case index of
		(
			0:
			(
				addSubRollout subRoll WOW2_GeoUI
			)
			1:
			(
				addSubRollout subRoll WOW2_AnimUI
			)
		)
	)
	
	on WOW2_ModelUI open do 
	(
		-- Tab init
		initTabs tabMain labels:#("Geometry", "Animation")
		
		-- Geometry view init
		addSubRollout subWindow WOW2_GeoUI
	)
	on WOW2_ModelUI close do
	(
		removeSubRollout subWindow subWindow.rollouts[1]
		WOW2_Reset_Globals()
		try (destroyDialog WOW2_Dialog) catch()
	)
	on tabMain MouseUp senderArg arg do
	(
		addTabRollout subWindow senderArg.SelectedIndex
	)
	on btnImport pressed do
	(
		subWindow.rollouts[1].close()
		WOW2_Start()
		try (destroyDialog WOW2_ModelUI) catch()
	)
	on btnCancel pressed do
	(
		destroyDialog WOW2_ModelUI
	)
)

rollout WOW2_Dialog "M2 Model Import" width:400 height:300
(
	group "Model and Skin"
	(
		edittext 	tFileName "Model Filename:" labelOnTop:true
		button		bOpenFile "Browse..." tooltip:"Locate a M2 file" align:#center offset:[0,10]
		edittext 	tSkinFileName "Skin Filename:" labelOnTop:true
		button		bSkinOpenFile "Browse..." tooltip:"Locate a Skin file" align:#center offset:[0,10]
	)

	button		bSettings "Paths/Settings..." width:120 height:25 tooltip:"Configure your M2 Importer settings" offset:[0,15]

	button bOK "Open" across:2 tooltip:"Open an M2" height:35 width:75 offset:[0,20]
	button bCancel "Cancel" tooltip:"Close M2 Importer" height:35 width:75 offset:[0,20]
	
	on WOW2_Dialog close do
	(
		try
		(
			DestroyDialog WOW2_Dialog
			DestroyDialog WOW2_Dialog_Settings
			DestroyDialog WOW2_ModelUI
		)
		catch()
	)
	on bOpenFile pressed do
	(
		uiOpenFile "M2 model (*.m2)|*.m2|All Files|*.*|" &tFileName.text
	)
	on bSkinOpenFile pressed do
	(
		uiOpenFile "Skin file (*.skin)|*.skin|All Files|*.*|" &tSkinFileName.text
	)
	on bOK pressed do
	(
		if (tFileName.text == "" or tFileName.text == undefined) then
		(
			Messagebox "Please open a valid M2 file"
		)
		else if (tSkinFileName.text == "" or tSkinFileName.text == undefined) then
		(
			Messagebox "Please open a valid SKIN file"
		)
		else
		(
			try
			(
				local dbcCheck = WOW2_DBCPath + AnimDataDBC
				if ((doesFileExist dbcCheck) == true) then dbcFile = dbcCheck
				filename = tFileName.text
				sknFile = tSkinFileName.text
				--DestroyDialog WOW2_Dialog
				--WOW2_Main()
				WOW2_PreMain()
				createDialog WOW2_ModelUI
			)
			catch
			(
				echo ("****"+getCurrentException()+"****")
				echo "====== Import Failed ======\n"
				messageBox ("Import failed!\n"+getCurrentException()) title:"Import failed"
				DestroyDialog WOW2_Dialog
			)
		)
	)
	on bCancel pressed do
	(
		DestroyDialog WOW2_Dialog
	)
	on bSettings pressed do
	(
		CreateDialog WOW2_Dialog_Settings
	)
)
	
fn WOW2_UI_Main =
(
	if WOW2_Dialog != undefined do
	(
		try (closerolloutfloater WOW2_Dialog) catch()
	)		

	CreateDialog WOW2_Dialog style:#(#style_titlebar, #style_border, #style_sysmenu, #style_minimizebox)
	WOW2_Dialog.placement = #normal
)

utility m2impexp "WoW M2 Import/Export"
(
	button 	bImport "Import" height:30 width:75
	--button 	bExport "Export" height:30 width:75
	button	btnAbout "About" height:20
		
	on bImport pressed do
	(
		WOW2_UI_Main()
	)
	on bExport pressed do
	(
		MessageBox "No longer supported"
		--M2E_Main()
	)
	on btnAbout pressed do
	(
		messagebox "M2 Importer v0.304 - 25-07-2010\n\xa9 2010, NiNtoxicated (madyavic@gmail.com)\nVisit www.sc2mapster.com for updates and more information\nHead to the forum for support. Feedback is appreciated!" title:"About"
	)
)