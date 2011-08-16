------------------------------------------------------------------------------------------------
-- Starcraft 2 Model (M3->3ds) Importer version 0.31
-- by NiNtoxicated (madyavic@gmail.com)
-- Imports M3 models into 3ds max via maxscript
-- Created for 3ds max 2010, but should be backwards compatible
-- Based on reworked code from my World of Warcraft M2 importer
--
-- Big thanks to: 
-- Blue Isle Studios (http://blueislestudios.com/) - Big thanks to the support provided by these guys. Check them out!
-- Teal (starcraft.incgamers.com) - PHP M3 parser
-- Volcore (http://volcore.limbicsoft.com/)  - Helped figure out vertex flags
-- Witchsong (http://code.google.com/p/libm3/) - Awesome M3 library and for help on sequence data
-- der_Ton (http://www.doom3world.org/) - Great work on MD5 format which is similar to M3
-- MrMoonKr - Providing a toUpper function to fix 3ds max incompatibility issues
-- Skizot - For testing and providing suggestions to improve the script, very big thanks
-- Phygit - Providing bug fixes and script development information to do with the M3 format
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
-- 3. Automate MPQ extraction
-- 4. Add good animation support
--
------------------------------------------------------------------------------------------------
--
-- Version History:
-- 0.31 - March 5th 2011
-- Added particle emitter support
-- Added custom bounding sphere support
-- Attachment wireframe improved to reflect orientation
-- Attachment volumes now imported
-- Animated bitmap settings now imported
-- UI improvements, added additional options
-- Miscellaneous code and bug fixes
-- Lots of code restructuring
--
-- 0.30 - August 15th 2010
-- No longer crashes on certain models
--
-- 0.29 - August 5th 2010
-- Corrected animation bug
--
-- 0.28b - 24th July 2010
-- Improved the way process time is output
-- Removed conflicting function with the m2 importer
-- Added sc2_objects.ms error catching
--
-- 0.28 - July 15th 2010
-- Rotations now use linear rotation controllers
-- Gimbal lock no longer affects animations
-- Added custom map support
-- Additional bitmap settings now supported
-- Improved zoom to model after import
--
-- 0.27 - June 28th 2010
-- Added decal support
-- Added terrain (null) material type support
-- Submeshes now import as multiple meshes
-- Meshes now skinned with just the bones that affect its vertices
-- Attachments now import as Starcraft 2 attachment objects
-- Attachments replace the bone they are attached to on import
--
-- 0.26 - June 14th 2010
-- Animations now import correctly for most models
-- Fixed attachments sometimes not binding to their bones properly
-- Added some basic message boxes for key events
--
-- 0.25 - June 9th 2010
-- Imports additional M3 animation data
-- Attachments now imported as dummy boxes
-- Animations now import faster
-- Small code fixes
--
-- 0.24 - May 28th 2010
-- Improved bindpose handling, now includes baseframe
-- Various code fixes
--
-- 0.22 - May 17th 2010
-- Added attachment support
-- Added sc2objects support, can now use custom materials/maps
-- Incompatibility error with old 3ds max versions fixed (thanks to MrMoonKr)
--
-- 0,21 - May 7th 2010
-- Fixed wrong textures being applied to some models
-- Fixed missing materials dialog duplicate error
-- Added reflection map support
-- Added code to deal with vertex flags
-- Added vertex normals UI option
-- Specular level now being set from material data
--
-- 0.20 - April 30th 2010
-- Added bindpose buffers for each animation, helps prevent weird translation across animations
-- Vertex normals now manually set properly (at the expense of processing time :( )
-- Code syntax improvements
--
-- 0.18 - April 25th 2010
-- Added support for new MD34 model format
-- Bones now animate correctly
--
-- 0.14 - April 10th 2010
-- Aligned all submeshes to their appropriate bones 
-- Skinned vertex positioning now based on all weighted bones (thanks to MD5 documentation)
-- Improved animation processing times (bones animated before vertex skinning)
--
-- 0.13 - April 1st 2010
-- Mesh now binds to bones properly for most models.
--
-- 0.11 - March 30th 2010
-- Updated Sequence support
-- Added Sequence UI for navigating sequences
-- Shift to more object orientated coding
--
-- 0.098 - March 26th 2010
-- Added queryBox error for missing textures before creating any scene objects
-- Updated some of the code regarding sequence data
-- Minor code improvements
--
-- 0.096 - March 22nd 2010
-- Fixed bump mapping (sets to 100 now)
-- 
-- 0.095 - March 21st 2010
-- Some basic error catching added
-- Fixed initial bone errors
--
-- 0.09 - March 20th 2010
-- Added primitive animation support
-- Code housekeeping
-- Updated code, improved processing time
--
-- 0.06 - March 13th 2010
-- Added rollout menu
--
-- 0.05 - March 11th 2010
-- Added bone support, however mesh not binding to bones properly yet
--
-- 0.04 - March 6th 2010
-- Major overhaul of code
-- Reworked tag reading and reference reading, can now read nested structures
-- Vastly improved material reading
--
-- 0.03 - March 4th 2010
-- Vertice normals added 
-- Added material importing
--
-- 0.02 - February 29th 2010 - March 2nd 2010
-- Made significant improvements to structures and accessing file data
-- Can now (hopefully) import UV data
-- Added submesh functionality
--
-- 0.01 - February 26th 2010
-- Initial version of M3 import script
--
------------------------------------------------------------------------------------------------

-- ********************
--  SCRIPT DECLARES
-- ********************
-- globals
global head, cmat, mread, aread, mbones, mparts, bstream, cbones
global scrStart, scrEnd -- For script timeStamps
global tread		= #()
global cmesh		= #()

-- Switches
global M3I_flipuv_y 			= true -- Flips uv.y coords
global scrExit					= false -- Indicates premature script exit

-- UI switches
global doCreateBndSphere = true
global doCreateBones 		= true -- #warning: can slow import
global doTransformBones 	= true
global doCreateSkin 		= true
global doCreateMesh 		= true
global doCreateMats		= true
global doVertexNormals	= true -- #warning: slows import
global doCreateAttachments = true
global doCreatePemits = true
global doAnimateObjects = true

-- Misc. variables
global M3I_sc2vers = 0.06
global M3I_useFPS 	= 30

--Function declaration
fn ReadTagData tagInd flags = ()
fn M3I_GetAnimData animRef mdata adata = ()
fn M3I_AnimUI = ()

-- *******************
--  M3 STRUCTURES
-- ******************* 
struct M3I_SeqData
(
	tag, ablock
)

fn M3I_getSize type flags:0 =
(
	local size
	case type of
	(
		#REF: 
		(
			case flags of
			(
				#MD33: size = 0x08
				#MD34: size = 0x0C
			)
		)
		#MD33: size = 0x14
		#MODL:
		(
			case flags of
			(
				23: size = 0x240
			)
		)
		#SEQS: size = 0x58
		#STC_: size = 0x8C
		#STG_: size = 0x10
		#STS_: size = 0x18
		#BONE: size = 0x9C
		#VERT: size = 0x20
		#U16_: size = 0x02
		#U32_: size = 0x04
		#CHAR: size = 0x01
		#DIV_: size = 0x24
		#REGN: size = 0x1C
		#BAT_: size = 0x0E
		#MSEC: size = 0x48
		#MATM: size = 0x08
		#MAT_: size = 0xD4
		#LAYR: size = 0x160
		#IREF: size = 0x40
	)
	
	return size
)

-- ***********
--  HELPERS
-- ***********
-- Liberally stolen from my M2 script
fn echo msg =
(
	format "%\n" (msg) to:listener
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

fn M3I_PointToArray pnt =
(
	local pntClass = classOf pnt as string
	local pntArray = #()
	case pntClass of
	(
		"Point2":
		(
			pntArray[2] = 0
			
			pntArray[1] = pnt.x
			pntArray[2] = pnt.y
		)
		"Point3":
		(
			-- initialise array
			pntArray[3] = 0
			
			pntArray[1] = pnt.x
			pntArray[2] = pnt.y
			pntArray[3] = pnt.z
		)
		"Point4":
		(
			pntArray[4] = 0
			
			pntArray[1] = pnt.x
			pntArray[2] = pnt.y
			pntArray[3] = pnt.z
			pntArray[4] = pnt.w
		)
	)
	
	return pntArray
)

fn M3I_Point4ToColour p4 =
(
	local col = color p4.x p4.y p4.z p4.w
	return col
)

fn M3I_IntToBool intgr =
(
	if (intgr > 0) then return true else return false
)

fn M3I_ReadVec bitStream flag array:0 =
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
			#v4dshort: (vec = [0,0,0,0]; vec.x = ReadShort bitStream #signed; vec.y = ReadShort bitStream #signed; vec.z = ReadShort bitStream #signed; vec.w = ReadShort bitStream #signed;)
			#v4dbyte: (vec = [0,0,0,0]; vec.x = ReadByte bitStream; vec.y = ReadByte bitStream; vec.z = ReadByte bitStream; vec.w = ReadByte bitStream;)
			#v4dubyte: (vec = [0,0,0,0]; vec.x = ReadByte bitStream #unsigned; vec.y = ReadByte bitStream #unsigned; vec.z = ReadByte bitStream #unsigned; vec.w = ReadByte bitStream #unsigned;)
			#v4dbyteFloat: (vec = [0.0, 0.0, 0.0, 0.0]; vec.x = (ReadByte bitStream #unsigned) / 255.0; vec.y = (ReadByte bitStream #unsigned) / 255.0; vec.z = (ReadByte bitStream #unsigned) / 255.0; vec.w = (ReadByte bitStream #unsigned) / 255.0;)
			#v3d: (vec = [0.0,0.0,0.0]; vec.x = ReadFloat bitStream; vec.y = ReadFloat bitStream; vec.z = ReadFloat bitStream;)
			#v2d: (vec = [0.0,0.0]; vec.x = ReadFloat bitStream; vec.y = ReadFloat bitStream;)
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

-- courtesy of MrMoonKr
-- Converts lower case string to uppercase without needing max 2008
fn M3I_toUpper str =
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

fn M3I_Convert_Time t =
(
	t / (1000 / M3I_useFPS)
)

fn M3I_GetID chunkid =
(
	local strID = chunkid as string
	local tagID = ""
	for i = 1 to chunkid.count do tagID += "A"
	-- reverse chunkid string
	for i = 1 to tagID.count do
	(
		k = (tagID.count + 1) - i
		tagID[i] = strID[k]
	)
	id = M3I_toUpper tagID -- Uppercase
	return id
)

fn M3I_Reset_Globals =
(
	head = mread = bstream = cmesh = mbones = mparts = undefined
	cmat = #()
	aread = #()
	tread = #()
	cbones = #()
	gc()
)

-- ************************
-- M3 FUNCTIONS
-- ************************ 
fn M3I_Open fname flags =
(
	M3I_Reset_Globals()
	
	step = "Accessing Model File"
	
	echo ("Opening "+fname+"...")
	bitStream = fopen fname flags
	if bitStream==undefined then 
	(
		echo "File not found!"
		throw "File not found"
	)
	
	return bitStream
)

fn M3I_Close bitStream =
(
	step = "Close"
	fclose bitStream
)

struct M3I_Sphere
(
	vmin, vmax, rad, flags,
	maxObj,
	
	fn Read bitStream flags =
	(
		local s = M3I_Sphere()
		s.vmin = M3I_ReadVec bitStream #v3d
		s.vmax = M3I_ReadVec bitStream #v3d
		s.rad = ReadFloat bitStream
		if (flags == #MD34) then s.flags = ReadLong bitStream #unsigned
		
		return s
	)
)

struct M3I_Tag -- Tag data
(
	dataID, ofsData, nData, flags,
	
	fn Read bitStream hinfo =
	(
		step = "Read Tags"
		
		local bm = ftell(bitStream) -- bookmark
		-- Pre-initializing arrays speeds up script
		local tr = #()
		tr[hinfo.nTag] = 0
		if (fseek bitStream hinfo.ofsTag #seek_set) then
		(	
			for i=1 to hinfo.nTag  do
			(
				local t 		= M3I_Tag()
				local chunkid = (ReadFixedString bitStream 4)
				t.dataID 	= (M3I_GetID chunkid) as name
				t.ofsData	= ReadLong bitStream #unsigned
				t.nData		= ReadLong bitStream #unsigned
				t.flags		= ReadLong bitStream #unsigned
			
				tr[i] = t
			)
		)
		fseek bitStream bm #seek_set -- return to bookmark
	
		return tr
	)
)

struct M3I_Ref
(
	entries, refid, data = #(), flags,
	
	fn Read bitStream flags:0 =
	(
		local r = M3I_Ref()
		r.entries 	= ReadLong bitStream #unsigned
		r.refid		= ReadLong bitStream #unsigned + 1
		if (head.fileID == #MD34) then r.flags = ReadLong bitStream #unsigned
		if (flags != #nodata) then
		(
			if (r.entries > 0) then
			(
				r.data 		= ReadTagData bitStream r.refid flags
				return r.data
			)
			else
			(
				return undefined
			)
		)
		else return r
	)
)

struct M3I_AnimKey
(
	stcID, frame, key
)

struct M3I_AnimRef -- Animation Reference
(
	flags, animflags, animid, initValue, nullValue, akeys,
	
	fn Read bitStream type readData:false =
	(
		ar = M3I_AnimRef()
		ar.flags = ReadShort bitStream #unsigned
		ar.animflags = ReadShort bitStream #unsigned
		ar.animid = ReadLong bitStream #unsigned
		
		case type of
		(
			#VEC2D:(ar.initValue = M3I_ReadVec bitStream #v2d; ar.nullValue = M3I_ReadVec bitStream #v2d;)
			#VEC3D:(ar.initValue = M3I_ReadVec bitStream #v3d; ar.nullValue = M3I_ReadVec bitStream #v3d;)
			#VEC4D:(ar.initValue = M3I_ReadVec bitStream #quat; ar.nullValue = M3I_ReadVec bitStream #quat;)
			#COLOUR:(ar.initValue = M3I_ReadVec bitStream #v4dubyte; ar.nullValue = M3I_ReadVec bitStream #v4dubyte;)
			#UINT32:(ar.initValue = ReadLong bitStream #unsigned; ar.nullValue = ReadLong bitStream #unsigned;)
			#UINT16:(ar.initValue = ReadShort bitStream #unsigned; ar.nullValue = ReadShort bitStream #unsigned;)
			#FLOAT:(ar.initValue = ReadFloat bitStream; ar.nullValue = ReadFloat bitStream;)
			#SPHERE:(ar.initValue = M3I_Sphere.Read bitStream 0; ar.nullValue = M3I_Sphere.Read bitStream 0;)
		)
		
		if (readData == true and doAnimateObjects) then
		(
			ar.akeys = M3I_GetAnimData ar mread aread
		)
		
		SkipBytes bitStream 0x04
		
		return ar
	)
)

fn M3I_Name name flt ext:undefined =
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

struct M3I_Header
(
	fileID, ofsTag, nTag, mref = M3I_Ref(),
	
	fn Read bitStream &header =
	(
		step = "Read header"
		echo "Reading Model Header..." 
	
		header = M3I_Header()
		local fileID = (ReadFixedString bitStream 4)
		header.fileID = (M3I_GetID fileID) as name
		echo ("Model Type: "+header.fileID as string)
		if (header.fileID != #MD33 and header.fileID != #MD34) then
		(
			echo "Not a valid Starcraft 2 model file!"
			throw "Not a valid Starcraft 2 model file!"
		)
		header.ofsTag 	= ReadLong bitStream #unsigned
		header.nTag		= ReadLong bitStream #unsigned
		header.mref		= M3I_Ref.Read bitStream flags:#nodata
	)
)

struct M3I_MODL
(
	name,  -- max model name
	versID, 
	SEQS, STC, STS, STG, -- anim info
	bones, 
	vflags, verts, DIV, blist,
    bndSphere, attach,
	matm, mat, ter,
	par, parc,
	IREF, attachvol
)

fn M3I_Read_MODL bitStream flags =
(
	echo "Reading Model Data..."
	mread				= M3I_MODL()
	local rsize			= M3I_getSize #Ref flags:head.fileID
	local mname 		= M3I_Ref.Read bitStream
	mread.name 		= M3I_Name mname "\\" ext:".max"
	echo ("Model Name: " + mread.name)	
	mread.versID 		= ReadLong bitStream #unsigned
	-- Animation data
	-- Don't read in unneccessary big chunks of data unless transforming bones
	if (doCreateBones and doAnimateObjects) then 
	(
		echo "Reading Animations..."
		mread.SEQS = M3I_Ref.Read bitStream
		-- Potentially massive array of data, better to store it in a different variable
		aread = M3I_Ref.Read bitStream
		mread.STG = M3I_Ref.Read bitStream
		
		echo "Animations read\n"
	)
	else
	(
		SkipBytes bitStream (rsize * 3)
	)
	
	-- SkipBytes
	case (head.fileID) of
	(
		#MD33: SkipBytes bitStream 0x14
		default: SkipBytes bitStream 0x1C
	)
	
	-- Bones
	if (doCreateBones) then
	(
		echo "Reading bones..."
		mbones		= M3I_Ref.Read bitStream
		echo "Bones read\n"
	)
	else
	(
		SkipBytes bitStream (rsize)
	)
	
	SkipBytes bitStream 0x04
	
	-- Mesh
	if (doCreateMesh) then
	(
		echo "Reading mesh data..."
		mread.vflags		= ReadLong bitStream #unsigned
		mread.verts		= M3I_Ref.Read bitStream flags:mread.vflags
		mread.DIV			= M3I_Ref.Read bitStream
		mread.blist			= M3I_Ref.Read bitStream flags:#ushort
		echo "Mesh data read\n"
	)
	else
	(
		SkipBytes bitStream (rsize * 3 + 4)
	)
	
	mread.bndSphere = M3I_Sphere.Read bitStream head.fileID
	
	case (head.fileID) of
	(
		#MD33: 
		(
			case flags of
			(
				20: SkipBytes bitStream 0x2C
				23: SkipBytes bitStream 0x34
			)
		)
		default:
		(
			case flags of
			(
				20: SkipBytes bitStream 0x30
				23: SkipBytes bitStream 0x3C
			)
		)
	)
	
	mread.attach = M3I_Ref.Read bitStream
	
	SkipBytes bitStream (rsize * 5)
		
	if (doCreateMats) then
	(
		echo "Reading materials..."
		mread.matm	= M3I_Ref.Read bitStream
		mread.mat		= M3I_Ref.Read bitStream
		SkipBytes bitStream (rsize * 2)
		mread.ter		= M3I_Ref.Read bitStream
		echo "Materials read\n"
	)
	else
	(
		SkipBytes bitStream (rsize * 5)
	)
	
	-- SkipBytes
	/*
	case (head.fileID) of
	(
		#MD33: SkipBytes bitStream 0x90
		default: SkipBytes bitStream 0xD8
	)
	*/
	SkipBytes bitStream (rsize * 3)
	
	mparts = M3I_Ref.Read bitStream
	mread.parc = M3I_Ref.Read bitStream
	
	SkipBytes bitStream (rsize * 13)
	
	if (doCreateBones) then 
	(
		mread.IREF = M3I_Ref.Read bitStream
	)
	else
	(
		SkipBytes bitStream (rsize)
	)
	
	SkipBytes bitStream 0x78
	
	mread.attachvol = M3I_Ref.Read bitStream
)

fn M3I_Read_Start bitStream =
(
	step = "Read Model Data"
	scrExit = false -- reset script exit flag
	scrStart = TimeStamp() -- start tracking script processing time
	M3I_Header.Read bitStream &head
	tread = M3I_Tag.Read bitStream head
	mtag = tread[head.mref.refid]
	-- Position bitstream at modl entry... kind of redundant as we should be there already
	fseek bitStream mtag.ofsData #seek_set
	
	M3I_Read_MODL bitStream mtag.flags
)

struct M3I_AnimData
(
	d1 = #(), name, d2, maxframes, moveSpeed, flags, frequency, d4 = #(), bndSphere,
	cstart, cend, -- Max variables
	
	fn Read bitStream tag =
	(
		ad = #()
		ad[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			a = M3I_AnimData()
			
			SkipBytes bitStream 8
			a.name = M3I_Ref.Read bitStream
			SkipBytes bitStream 4
			local mframes = ReadLong bitStream #unsigned
			a.maxframes 	= M3I_Convert_Time mframes
			a.moveSpeed 	= ReadFloat bitStream
			a.flags 		= ReadLong bitStream #unsigned
			a.frequency	= ReadLong bitStream #unsigned
			
			SkipBytes bitStream 0x10
			a.bndSphere = M3I_Sphere.Read bitStream head.fileID
			SkipBytes bitStream 0x08
			
			ad[i] = a
		)
		
		echo ("nAnims: " + ad.count as string)
		return ad
	)
)

struct M3I_AnimBlock -- Sequence Data
(
	frames, flags, fend, keys,
	
	fn Read bitStream tag =
	(
		ac = M3I_SeqData()
		ac.tag = tag
		ac.ablock = #()
		ac.ablock[tag.nData] = 0
		
		for i = 1 to tag.nData do
		(
			ab 			= M3I_AnimBlock()
			ab.frames 	= M3I_Ref.Read bitStream flags:#ulong
			ab.flags 		= ReadLong bitStream #unsigned
			ab.fend		= ReadLong bitStream #unsigned
			ab.keys 		= M3I_Ref.Read bitStream
			
			ac.ablock[i] = ab
		)
		
		return ac
	)
)

struct M3I_SeqCollection --Sequence Transformations Collection (STC)
(
	name, stcInd, animid, animref, animoffs, sdata, 
	seqInd, cstart, cend, freq, moveSpeed, looping, -- extra data
	
	fn Read bitStream tag =
	(
		step = "Read Sequence Transformations"
		
		sc = #()
		sc[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			local a = M3I_SeqCollection()

			a.name 		= M3I_Ref.Read bitStream
			SkipBytes bitStream 4
			a.stcInd		= ReadShort bitStream #unsigned
			SkipBytes bitStream 2
			a.animid		= M3I_Ref.Read bitStream flags:#ulong
			a.animoffs	= M3I_Ref.Read bitStream flags:#animind
			SkipBytes bitStream 4
			-- sequence data array
			sda = #()
			sda[13] = 0
			for i = 1 to 13 do
			(
				s			= M3I_Ref.Read bitStream
				sda[i]	= s
			)
			a.sdata = sda
			
			sc[i] = a
		)
		
		return sc
	)
)

struct M3I_AnimLookup
(
	name, stcind,
	
	fn Read bitStream tag =
	(
		step = "Read Animation Lookup"
		
		al = #()
		al[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			local a = M3I_AnimLookup()
			a.name = M3I_Ref.Read bitStream
			a.stcind = M3I_Ref.Read bitStream flags:#ulong
			for k = 1 to a.stcind.count do
			(
				-- Must be positive for max arrays later
				a.stcind[k] += 1
			)
			
			al[i] = a
		)
		
		return al
	)
)

fn M3I_GetAnimData animRef mdata adata =
(
	local stg = mdata.STG
	local refID = animRef.animid
	local akeyArray = #()
	for i = 1 to stg.count do
	(
		-- Find STC's for animation
		stgInd = stg[i]
		for k = 1 to stgInd.stcind.count do
		(
			stcInd = stgInd.stcind[k]
			-- 1. Find refid in animid list
			stc = adata[stcInd]
			animID = stc.animid
			local IDfound = findItem animID refID
			
			-- 2. If refid found -> transform bone with corresponding animation data
			-- if not found -> bone refid references no animation data
			if (IDfound != 0) then
			(
				local abInd = stc.animoffs[IDfound].aind
				local seqInd = stc.animoffs[IDfound].sdind
				local seqData = stc.sdata[seqInd]
				local ablock = seqData.ablock[abInd]
				
				for i = 1 to ablock.frames.count do
				(
					local akey = M3I_AnimKey()
					akey.stcID = stcInd
					akey.frame = ablock.frames[i]
					akey.key = ablock.keys[i]
					
					append akeyArray akey
				)
			)
		)
	)
	
	return akeyArray
)

struct M3I_Bone
(
	name, parent, trans, rot, scale, bindmat, animmat,
	maxObj,
	
	fn Read bitStream tag =
	(
		step = "Read Bones"
		
		br = #()
		br[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			local b = M3I_Bone()
			SkipBytes bitStream 4
			b.name = M3I_Ref.Read bitStream
			--echo ("Bone_" + i as string + ": " + b.name)
			SkipBytes bitStream 4
			b.parent = ReadShort bitStream #signed + 1
			SkipBytes bitStream 2
			b.trans = M3I_AnimRef.Read bitStream #VEC3D readData:true
			b.rot = M3I_AnimRef.Read bitStream #VEC4D readData:true
			b.scale = M3I_AnimRef.Read bitStream #VEC3D readData:true
			SkipBytes bitStream 0x14

			bmat = (inverse b.rot.initValue) as matrix3
			bmat.translation = b.trans.initValue

			b.bindmat = bmat
			
			br[i] = b
		)
		echo ("nBones: "+br.count as string)
		
		return br
	)
)

fn M3I_getUV uv =
(
	local uvm_sml = 2048.0
	for i = 1 to 2 do
	(
		local cuv = uv[i]
		cuv = cuv / 2048.0
		--if uv > 1 then echo("Warning! Vert["+i as string+"].uv["+j as string+"]: "+uv as string+" is above 1!")
		if (i==2) and (M3I_flipuv_y) then (cuv = 1 - cuv) -- flip Y
		-- update original Point3
		uv[i] = cuv
	)
)

struct M3I_Vertex
(
	pos, bw, bi, normal, uv, 
	
	fn Read bitStream tag flags =
	(
		step = "Read Verts"
		
		local vbytes, vcount, bsize; --vertice/buffer size, many thanks to Volcore for discovering these flags and their meanings!
		vbytes = 0x1C
		bsize = 1
		if (bit.get flags 19 == true) then bsize += 1
		if (bit.get flags 20 == true) then bsize += 1
		if (bit.get flags 21 == true) then bsize += 1
		vbytes += (bsize * 4)
		
		vcount = tag.nData / vbytes
		local vread = #()
		vread[vcount] = 0
		for i=1 to vcount do
		(
			local v = M3I_Vertex()
			v.pos = M3I_ReadVec bitStream #v3d
			
			-- vertex bone weights
			local m3weights = #()
			m3weights[4] = 0
			for j = 1 to 4 do 
			(
				m3weights[j] = ReadByte bitStream #unsigned
			) 
			
			-- vertex bone index
			local m3bind = #()
			m3bind[4] = 0
			for j = 1 to 4 do 
			(
				m3bind[j] = ReadByte bitStream #unsigned -- 1 + as maxscript arrays are 1 based
			)
			
			-- build real weight assignments
			v.bi = #()
			v.bw = #()
			for j = 1 to 4 do
			(
				local weight = m3weights[j]
				local bind = m3bind[j]
				if (weight > 0) then
				(
					local w = weight / 255.0
					local b = bind + 1
					
					append v.bw w
					append v.bi b
				)
			)

			-- First read in compressed normals
			v.normal = #()
			v.normal[4] = 0
			for j = 1 to 4 do 
			(
				vnorm = ReadByte bitStream #unsigned
				vnorm = vnorm / 255.0
				vnorm = 2 * vnorm
				vnorm = vnorm - 1
				v.normal[j] = vnorm
			)
			
			-- ignore scale for now...seems insignificant
			local vn = [0,0,0] -- need point3 when building mesh
			--local w = v.normal[4]
			for j = 1 to 3 do (vn[j] = v.normal[j])
			v.normal = vn
			
			if (bit.get flags 10 == true) then SkipBytes bitStream 0x04 --some kind of extra data 
			
			-- UV conversion
			local uvarray = #()
			for u = 1 to bsize do
			(
				local uv = [0,0,0]
				for j = 1 to 2 do 
				(
					uv[j] = ReadShort bitStream #signed
				)
				M3I_getUV uv
				append uvarray uv
			)
			v.uv = uvarray
			
			-- Additional data due to flags
			--SkipBytes bitStream bsize
			
			SkipBytes bitStream 0x04 -- tangent data
			
			vread[i] = v
		)
		echo ("nVerts: " + vread.count as string)
		
		return vread
	)
)

struct M3I_DIV -- Model divisions
(
	faces, smeshes, bat, msec,
	
	fn Read bitStream =
	(
		step = "Read DIV"
		
		div = M3I_DIV()
		div.faces = M3I_Ref.Read bitStream flags:#ushort
		div.smeshes = M3I_Ref.Read bitStream
		div.bat = M3I_Ref.Read bitStream
		div.msec = M3I_Ref.Read bitStream

		if (div.faces != undefined) then echo ("nFaces: " + div.faces.count as string)
		if (div.smeshes != undefined) then echo ("nSubmeshes: " + div.smeshes.count as string)
		
		return div
	)
)

struct M3I_Submesh
(
	indverts, nverts, indfaces, nfaces, indbones, nbones,
	maxMesh, m3verts = #(), create = true,
	
	fn Read bitStream tag =
	(
		step = "Read Submeshes"
		
		smr = #()
		smr[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			sm = M3I_Submesh()
			case (head.fileID) of
			(
				#MD33:
				(
					SkipBytes bitStream 0x04
					sm.indverts = ReadShort bitStream #unsigned
					sm.nverts = ReadShort bitStream #unsigned
				)
				default:
				(
					SkipBytes bitStream 0x08
					sm.indverts = ReadLong bitStream #unsigned
					sm.nverts = ReadLong bitStream #unsigned
				)
			)

			sm.indfaces = ReadLong bitStream #unsigned
			sm.nfaces = ReadLong bitStream #unsigned
			SkipBytes bitStream 0x02
			sm.indbones = ReadShort bitStream #unsigned
			sm.nbones = ReadShort bitStream #unsigned
			SkipBytes bitStream 0x06
				
			smr[i] = sm
		)
		
		return smr
	)
)

struct M3I_Subref -- Submesh refrences
(
	subid, matid,
	
	fn Read bitStream tag =
	(
		step = "Read Submesh Material references"
		
		sr= #()
		sr[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			mat = M3I_Subref()
			SkipBytes bitStream 0x04
			mat.subid = ReadShort bitStream #unsigned + 1
			SkipBytes bitStream 0x04
			mat.matid = ReadShort bitStream #unsigned + 1
			SkipBytes bitStream 0x02
			
			sr[i] = mat
		)
		
		return sr
	)
)

struct M3I_Attach
(
	name, bone,
	
	fn Read bitStream tag =
	(
		step = "Read Attachment references"
		
		attarr = #()
		attarr[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			att = M3I_Attach()
			SkipBytes bitStream 0x04
			att.name = M3I_Ref.Read bitStream
			att.bone = ReadLong bitStream #unsigned + 1
			
			attarr[i] = att
		)
		
		return attarr
	)
)

struct M3I_AttachVol
(
	attBone, attRad,
	
	fn Read bitStream tag =
	(
		step = "Read attachment volumes"
		
		attvol = #()
		attvol[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			avol = M3I_AttachVol()
			SkipBytes bitStream 0x0C
			avol.attBone = ReadLong bitStream #unsigned + 1
			SkipBytes bitStream 0x58
			avol.attRad = ReadFloat bitStream
			SkipBytes bitStream 0x08
			
			attvol[i] = avol
		)
		
		return attvol
	)
)

struct M3I_MATM
(
	matType, matInd,
	maxMaterial,
	
	fn Read bitStream tag =
	(
		step = "Read MATM"
		
		mtm = #()
		mtm[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			matm = M3I_MATM()
			matm.matType = ReadLong bitStream #unsigned
			matm.matInd = ReadLong bitStream #unsigned + 1
			
			mtm[i] = matm
		)
		
		return mtm
	)
)

struct M3I_Layr --more work to be done at a later point
(
	name, flags, uvFlags, alphaFlags, bright_mult, 
	UVoffset, UVtiling, UVangle,
	
	fn Read bitStream = 
	(
		layr = M3I_LAYR()
		
		SkipBytes bitStream 0x04
		local layrName = M3I_Ref.Read bitStream -- .dds file
		if (layrName != undefined and layrName != "") then layr.name = M3I_Name layrName "/" else layr.name = ""
		SkipBytes bitStream 0x14
		layr.flags = ReadLong bitStream #unsigned
		layr.uvFlags = ReadLong bitStream #unsigned
		layr.alphaFlags = ReadLong bitStream #unsigned
		layr.bright_mult = M3I_AnimRef.Read bitStream #FLOAT readData:true
		SkipBytes bitStream 0x70
		layr.UVoffset = M3I_AnimRef.Read bitStream #VEC2D readData:true
		layr.UVangle = M3I_AnimRef.Read bitStream #VEC3D readData:true
		layr.UVtiling = M3I_AnimRef.Read bitStream #VEC2D readData:true
		SkipBytes bitStream 0x54
		
		return layr
	)
)

struct M3I_Mat
(
	name, flags, 
	blendMode, priority, 
	spec, spec_mult, emis_mult, cutoutThresh,
	layerBlendType, emisBlendType,
	layrs,
	maxMaterial,

	fn Read_Layrs bitStream =
	(
		ml = #()
		-- Static 13 layers in Materials
		ml[13] = 0
		
		for j = 1 to 13 do
		(
			ml[j] = M3I_Ref.Read bitStream
		)
		
		return ml
	),
	fn Read bitStream tag =
	(
		step = "Read Materials"
		
		mr = #()
		mr[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			m = M3I_Mat()
			m.name 			= M3I_Ref.Read bitStream
			--echo ("Mat_" + i as string + ": " + m.name)
			SkipBytes bitStream 0x04
			m.flags 			= ReadLong bitStream #unsigned
			m.blendMode 	= ReadLong bitStream #unsigned
			m.priority		= ReadLong bitStream #unsigned
			SkipBytes bitStream 0x04
			m.spec 			= ReadFloat bitStream
			SkipBytes bitStream 0x04
			m.cutoutThresh = ReadLong bitStream #unsigned
			m.spec_mult 	= ReadFloat bitStream 
			m.emis_mult	= ReadFloat bitStream 
			
			-- Map Layers
			m.layrs = M3I_Mat.Read_Layrs bitStream
			
			SkipBytes bitStream 0x04
			m.layerBlendType = ReadLong bitStream #unsigned
			m.emisBlendType	= ReadLong bitStream #unsigned
			
			SkipBytes bitStream 0x30
			
			mr[i] = m
		)
		
		echo ("nMaterials: " + mr.count as string)	
		return mr
	),
	fn MapChk tname =
	(
		if (tname.count > 1) then
		(
			mcount = mapPaths.count()
			for i = 1 to mcount do
			(
				local tp = mapPaths.get i + "\\"
				
				tex = tp + tname
				if (doesFileExist(tex)) then
				(
					return tex
				)
				else if (i == mapPaths.count()) then
				(
					return 0
				)
			)
		)
		else
		(
			return 1
		)
	),
	fn Check =
	(
		step = "Check Materials"
		
		-- Material bitmap check
		local matlu = mread.DIV.bat
		local ss = stringstream "", fmt = "%\n"
		local ss_f = false
		if (matlu != undefined) then
		(
			for i = 1 to matlu.count do
			(
				-- find material referenced in lookup table
				mat_chk = matlu[i].matID
				mid = mread.matm[mat_chk].matInd
				m = mread.mat[mid]
				
				for j = 1 to 13 do
				(
					-- Check if file exists
					local map = m.layrs[j].name
					t = M3I_Mat.MapChk map
					-- If it doesn't, add it to error output for later
					if (t == 0) then 
					(
						-- prevent duplicates being added to list
						local strchk = ss as string
						local strmapchk = "*" + (map as string) + "*"
						if (matchPattern strchk pattern:strmapchk ignoreCase:true != true) then
						(
							format fmt map to:ss
						)
						
						-- Trip error switch
						ss_f = true
					)
				)
			)
		)
		
		if (ss_f) then
		(
			-- Error text
			textErr = "The following textures were not found in your 3ds maps directories:\n"
			textErr += ss
			echo textErr
			textErr += "These textures will not be applied to the model. Continue?"
			local t_scrTime = TimeStamp()
			if (queryBox textErr beep:false != true) then
			(
				-- Flip script exit, disable all further script activity
				echo "ERROR# Textures not found"
				scrExit = true
				doCreateBones = doTransformBones = doAnimateObjects = doCreateSkin = doCreateMesh = doCreateMats = doCreateBndSphere = false
			)
			else
			(
				-- Correct for time spent dealing with queryBox
				local t_scrTime = TimeStamp() - t_scrTime
				scrStart += t_scrTime
			)
		)
	)
)

struct M3I_TER
(
	name, map,
	maxMaterial,
	
	fn Read bitStream tag =
	(
		terArray = #()
		terArray[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			local ter 	= M3I_TER()
			ter.name 	= M3I_Ref.Read bitStream
			ter.map 		= M3I_Ref.Read bitStream
			
			terArray[i] = ter
		)
		
		return terArray
	)
)

struct M3I_PAR
(
	-- known values
	bone, matmIndex, 
	initEmissSpeed, speedVar, enableSpeedVar, angleX, angleY, spreadX, spreadY,
	lifespan, decay, enableDecay,
	pemitScale, colour1,
	minParticles, maxParticles, emissRate, type, emissArea, pivotSpread,
	enablePemitRotate, pemitRotate, enableColour2, colour2, partEmit, columns, rows, pemitFlags,
	enableTrailing, enableStreak, enableRadialEmission, parcRef, enableScale2, pemitScale2,
	
	-- unknown values
	emissSpeed2, emissSpeed3, scaleRatio, f1, speedUnk1, lifespanRatio, f2, f3, tailUnk1, spreadUnk1,
	ar1, speedUnk2, f4, f5, i1, f6, f7, i2, i3,
	
	-- maxObject
	maxObj,
	
	fn Read bitStream tag = 
	(
		parArray = #()
		parArray[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			local par = M3I_PAR()
			par.bone = ReadLong bitStream #unsigned + 1
			par.matmIndex = ReadLong bitStream #unsigned + 1
			par.initEmissSpeed = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.speedVar = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.enableSpeedVar = ReadLong bitStream #unsigned
			par.angleY = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.angleX = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.spreadX = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.spreadY = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.lifespan = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.decay = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.enableDecay = ReadLong bitStream #unsigned
			
			SkipBytes bitStream 0x0C
			
			par.emissSpeed2 = ReadFloat bitStream 
			par.scaleRatio = ReadFloat bitStream
			
			par.f1 = #()
			for j = 1 to 3 do (append par.f1 (ReadFloat bitStream))
			
			par.pemitScale = M3I_AnimRef.Read bitStream #VEC3D readData:true
			par.speedUnk1 = M3I_AnimRef.Read bitStream #VEC3D readData:true
				
			par.colour1 = #()
			for j = 1 to 3 do (append par.colour1 (M3I_AnimRef.Read bitStream #COLOUR readData:true))
			par.emissSpeed3 = ReadFloat bitStream
				
			SkipBytes bitStream 0x04
			
			par.f2 = #()
			for j = 1 to 2 do (append par.f2 (ReadFloat bitStream))
				
			SkipBytes bitStream 0x04
				
			par.enableTrailing = ReadLong bitStream #unsigned
				
			SkipBytes bitStream 0x08
			
			par.f3 = #()
			for j = 1 to 4 do (append par.f3 (ReadFloat bitStream))

			par.minParticles = ReadLong bitStream #unsigned
			par.maxParticles = ReadLong bitStream #unsigned
			par.emissRate = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.type = ReadLong bitStream #unsigned + 1
			par.emissArea = M3I_AnimRef.Read bitStream #VEC3D readData:true
			par.tailUnk1 = M3I_AnimRef.Read bitStream #VEC3D readData:true
			par.pivotSpread = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.spreadUnk1 = M3I_AnimRef.Read bitStream #FLOAT readData:true
			par.enableRadialEmission = ReadLong bitStream #unsigned
			par.enableScale2 = ReadLong bitStream #unsigned
			par.pemitScale2 = M3I_AnimRef.Read bitStream #VEC3D readData:true
			par.enablePemitRotate = ReadLong bitStream #unsigned
			par.pemitRotate = M3I_AnimRef.Read bitStream #VEC3D readData:true
			par.enableColour2 = ReadLong bitStream #unsigned
			par.colour2 = #()
			for j = 1 to 3 do (append par.colour2 (M3I_AnimRef.Read bitStream #COLOUR readData:true))
			
			SkipBytes bitStream 0x04
				
			par.partEmit = M3I_AnimRef.Read bitStream #UINT16 readData:true
			par.speedUnk2 = M3I_ReadVec bitStream #v4dbyteFloat
			par.lifespanRatio = ReadFloat bitStream
			par.columns = ReadShort bitStream #unsigned
			par.rows = ReadShort bitStream #unsigned
				
			par.f4 = #()
			for j = 1 to 2 do (append par.f4 (ReadFloat bitStream))
			
			SkipBytes bitStream 0x04
			par.f5 = ReadFloat bitStream
			SkipBytes bitStream 0x18
			par.enableStreak = ReadLong bitStream #unsigned
			par.f6 = ReadFloat bitStream
			SkipBytes bitStream 0x08
			par.f7 = ReadFloat bitStream
				
			SkipBytes bitStream 0x1A0
				
			par.pemitFlags = ReadLong bitStream #unsigned
			
			SkipBytes bitStream 0x2C
			par.ar1 = M3I_AnimRef.Read bitStream #FLOAT readData:true
			SkipBytes bitStream 0x30
			par.parcRef = M3I_Ref.Read bitStream flags:#ulong
			
			parArray[i] = par
		)
		
		return parArray
	)
)

struct M3I_PARC -- particle copy
(
	emissRate, partEmit, bone,
	parID,
	maxObj,
	
	fn Read bitStream tag =
	(
		parcArray = #()
		parcArray[tag.nData] = 0
		for i = 1 to tag.nData do
		(
			local parc = M3I_PARC()
			
			parc.emissRate = M3I_AnimRef.Read bitStream #FLOAT readData:false
			parc.partEmit = M3I_AnimRef.Read bitStream #UINT16 readData:false
			parc.bone = ReadLong bitStream #unsigned + 1
			
			parcArray[i] = parc
		)
		
		return parcArray
	)
)

struct M3I_Animoffs 
(
	aind, sdind,
	
	fn Read bitStream =
	(
		a = M3I_Animoffs()
		a.aind	= ReadShort bitStream #unsigned + 1
		a.sdind 	= ReadShort bitStream #unsigned + 1
		
		return a
	)
)

fn M3I_Read_Data bitStream tag flags = --Reading U32_, I32_, U8__, etc.
(
	local u = #()
	u[tag.nData] = 0
	for i = 1 to tag.nData do
	(
		local a
		case (flags) of
		(
			#animind: 
			(
				a	= M3I_Animoffs.Read bitStream
			)
			#ubyte: a = ReadByte bitStream #unsigned
			#ushort: a = ReadShort bitStream #unsigned
			#ulong: a = ReadLong bitStream #unsigned 
			#float: a = ReadFloat bitStream
		)
		
		u[i] = a
	)
	
	return u
)

fn ReadTagData bitStream tagInd flags =
(
	local bm = ftell(bitStream) -- bookmark first
	local d = #()
	th = tread[tagInd]

	if ((fseek bitStream th.ofsData #seek_set) and (th.nData > 0)) then
	(
		case (th.dataID) of
        (
			#MODL: d = M3I_Read_MODL bitStream th
			#SEQS: d = M3I_AnimData.Read bitStream th
			#STC_: d = M3I_SeqCollection.Read bitStream th
			#STG_: d = M3I_AnimLookup.Read bitStream th
			#SD4Q: d = M3I_AnimBlock.Read bitStream th
			#SD2V: d = M3I_AnimBlock.Read bitStream th
			#SD3V: d = M3I_AnimBlock.Read bitStream th
			#SDR3: d = M3I_AnimBlock.Read bitStream th
			#SDCC: d = M3I_AnimBlock.Read bitStream th
			#SDS6: d = M3I_AnimBlock.Read bitStream th
			#U8__ : d = M3I_Vertex.Read bitStream th flags
			#U16_: d = M3I_Read_Data bitStream th flags
			#I16_: d = M3I_Read_Data bitStream th #ushort
			#U32_: d = M3I_Read_Data bitStream th flags
			#I32_: d = M3I_Read_Data bitStream th flags
			#REAL: d = M3I_Read_Data bitStream th #float
			#VEC2: d = M3I_ReadVec bitStream #v2d array:th.nData
			#VEC3: d = M3I_ReadVec bitStream #v3d array:th.nData
			#QUAT: d = M3I_ReadVec bitStream #quat array:th.nData
			#COL: d = M3I_ReadVec bitStream #v4dubyte array:th.nData
			#DIV_: d = M3I_DIV.Read bitStream
			#REGN: d = M3I_Submesh.Read bitStream th
			#BAT_: d = M3I_Subref.Read bitStream th
			#MATM: d = M3I_MATM.Read bitStream th
			#MAT_: d = M3I_Mat.Read bitStream th
			#TER_: d = M3I_TER.Read bitStream th
			#LAYR: d = M3I_Layr.Read bitStream
			#ATT_: d = M3I_Attach.Read bitStream th
			#BONE: d = M3I_Bone.Read bitStream th
			#PAR_: d = M3I_PAR.Read bitStream th
			#PARC: d = M3I_PARC.Read bitStream th
			#CHAR: d = ReadFixedString bitStream th.nData
			#IREF: d = M3I_ReadVec bitStream #matrix array:th.nData
			#ATVL: d = M3I_AttachVol.Read bitStream th
			default: d = M3I_Read_Data bitStream th #ubyte
		)
		
		if (flags == #debug) then 
		(
			echo ("Tag: "+th as string)
			echo ("Data: "+d as string)
		)
	)
	else
		"Read Tag failed!"
	
	fseek bitStream bm #seek_set -- return to bookmark
	return d
)

-- ***************************
--  MAX SCENE FUNCTIONS
-- ***************************
-- Scene data funcs
fn M3I_STCtoStringStream stc =
(
	local ss = stringStream ""
	format ".name:%\n" stc.name to:ss
	format ".seqInd:%\n" stc.seqInd to:ss
	format ".cstart:%\n" stc.cstart to:ss
	format ".cend:%\n" stc.cend to:ss
	format ".freq:%\n" stc.freq to:ss
	format ".moveSpeed:%\n" stc.moveSpeed to:ss
	format ".looping:%\n" stc.looping to:ss
	return ss
)

fn M3I_Store_Anims =
(
	step = "Storing Animation Data"
	echo "Storing Animation Data in Scene..."

	-- Initiate Scene Object
	local ad
	local adCreate = true
	if ($_M3_Anim_Data != undefined) then 
	(
		local adObjClass = classOf ($_M3_Anim_Data) as string
		if (adObjClass == "Point") then adCreate = false
	)
	
	if (adCreate == true) then
	(
		-- Create scene object to house animation information
		ad = point size:0.001 pos:[0,0,0]
		ad.name = "_M3_Anim_Data"
		ad.renderable = off
		ad.isHidden = true
		ad.isFrozen = true
		ad.wirecolor = color 8 8 136
	)
		
	local stcssInd = 2 -- appData index begins at 2
	local astart = 3 -- leave keyframe 0 and 1 as bindposes
	local buffer = 2000 -- buffer between animations
	local animLU = mread.STG
	local SEQS = mread.SEQS
	local acount = 0
	
	for i = 1 to animLU.count do
	(
		seq		= SEQS[i]
		aluIndex = animLU[i]
		
		for k = 1 to aluIndex.stcind.count do
		(
			stcid = aluIndex.stcind[k]
			stc = aread[stcid]
			stc.name = (seq.name)
			stc.seqInd = (i - 1)
			stc.cstart = astart
			stc.cend = astart + seq.maxframes
			stc.freq = seq.frequency
			stc.moveSpeed = seq.moveSpeed
			local nonlooping = bit.get seq.flags 1
			if (nonlooping == true) then stc.looping = false else stc.looping = true -- invert looping switch
			
			if (ad != undefined) then
			(
				local stcss = M3I_STCtoStringStream stc
				setAppData ad stcssInd stcss
				stcssInd += 1
			)
			
			astart = stc.cend + (M3I_Convert_Time buffer)
			acount += 1
		)
	)
	
	if (adCreate == true) then
	(
		-- setup anim. obj header
		local adss = stringStream ""
		format ".version:%\n" M3I_sc2vers to:adss
		format ".count:%\n" acount to:adss
		setAppData ad 1 adss
	)
	frameRate = M3I_useFPS
)

-- BONE FUNCTIONS
-- from the maxscript reference
fn M3I_setNodeWorldRotation theNode theRot = 
( 
	local tmat = transmatrix theNode.transform.pos
	in coordsys tmat (theNode.rotation = theRot)
) 

fn M3I_Bone_Depth b =
(
	-- For organising bones based on depth
	if b.parent == 0 then 0
	else return ( 1 + M3I_Bone_Depth mbones[b.parent] )
)

fn M3I_Get_Bone_Depth bones =
(
	-- sort bones by depth
	bd = #()
	bd[bones.count] = 0
	for i=1 to bones.count do
	(
		bonerec = [(M3I_Bone_Depth bones[i]), i]
		bd[i] = bonerec
	)
	fn compfn a b = ( if a.x<b.x then return 1; else if a.x>b.x then return -1; else return 0; )
	qsort bd compfn
	
	return bd
)

fn M3I_qdot q1 q2 = return ((q1.x*q2.x) + (q1.y*q2.y) + (q1.z*q2.z) + (q1.w*q2.w))

fn M3I_Bones_Basepose modlbones =
(
	local bd = M3I_Get_Bone_Depth modlbones
	for i=1 to modlbones.count do
	(
		local h = bd[i].y
		b = modlbones[h]
		
		local bmat = matrix3 1
		rotate bmat (inverse b.rot.initValue)
		bmat.row4 = b.trans.initValue
		scale bmat b.scale.initValue

		if (b.maxObj.parent != undefined) then bmat = bmat * (b.maxObj.parent.transform)
		b.maxObj.transform = bmat
		
		/*
		in coordsys parent
		(
			cb.rotation = b.rot
			cb.position = b.pos
			cb.scale = b.scale
		)
		*/
	)
)

fn M3I_Bones_Poses modlbones bindFrame baseFrame =
(
	echo "Set up bones bindpose"
	with animate on
	(
		at time bindFrame
		(
			for i = 1 to modlbones.count do
			(
				cb = modlbones[i].maxObj
				iref = mread.iref[i]
				cb.transform = inverse iref
			)
		)
	)
	
	echo "Set up bones base pose"
	with animate on
	(
		at time baseFrame
		(
			M3I_Bones_Basepose mbones
		)
	)
)

fn M3I_Get_Bindmat bones =
(
	bonematarray = #()
	bonematarray[bones.count] = 0
	for i = 1 to bones.count do
	(
		cb = bones[i]
		local animmat = cb.transform
		
		bonematarray[i] = animmat
	)
	return bonematarray
)

fn M3I_Create_Bones =
(
	step = "Create Bones"
	echo "Creating bones..."
	cbones = #()
	
	mb = mbones
	for i = 1 to mb.count do
	(
		b = mb[i]
		iref = mread.iref[i]
		--echo ("Creating bone_" + i as string + ": " + b.name)
		
		cb = BoneSys.createBone [0,0,0] [0,0,0] [0,0,0.1]
		cb.name 		= b.name
		cb.width 		= 0
		cb.height		= 0
		cb.showLinks	= true
		cb.transform = inverse iref
		-- need to use tcb at some stage to get around gimbal lock...
		cb.rotation.controller = Linear_Rotation()
		cb.boneScaleType = #none
		
		b.maxObj = cb -- assign max bone
		
		-- update original array
		mbones[i] = b
	)
	max views redraw
	
	echo "Setting up bone hierarchy"
	for i=1 to mb.count do
	(
		b = mb[i]
		if b.parent!=0 then
		(
			-- echo ("Setting parent of " + i as string + " to " + (bones_read[i].par+1) as string)
			b.maxObj.parent = mb[b.parent].maxObj
		)
	)

	max views redraw
)

fn M3I_Create_BndSphere =
(
	if (mread.bndSphere != undefined) then
	(
		step = "Create Bound Sphere"
		echo "Creating bounding sphere..."
		local bsphere = mread.bndSphere
		local pos = (bsphere.vmin + bsphere.vmax) / 2 -- get centre
		local rad = bsphere.rad
		
		local bsphObj = sc2boundSphere pos:pos bndRadius:rad
		bsphObj.wirecolor = (color 6 134 58) -- dark green for bound sphere
		bsphere.maxObj = bsphObj
		
		-- update global structure
		mread.bndSphere = bsphere
	)
)

fn M3I_Child_Fix oldObj newObj =
(
	-- fix up any children of the new bone with children of the old bone
	if (oldObj.children != undefined) then 
	(
		for i = 1 to oldObj.children.count do
		(
			local child = oldObj.children[i]
			if (child != undefined) then
			(
				append newObj.children oldObj.children[i]
			)
		)
	)	
)

fn M3I_Create_Attachments =
(
	if (mread.attach != undefined) then
	(
		step = "Create Attachments"
		echo "Creating attachments..."
		
		for i = 1 to mread.attach.count do
		(
			mattach = mread.attach[i]

			local abone = mbones[mattach.bone].maxObj
			
			if (sc2attachment != undefined) then
			(
				cattach = sc2attachment name:abone.name
				cattach.attachName = mattach.name
				
				-- Target/Shield attachments are special cases, they have volumes
				if ((matchPattern mattach.name pattern:"Ref_Target*") or (matchPattern mattach.name pattern:"Ref_Shield*")) then
				(
					for j = 1 to mread.attachvol.count do
					(
						local mattvol = mread.attachvol[j]
						if (mattvol.attBone == mattach.bone) then 
						(
							cattach.attachRadius = mattvol.attRad
						)
					)
				)
				
				cattach.boxsize = 0.06
				cattach.wirecolor = green
				cattach.parent	= abone.parent
				cattach.transform = copy abone.transform
				cattach.showLinks = true
			)
			else
			(
				cattach 	= dummy name:mattach.name
				
				cattach.boxsize 	= [0.08,0.08,0.08]
				cattach.parent	= abone.parent
				cattach.transform = copy abone.transform
				cattach.showLinks = true
			)
			
			M3I_Child_Fix abone cattach
			
			-- leave attachment object only
			mbones[mattach.bone].maxObj = cattach
			delete abone
		)
	)
)

fn M3I_Create_Particles =
(
	if (sc2pemitter != undefined and mparts != undefined) then
	(
		step = "Create Particle Emitters"
		echo "Creating particle emitters..."
		
		for i = 1 to mparts.count do
		(
			local mpar = mparts[i]
			local pbone = mbones[mpar.bone].maxObj
		
			-- 3ds Max Settings
			cpar = sc2pemitter name:pbone.name
			cpar.parent = pbone.parent
			cpar.boxSize = 0.08
			cpar.wireColor = red
			cpar.transform = copy pbone.transform
			cpar.showLinks = true
			
			-- fix up any children of the particle emitter bone
			M3I_Child_Fix pbone cpar
			
			-- M3 Settings
			cpar.type = mpar.type
			cpar.columns = mpar.columns
			cpar.rows = mpar.rows
			cpar.enableStreak = bit.get mpar.enableStreak 1
			cpar.enableTrailing = bit.get mpar.enableTrailing 1
			cpar.minParticles = mpar.minParticles
			cpar.maxParticles = mpar.maxParticles
			
			cpar.lifeSpan = mpar.lifespan.initValue
			cpar.enableDecay = M3I_IntToBool mpar.enableDecay
			cpar.decay = mpar.decay.initValue
			cpar.pivotSpread = mpar.pivotSpread.initValue
			
			cpar.pemitScaleStart = mpar.pemitScale.initValue.x
			cpar.pemitScaleEnd = mpar.pemitScale.initValue.y
			cpar.pemitScaleSpread = mpar.pemitScale.initValue.z
			
			cpar.enablePemitRotate = M3I_IntToBool mpar.enablePemitRotate
			cpar.pemitRotateSpread1 = mpar.pemitRotate.initValue.x
			cpar.pemitRotateSpread2 = mpar.pemitRotate.initValue.y
			cpar.pemitRotateSpinSpeed = mpar.pemitRotate.initValue.z
			
			cpar.enableRadialEmission = bit.get mpar.enableRadialEmission 1
			cpar.initEmissSpeed = mpar.initEmissSpeed.initValue
			cpar.enableSpeedVar = M3I_IntToBool mpar.enableSpeedVar
			cpar.speedVar = mpar.speedVar.initValue
			cpar.rate = mpar.emissRate.initValue
			cpar.partEmit = mpar.partEmit.initValue
			
			cpar.pemitAreaWidth = mpar.emissArea.initValue.x
			cpar.pemitAreaLength = mpar.emissArea.initValue.y
			cpar.pemitAreaSpread = mpar.emissArea.initValue.z
			
			cpar.emissSpreadX = mpar.SpreadX.initValue
			cpar.emissSpreadY = mpar.SpreadY.initValue
			cpar.emissAngleX = mpar.AngleX.initValue
			cpar.emissAngleY = mpar.AngleY.initValue
			
			-- colours
			cpar.colour1start = mpar.colour1[1].initValue; cpar.colour1mid = mpar.colour1[2].initValue; cpar.colour1end = mpar.colour1[3].initvalue
			cpar.colour2start = mpar.colour2[1].initValue; cpar.colour2mid = mpar.colour2[2].initValue; cpar.colour2end = mpar.colour2[3].initvalue

			cpar.enableColour2 = M3I_IntToBool mpar.enableColour2
			
			-- particle flags
			local pflags = mpar.pemitFlags
			cpar.sort 							= bit.get pflags 1
			cpar.collideTerrain 				= bit.get pflags 2
			cpar.collideObjects				= bit.get pflags 3
			cpar.spawnOnBounce 			= bit.get pflags 4
			cpar.useInnerShape 				= bit.get pflags 5
			cpar.inheritEmissionParams 	= bit.get pflags 6
			cpar.inheritParentVel			= bit.get pflags 7
			cpar.sortByZHeight				= bit.get pflags 8
			cpar.reverseIteration			= bit.get pflags 9
			cpar.smoothRotation				= bit.get pflags 10
			cpar.bezSmoothRotation		= bit.get pflags 11
			cpar.smoothSize					= bit.get pflags 12
			cpar.bezSmoothSize				= bit.get pflags 13
			cpar.smoothColour				= bit.get pflags 14
			cpar.bezSmoothColour			= bit.get pflags 15
			cpar.litParts						= bit.get pflags 16
			cpar.randFlipBookStart			= bit.get pflags 17
			cpar.multiplyByGravity			= bit.get pflags 18
			cpar.clampTailParts				= bit.get pflags 19
			cpar.spawnTrailingParts			= bit.get pflags 20
			cpar.fixLengthTailParts			= bit.get pflags 21
			cpar.useVertexAlpha				= bit.get pflags 22
			cpar.modelParts					= bit.get pflags 23
			cpar.swapYZonModelParts		= bit.get pflags 24
			cpar.scaleTimeByParent 		= bit.get pflags 25
			cpar.useLocalTime				= bit.get pflags 26
			cpar.simulateOnInit				= bit.get pflags 27
			cpar.copy							= bit.get pflags 28
			
			-- unknown settings
			cpar.emissSpeed1 = mpar.emissSpeed2
			cpar.emissSpeed2 = mpar.emissSpeed3
			
			cpar.emissSpeed3X = mpar.speedUnk1.initValue.x
			cpar.emissSpeed3Y = mpar.speedUnk1.initValue.y
			cpar.emissSpeed3Z = mpar.speedUnk1.initValue.z
			
			cpar.speedUnk1X = mpar.speedUnk2.x
			cpar.speedUnk1Y = mpar.speedUnk2.y
			cpar.speedUnk1Z = mpar.speedUnk2.z
			cpar.speedUnk1W = mpar.speedUnk2.w
			
			cpar.enableScale2 = bit.get mpar.enableScale2 1
			cpar.scale2start = mpar.pemitScale2.initValue.x
			cpar.scale2end = mpar.pemitScale2.initValue.y
			cpar.scale2spread = mpar.pemitScale2.initValue.z
			
			cpar.scaleRatio = mpar.scaleRatio
			cpar.lifespanRatio = mpar.lifespanRatio
			
			cpar.tailUnkX = mpar.tailUnk1.initValue.x
			cpar.tailUnkY = mpar.tailUnk1.initValue.y
			cpar.tailUnkZ = mpar.tailUnk1.initValue.z
			
			cpar.spreadUnk = mpar.spreadUnk1.initValue
			
			cpar.unk1 = mpar.f1[1]
			cpar.unk2 = mpar.f1[2]
			cpar.unk3 = mpar.f1[3]
			cpar.unk4 = mpar.f2[1]
			cpar.unk5 = mpar.f2[2]
			cpar.unk6 = mpar.f3[1]
			cpar.unk7 = mpar.f3[2]
			cpar.unk8 = mpar.f3[3]
			cpar.unk9 = mpar.f3[4]
			cpar.unk10 = mpar.f4[1]
			cpar.unk11 = mpar.f4[2]
			cpar.unk12 = mpar.f5
			cpar.unk13 = mpar.f6
			cpar.unk14 = mpar.f7
			cpar.unk15 = mpar.ar1.initValue
			
			-- update original array with particle object
			mparts[i].maxObj = cpar
			
			-- leave particle object only
			mbones[mpar.bone].maxObj = cpar
			delete pbone
		)
	)
	else doCreatePemits = false
)

fn M3I_Create_PARCs =
(
	if (sc2pemitter != undefined and mparts != undefined) then
	(
		local echoBool = true
		step = "Create Particle Emitter Copies"
		
		for i = 1 to mparts.count do
		(
			local mpar = mparts[i]
			local cpar = mpar.maxObj
			local pbone = mbones[mpar.bone].maxObj
			
			-- check for particle emitter copies...
			if (mpar.parcRef != undefined) then
			(
				if (echoBool == true) then
				(
					echo "Creating particle emitter copies..."
					echoBool = false
				)
				
				for j = 1 to mpar.parcRef.count do
				(
					local parcRef = mpar.parcRef[j] + 1
					local parc = mread.parc[parcRef]
					local pcBone = mbones[parc.bone].maxObj
					mread.parc[parcRef].parID = i
					
					local parcObj = copy cpar
					
					parcObj.name = pcBone.name
					parcObj.parent = pcBone.parent
					parcObj.boxSize = 0.08
					parcObj.wireColor = red
					parcObj.transform = copy pcBone.transform
					parcObj.showLinks = true

					parcObj.rate = parc.emissRate.initValue
					parcObj.partEmit = parc.partEmit.initValue
					
					M3I_Child_Fix pcBone parcObj
					
					-- update original particle emitter copy object
					mread.parc[parcRef].maxObj = parcObj
					
					-- leave instanced particle emitter object only
					mbones[parc.bone].maxObj = parcObj
					
					delete pcBone
				)
			)
		)
	)
)

fn M3I_Animate_Entry arEntry &arValue vec:#null =
(
	if (arEntry.akeys != undefined) then
	(
		for i = 1 to arEntry.akeys.count do
		(
			local akey = arEntry.akeys[i]
			local stc = aread[akey.stcID]
			local t = stc.cstart + (M3I_Convert_Time akey.frame)
			
			if (t <= stc.cend) then -- sanity check
			(
				with animate on
				(
					at time t
					(
						case vec of
						(
							#x: arValue = akey.key.x
							#y: arValue = akey.key.y
							#z: arValue = akey.key.z
							#w: arValue = akey.key.w
							default: arValue = akey.key
						)
					)
				)
			)
		)
		
		-- create initValue entries between animations
		-- prevents bad interpolation
		stg = mread.STG
		seqs = mread.SEQS
		for i = 1 to seqs.count do
		(
			seqInd = seqs[i]
			stgInd = stg[i]
			
			for j = 1 to stgInd.stcind.count do
			(
				stcInd = stgInd.stcind[j]
				stc = aread[stcInd]
				aprev = stc.cstart - 1
				anext = stc.cend + 1
				poseFrames = #(aprev, anext)
				
				for k = 1 to 2 do
				(
					with animate on
					(
						set time poseFrames[k]
						case vec of
						(
							#x: arValue = arEntry.initValue.x
							#y: arValue = arEntry.initValue.y
							#z: arValue = arEntry.initValue.z
							#w: arValue = arEntry.initValue.w
							default: arValue = arEntry.initValue
						)
					) -- end animate loop
				) -- end k for loop
			) -- end j for loop
		) -- end i for loop
	) -- if akeys != undefined
)

fn M3I_Animate_Particles =
(
	if (mparts != undefined) then
	(
		step = "Animating particle emitters"
		echo "Animating particle emitters..."
		
		set time 0
		for i = 1 to mparts.count do
		(
			local mpart = mparts[i]
			local cpar = mpart.maxObj
			
			M3I_Animate_Entry mpart.lifeSpan &cpar.lifeSpan
			M3I_Animate_Entry mpart.decay &cpar.decay
			M3I_Animate_Entry mpart.pivotSpread &cpar.pivotSpread
			
			M3I_Animate_Entry mpart.initEmissSpeed &cpar.initEmissSpeed
			M3I_Animate_Entry mpart.speedVar &cpar.speedVar
			M3I_Animate_Entry mpart.emissRate &cpar.rate
			M3I_Animate_Entry mpart.partEmit &cpar.partEmit
			
			M3I_Animate_Entry mpart.emissArea &cpar.pemitAreaWidth vec:#x
			M3I_Animate_Entry mpart.emissArea &cpar.pemitAreaLength vec:#y
			M3I_Animate_Entry mpart.emissArea &cpar.pemitAreaSpread vec:#z
			
			M3I_Animate_Entry mpart.pemitScale &cpar.pemitScaleStart vec:#x
			M3I_Animate_Entry mpart.pemitScale &cpar.pemitScaleEnd vec:#y
			M3I_Animate_Entry mpart.pemitScale &cpar.pemitScaleSpread vec:#z
			
			M3I_Animate_Entry mpart.pemitRotate &cpar.pemitRotateSpread1 vec:#x
			M3I_Animate_Entry mpart.pemitRotate &cpar.pemitRotateSpread2 vec:#y
			M3I_Animate_Entry mpart.pemitRotate &cpar.pemitRotateSpinSpeed vec:#z
			
			M3I_Animate_Entry mpart.spreadX &cpar.emissSpreadX
			M3I_Animate_Entry mpart.spreadY &cpar.emissSpreadY
			
			M3I_Animate_Entry mpart.angleX &cpar.emissAngleX
			M3I_Animate_Entry mpart.angleY &cpar.emissAngleY
			
			-- colours
			M3I_Animate_Entry mpart.colour1[1] &cpar.colour1start
			M3I_Animate_Entry mpart.colour1[2] &cpar.colour1mid
			M3I_Animate_Entry mpart.colour1[3] &cpar.colour1end
			
			M3I_Animate_Entry mpart.colour2[1] &cpar.colour2start
			M3I_Animate_Entry mpart.colour2[2] &cpar.colour2mid
			M3I_Animate_Entry mpart.colour2[3] &cpar.colour2end

			M3I_Animate_Entry mpart.speedUnk1 &cpar.emissSpeed3X vec:#x
			M3I_Animate_Entry mpart.speedUnk1 &cpar.emissSpeed3Y vec:#y
			M3I_Animate_Entry mpart.speedUnk1 &cpar.emissSpeed3Z vec:#z
			
			M3I_Animate_Entry mpart.tailUnk1 &cpar.tailUnkX vec:#x
			M3I_Animate_Entry mpart.tailUnk1 &cpar.tailUnkY vec:#y
			M3I_Animate_Entry mpart.tailUnk1 &cpar.tailUnkZ vec:#z
			
			M3I_Animate_Entry mpart.spreadUnk1 &cpar.spreadUnk
			M3I_Animate_Entry mpart.ar1 &cpar.unk15
			
			M3I_Animate_Entry mpart.pemitScale2 &cpar.scale2start vec:#x
			M3I_Animate_Entry mpart.pemitScale2 &cpar.scale2end vec:#y
			M3I_Animate_Entry mpart.pemitScale2 &cpar.scale2spread vec:#z
		)
	)
)

fn M3I_Animate_PARCs =
(
	if (mread.parc != undefined) then
	(
		if (mread.parc.count > 0) then
		(
			step = "Animating particle emitter copies"
			echo "Animating particle emitter copies..."
			
			set time 0
			for i = 1 to mread.parc.count do
			(
				local parc = mread.parc[i]
				local parcObj = parc.maxObj
				
				M3I_Animate_Entry parc.emissRate &parcObj.rate
				M3I_Animate_Entry parc.partEmit &parcObj.partEmit
			)
		)
	)
)

fn M3I_Animate_BndSphere =
(
	if (mread.bndSphere != undefined) then
	(
		step = "Animate Bound Sphere"
		echo "Animating bounding sphere..."
		local sphereObj = mread.bndSphere.maxObj
		local stg = mread.STG
		local seqs = mread.SEQS
		
		for i = 1 to seqs.count do
		(
			local seqInd = seqs[i]
			local stgInd = stg[i]
			
			local bsphere = seqInd.bndSphere
			local newPos = (bsphere.vmin + bsphere.vmax) / 2 -- get centre
			local newRad = bsphere.rad
			
			for j = 1 to stgInd.stcind.count do
			(
				local stcInd = stgInd.stcind[j]
				local stc = aread[stcInd]
				local seqStart = stc.cstart
				local seqEnd = stc.cend
				local frames = #(seqStart, seqEnd)
				
				for k = 1 to 2 do
				(
					with animate on
					(
						set time frames[k]
						sphereObj.position = newPos
						sphereObj.bndRadius = newRad
					)
				)
			)
		)
	)
)

fn M3I_Animate_Bone modlBone type =
(
	-- set bones/created bones
	local b = modlBone
	local akeys
	
	case type of
	(
		#rot: akeys = b.rot.akeys
		#trans: akeys = b.trans.akeys
		#scale: akeys = b.scale.akeys
	)
	
	cb = b.maxObj
	local prevq = quat 1
	--at time basePose (prevq = cb.rotation.controller.value)

	for i = 1 to akeys.count do
	(
		akey = akeys[i]
		
		local t, key, stcID, stc
		stcID = akey.stcID
		stc = aread[stcID]
		key = akey.key
		
		t = stc.cstart + (M3I_Convert_Time akey.frame)

		with animate on
		(	
			set time t
			case (type) of
			(
				#trans: 
				(
					in coordsys parent cb.position = key
				)
				#rot:
				(
					local par = cb.parent

					local bmat = matrix3 1
					rotate bmat (inverse key)
					bmat.row4 = cb.pos
					scale bmat cb.scale

					if (par != undefined) then 
					(
						bmat = bmat * (par.transform)
					)

					-- setup transform
					-- this is the only way I could get rotations to work correctly for all models!
					cb.transform = bmat

					-- remove unneccesary keys
					deleteKey cb.position.controller (numKeys cb.position.controller)
					deleteKey cb.scale.controller (numKeys cb.scale.controller)
					
					local rkey = getKey cb.rotation.controller (numKeys cb.rotation.controller)
					local newq = rkey.value
					if ((M3I_qdot newq prevq) < 0) then 
					(
						rkey.value = -newq
					)
					prevq = rkey.value
				)
				#scale:
				(
					in coordsys parent cb.scale = key
				)
			) -- end of case
		) -- end animation handling
	) -- end of for loop
)

fn M3I_Animate_Bones =
(
	---------------------- animation
	-- sort bones by depth
	modlbones = mbones
	local bd = M3I_Get_Bone_Depth modlbones
	
	echo "Transforming bones..."
	step = "Bone transforms"
	
	for i=1 to modlbones.count do
	(
		local bind = bd[i].y
		--echo ("Doing bone " + i as string + " (depth: " + bd[k].x as string + ")" )
		--echo ("Transforming bone " + i as string)
		b = mbones[bind]

		-- rotation
		M3I_Animate_Bone b #rot
		-- translation
		M3I_Animate_Bone b #trans
		-- scale
		M3I_Animate_Bone b #scale
	)
	
	-- bindpose before and after animations
	-- prevents funny translations between animations
	echo "Setting up bindposes between animations..."
	stg = mread.STG
	seqs = mread.SEQS
	for i = 1 to seqs.count do
	(
		seqInd = seqs[i]
		stgInd = stg[i]
		
		for j = 1 to stgInd.stcind.count do
		(
			stcInd = stgInd.stcind[j]
			stc = aread[stcInd]
			aprev = stc.cstart - 1
			anext = stc.cend + 1
			poseFrames = #(aprev, anext)
			
			for k = 1 to 2 do
			(
				with animate on
				(
					set time poseFrames[k]
					M3I_Bones_Basepose mbones
				)
			)
		)
	)
	
	echo "Bone animation done\n"
)

fn M3I_Assign_Maps layr =
(
	local mapstr = M3I_Mat.MapChk layr.name
	if (isKindOf mapstr string) then
	(
		local smap
		local mapExt = M3I_toUpper (getFilenameType mapstr)
		if (sc2bitmap != undefined) then
		(
			local fname = getFilenameFile mapstr
			smap = sc2bitmap name:"Bitmap"
			if (mapExt == ".DDS") then
			(
				smap.scbitmap = openBitmap mapstr
			)
			else
			(
				smap.scCustomMap = mapstr
			)

			local uvFlags = bit.get layr.uvFlags 1
			if (uvFlags == true) then smap.mapChannel = 2 else smap.mapChannel = 1
			smap.TeamColour = bit.get layr.alphaFlags 1
			smap.TexAlphaOnly = bit.get layr.alphaFlags 2
			smap.Bright_Mult = layr.bright_mult.initValue
			
			-- UV Tiling
			smap.U_Tile = bit.get layr.flags 3
			smap.V_Tile = bit.get layr.flags 4
			smap.U_Offset = layr.UVoffset.initValue.x
			smap.V_Offset = layr.UVoffset.initValue.y
			smap.U_Tiling = layr.UVtiling.initValue.x
			smap.V_Tiling = layr.UVtiling.initValue.y
			
			if (doAnimateObjects) then
			(
				-- brightness
				M3I_Animate_Entry layr.bright_mult &smap.Bright_Mult
				
				-- UV offset 
				M3I_Animate_Entry layr.UVoffset &smap.U_Offset vec:#x
				M3I_Animate_Entry layr.UVoffset &smap.V_Offset vec:#y
				
				-- UV tiling
				M3I_Animate_Entry layr.UVtiling &smap.U_Tiling vec:#x
				M3I_Animate_Entry layr.UVtiling &smap.V_Tiling vec:#y
			)
		)
		else
		(
			if (mapExt == ".DDS") then
			(
				smap = BitMapTexture()
				smap.filename = mapstr
			)
		)

		return smap
	)
	else return undefined
)

fn M3I_Create_SC2Material matm =
(
	local mat = sc2material()
	local matType = matm.matType
	local matInd = matm.matInd
	
	local sc2mat
	case matType of
	(
		1:
		(
			sc2mat = mread.mat[matInd]
			mat.name = sc2mat.name
			
			mat.materialType = 2
			--{
			mat.Unfogged = bit.get sc2mat.flags 3 
			mat.TwoSided = bit.get sc2mat.flags 4 
			mat.Unshaded = bit.get sc2mat.flags 5 
			mat.NoShadowsCast = bit.get sc2mat.flags 6 
			mat.NoHitTest = bit.get sc2mat.flags 7 
			mat.NoShadowsReceived = bit.get sc2mat.flags 8 
			mat.DepthPrepass = bit.get sc2mat.flags 9 
			mat.UseTerrainHDR = bit.get sc2mat.flags 10 
			mat.SplatUVfix = bit.get sc2mat.flags 12 
			mat.SoftBlending = bit.get sc2mat.flags 13
			--}
		
			mat.blendMode 	= sc2mat.blendMode + 1 -- +1 due to using 1 based index
			mat.priority			= sc2mat.priority
			mat.specVal			= sc2mat.spec
			mat.specMult		= sc2mat.spec_mult
			mat.emisMult		= sc2mat.emis_mult
			mat.cutoutThresh = sc2mat.cutoutThresh
			mat.layerBlendType = sc2mat.layerBlendType + 1
			mat.emissiveBlendType = sc2mat.emisBlendType + 1
			
			-- init. team colour to red
			mat.TeamColourID = 3 -- Red
			
			mat.diffuseMap = M3I_Assign_Maps sc2mat.layrs[1]
			mat.decalMap = M3I_Assign_Maps sc2mat.layrs[2]
			mat.specularMap = M3I_Assign_Maps sc2mat.layrs[3]
			mat.selfIllumMap = M3I_Assign_Maps sc2mat.layrs[4]
			mat.emisMap2 = M3I_Assign_Maps sc2mat.layrs[5]
			mat.envioMap = M3I_Assign_Maps sc2mat.layrs[6]
			mat.envioMaskMap = M3I_Assign_Maps sc2mat.layrs[7]
			mat.alphaMaskMap = M3I_Assign_Maps sc2mat.layrs[8]
			mat.bumpMap = M3I_Assign_Maps sc2mat.layrs[10]
			mat.heightMap = M3I_Assign_Maps sc2mat.layrs[11]
		)
		4:
		(
			sc2mat = mread.ter[matInd]
			mat.name = sc2mat.name
			
			mat.materialType = 1
		)
	)
	
	return mat
)

fn M3I_Create_Materials =
(
	step = "Create Materials"
	
	echo "Creating Materials..."
	
	local submatlu = mread.DIV.bat -- submeshes
	local matArray = #() -- keeps track of created material IDs
	local maxMatInd = 1 -- used to assign materials in the material editor
	local matmArray = #()
	local matmIDArray = #()
	
	if (doCreateMesh == true) then
	(
		-- gather submesh materials
		if (submatlu != undefined) then
		(
			for i = 1 to submatlu.count do
			(
				local submat = submatlu[i]
				local matmID = submat.matID
				
				append matmIDArray matmID
			)
		)
	)
	
	if (doCreatePemits == true and mparts != undefined) then
	(
		-- gather particle materials
		for i = 1 to mparts.count do
		(
			local mpart = mparts[i]
			local matmID = mpart.matmIndex
			
			append matmIDArray matmID
		)
	)
	
	-- Create Materials
	for i = 1 to matmIDArray.count do
	(
		local matmID = matmIDArray[i]
		
		local matm = mread.matm[matmID]
		
		if ((findItem matmArray matm) == 0) then
		(
			append matmArray matm
			
			local maxMat = M3I_Create_SC2Material matm
			setMeditMaterial maxMatInd maxMat
			maxMatInd += 1
			
			-- update original matm
			mread.matm[matmID].maxMaterial = maxMat
		)
	)
)

fn M3I_Assign_Materials =
(
	-- submeshes
	if (doCreateMesh == true) then
	(
		local subs = mread.DIV.smeshes
		
		if (subs != undefined) then
		(
			local submats = mread.DIV.bat
			
			for i = 1 to submats.count do
			(
				local submat = submats[i]
				
				local matmID = submat.matID
				local regnID = submat.subID
				
				local smesh = subs[regnID]
				local matm = mread.matm[matmID]
				local sm = matm.maxMaterial
				
				smesh.maxMesh.material = sm
				if (sm.diffuseMap != undefined) then showTextureMap sm sm.diffuseMap on else (showTextureMap sm on)
			)
		)
	)
	
	-- particles
	if (doCreatePemits == true and mparts != undefined) then
	(
		for i = 1 to mparts.count do
		(
			local mpart = mparts[i]
			local matmID = mpart.matmIndex
			local matm = mread.matm[matmID]
			
			mpart.maxObj.pMaterial = matm.maxMaterial
		)
		
		if (mread.parc != undefined) then
		(
			for i = 1 to mread.parc.count do
			(
				local parc = mread.parc[i]
				local mpart = mparts[parc.parID]
				local matmID = mpart.matmIndex
				local matm = mread.matm[matmID]
				
				parc.maxObj.pMaterial = matm.maxMaterial
			)
		)
	)
)

fn M3I_SetVertexNormals mesh verts =
(
	animationRange = interval 0 100
	sliderTime = 0
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
		-- en_Unify node:mesh
		en_Move verts[i].normal
	)
	
	local nNormals = en.getNumNormals node:mesh
	en.select #{1..nNormals} node:mesh -- select all normals
	en.MakeExplicit node:mesh -- make them explicit
	en.select #{1..nNormals} node:mesh invert:true -- deselect them
	-- end method 1
	
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
	-- end method 2
	*/
	
	-- collapse edit_normal modifier
	collapseStack mesh
)
	
fn M3I_Apply_Skin mesh skinBones verts =
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
	-- 4. Set vertex weights
	for i = 1 to verts.count do
	(
		local vert = verts[i]
		skinOps.ReplaceVertexWeights sk i vert.bi vert.bw
	)
	enableSceneRedraw()

	update mesh
	redrawViews()
)

fn M3I_Create_Skin submeshes =
(
	if (submeshes != undefined) then
	(
		echo "Creating skin..."
		for i = 1 to submeshes.count do
		(
			local smesh = submeshes[i]
			
			if (smesh.create == true) then
			(
				-- Gather skinned bones
				local boneList = #()
				for i = 1 to smesh.nbones do
				(
					local bListInd = smesh.indbones + i
					local bInd = mread.blist[bListInd] + 1
					local sbone = mbones[bInd]
					append boneList sbone
				)
				
				M3I_Apply_Skin smesh.maxMesh boneList smesh.m3verts
			)
		)
	)
)

fn M3I_Create_Submesh smesh divFaces mVerts smName =
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
			case (head.fileID) of
			(
				#MD33: face[j] = divFaces[k] - smesh.indverts + 1
				default: face[j] = divFaces[k] + 1
			)
		)
		
		append faceList face
	)
	
	for i = 1 to smesh.nverts do
	(
		local vertInd = smesh.indverts + i
		local m3vert = mVerts[vertInd]
		local vpos = m3vert.pos
		local vuv = m3vert.uv
		
		append smesh.m3verts m3vert
		append vertList vpos
		append tvertList vuv
	)
	
	local msh = mesh vertices:vertList faces:faceList name:smName

	if (doVertexNormals == true) then
	(
		try
		(
			M3I_SetVertexNormals msh smesh.m3verts
		)
		catch
		(
			echo "ERROR# Setting vertex normals failed!"
		)
	)
	
	Update msh
	redrawViews()
	
	-- tvert faces
	if vertList.count != 0 then
	(
		-- setup map channels
		meshop.setNumMaps msh (1 + tvertList[1].count)
		for t = 1 to tvertList[1].count do
		(
			meshOp.setMapSupport msh t true
			meshOp.defaultMapFaces msh t 
		)
		
		-- setup uv coords for each channel
		for t = 1 to tvertList.count do
		(
			local tv = tvertList[t]
			
			for i = 1 to tv.count do
			(
				meshop.setMapVert msh i t tv[i]
			)
		)
	)
	Update msh

	smesh.maxMesh = msh
)

fn M3I_Create_Mesh =
(
	local regn = mread.DIV.smeshes
	
	cmesh = #()
	if (regn != undefined) then
	(
		step = "Create Mesh"
		echo "Creating submeshes..."
		for s = 1 to regn.count do
		(
			local smesh = regn[s]
			
			if (smesh.create == true) then
			(
				local smname = (mread.name+"_"+(s - 1) as string)
				format "Creating submesh %..." smname to:listener
				M3I_Create_Submesh smesh mread.DIV.faces mread.verts smname
				echo ("done!")
			)
		)
		
		step = "Create Mesh Done"
		echo "Submeshes done\n"
	)
)

-- ********
--  MAIN
-- ********
fn M3I_ScriptTime start end =
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

-- Import
fn M3I_Main file =
(	
	-- Read Model Data
	if (SC2PLUGIN_VERS == undefined) then
	(
		throw ("Starcraft 2 Object definition file not found\nMake sure sc2_objects.ms is loaded before trying to import")
	)
	
	echo "\n====== Import Starting ======\n"
	bstream = M3I_Open file "rb"
	M3I_Read_Start bstream
	M3I_Close(bstream)
	if (doCreateMats and doCreateMesh) then M3I_Mat.Check()
	
	-- Max Scene Objects
	if (scrExit != true) then echo "Creating Scene objects..."
	
	-- Bounding Sphere
	if (doCreateBndSphere) then
	(
		Try
		(
			M3I_Create_BndSphere()
		)
		Catch
		(
			echo "ERROR# Bound sphere import failed!"
			echo ("****"+getCurrentException()+"****")
		)
	)
	
	if (doAnimateObjects) then
	(
		M3I_Store_Anims()
		
		if (doCreateBndSphere) then
		(
			M3I_Animate_BndSphere()
		)
	)
	
	-- Bones
	if doCreateBones then
	(
		Try 
		(
			M3I_Create_Bones()
		)
		Catch
		(
			echo "ERROR# Bone import failed!"
			echo ("****"+getCurrentException()+"****")
			doCreateBones = false
			doCreateSkin = false
			doTransformbones = false
		)
		
		-- Bone Animation
		if doTransformBones then
		(
			Try
			(
				M3I_Animate_Bones()
			)
			Catch
			(
				echo "ERROR# Bone animation failed!"
				echo ("****"+getCurrentException()+"****")
				doTransformBones = false
			)
		)
		
		-- only execute if bones were properly created
		if (doCreateBones) then
		(
			M3I_Bones_Poses cbones 0 1
		)
		
		-- Attachments
		if doCreateAttachments then
		(
			Try
			(
				M3I_Create_Attachments()
			)
			Catch
			(
				echo "ERROR# Attachment import failed!"
				echo ("****"+getCurrentException()+"****")
				doCreateAttachments = false
			)
		)
		
		if (doCreatePemits) then
		(
			M3I_Create_Particles()
			if (doAnimateObjects) then
			(
				M3I_Animate_Particles()
			)
			
			-- need to copy original animated particle objects, then sub in the PARC animated emission values
			M3I_Create_PARCs()
			
			if (doAnimateObjects) then
			(
				M3I_Animate_PARCs()
			)
		)
	)

	-- Mesh
	if doCreateMesh then
	(
		Try
		(
			M3I_Create_Mesh()
			--M3I_Zoom_Model()
		)
		Catch
		(
			echo "ERROR# Mesh import failed!"
			echo ("****"+getCurrentException()+"****")
			doCreateMesh = false
			doCreateSkin = false
			doVertexNormals = false
			if isSceneRedrawDisabled() then enableSceneRedraw()
		)
	)
	
	-- Materials
	if (doCreateMats == true) then
	(
		try
		(
			M3I_Create_Materials()
			M3I_Assign_Materials()
		)
		Catch
		(
			echo "ERROR# Material import failed!"
			echo ("****"+getCurrentException()+"****")			
		)
	)
	
	if (doCreateSkin == true) then
	(
		try
		(
			M3I_Create_Skin mread.DIV.smeshes
		)
		catch
		(
			echo "ERROR# Skin creation failed!"
			echo ("****"+getCurrentException()+"****")
			doCreateSkin = false
			-- Fix viewport rendering if skinning failed during vertex weighting
			if isSceneRedrawDisabled() then enableSceneRedraw()				
		)
	)
	
	-- Check if script exit has been flipped
	if (scrExit) then
	(
		messageBox ("Import failed") title:"Import failed"
		echo "======= Import Aborted =======\n"
	)
	else
	(
		-- Calculate Script Execution time
		scrEnd = TimeStamp()
		local scrTime = M3I_ScriptTime scrStart scrEnd
		
		format "Import took % seconds\n" scrTime
		echo "====== Import Successful ======\n"
		messageBox ("Import Successful\nImport took "+scrTime) title:"Import successful"
		if doAnimateObjects then
		(
			M3I_AnimUI()
		)
	)

	setCommandPanelTaskMode #utility
	
	max select all
	
	-- Only once doesn't do a proper zoom
	for i = 1 to 3 do
	(
		max zoomext sel all
	)
	
	max views redraw
	clearSelection()
	
	M3I_Reset_Globals()
)

-- *********************************
--  USER INTERFACE FUNCTIONS
-- *********************************
-- Global UI Funcs
fn M3I_uiOpenFile ftypes &fname =
(
	local ret = getOpenFileName types:ftypes filename:fname
	if ret != undefined then fname = ret
)

utility m3imp "M3 - Import"
(
	group "Model Filename"
	(
		button bOpenFile "Open..."
		edittext tFileName
	)
	
	group "Settings"
	(
		checkBox chkImportMesh "Import Mesh" checked:(doCreateMesh) tooltip:"Imports Model Geometry"
		checkBox chkImportNorms "Import Vertex Normals" checked:(doVertexNormals)
		checkBox chkImportMats "Import Materials" checked:(doCreateMats) tooltip:"Imports Model Materials"
		checkBox chkImportBndSphere "Import Bounding Sphere" checked:(doCreateBndSphere) tooltip:"Imports Bounding Sphere"
		checkBox chkImportSkin	"Create Skin" checked:(doCreateSkin) enabled:(doCreateBones and doCreateMesh) tooltip:"Deforms mesh through bones"
		checkBox chkImportBones "Import Bones" checked:(doCreateBones) tooltip:"Imports Bones from Model"
		checkBox chkImportAttach "Import Attachments" checked:(doCreateAttachments) tooltip:"Imports Attachments"
		checkBox chkImportPemits "Import Particle Emitters" checked:(doCreatePemits) tooltip:"Imports Particle Emitters"
		checkBox chkAnimateObjects "Animate Objects" checked:(doAnimateObjects) tooltip:"Animate Objects"
		checkBox chkTransformBones "Animate Bones" checked:(doTransformBones) enabled:(doCreateBones) tooltip:"Animates model bones"
		spinner spnFPS "FPS:" range:[1,1000,1000] enabled:(doAnimateObjects) type:#integer
	)
	
	button bImport "Import" height:35 width:100 offset:[0,5]
	button bAbout "About" offset:[0,5]
	
	on m3imp open do
	(
		if (doCreateBones != true) then
		(
			chkImportAttach.checked = false
			chkImportAttach.enabled = false
			chkImportPemits.checked = false
			chkImportPemits.enabled = false
			chkTransformBones.checked = false 	
			chkTransformBones.enabled = false
			chkImportSkin.checked = false
			chkImportSkin.enabled = false
		)
		if (chkAnimateObjects.checked != true) then
		(
			chkTransformBones.enabled = false
			chkTransformBones.checked = false
			spnFPS.enabled = false
		)
		if (doCreateMesh != true) then
		(
			chkImportSkin.checked = false
		)
	)
	on chkImportMesh changed state do
	(
		if (state == on) then
		(
			if (chkImportBones.checked != false) then
			(
				chkImportSkin.checked = true
				chkImportSkin.enabled = true
			)
			chkImportNorms.checked = true
			chkImportNorms.enabled = true
			chkImportMats.checked = true
			chkImportMats.enabled = true
		)
		else
		(
			chkImportNorms.checked = false
			chkImportNorms.enabled = false
			chkImportSkin.checked = false
			chkImportSkin.enabled = false
			chkImportMats.checked = false
			chkImportMats.enabled = false			
		)
	)
	on chkImportBones changed state do
	(
		if (state == on) then
		(
			chkImportAttach.checked = true
			chkImportAttach.enabled = true
			chkImportPemits.checked = true
			chkImportPemits.enabled = true
			chkTransformBones.checked = true
			chkTransformBones.enabled	= true
			if (chkImportMesh.checked != false) then
			(
				chkImportSkin.checked = true
				chkImportSkin.enabled = true
			)
		)
		else
		(
			chkImportAttach.checked = false
			chkImportAttach.enabled = false
			chkImportPemits.checked = false
			chkImportPemits.enabled = false
			chkTransformBones.checked = false 	
			chkTransformBones.enabled = false
			chkImportSkin.checked = false
			chkImportSkin.enabled = false
		)
	)
	on chkAnimateObjects changed state do
	(
		if (state == on) then
		(
			chkTransformBones.enabled = true
			chkTransformBones.checked = true
			spnFPS.enabled = true
		)
		else
		(
			chkTransformBones.enabled = false
			chkTransformBones.checked = false
			spnFPS.enabled = false	
		)
	)
	on bOpenFile pressed do
	(
		M3I_uiOpenFile "M3 model (*.m3)|*.m3|All Files|*.*|" &tFileName.text
	)
	on bImport pressed do
	(
		local fname = tFilename.text
		if doesFileExist(fname) then
		(
			doCreateMesh = chkImportMesh.checked
			doVertexNormals = chkImportNorms.checked
			doCreateSkin = chkImportSkin.checked
			doCreateMats = chkImportMats.checked
			doCreateBndSphere = chkImportBndSphere.checked
			doCreateBones = chkImportBones.checked
			doCreateAttachments = chkImportAttach.checked
			doCreatePemits = chkImportPemits.checked
			doAnimateObjects = chkAnimateObjects.checked
			doTransformBones = chkTransformBones.checked
			M3I_useFPS = spnFPS.value
			try
			(
				M3I_Main(fname)
			)
			catch
			(
				messageBox ("Import failed\n"+getCurrentException()) title:"Import failed"
			)
			
		)
	)
	on bAbout pressed do
	(
		messagebox "M3 Importer v0.31 - 05-03-2011\n\xa9 2010, NiNtoxicated (madyavic@gmail.com)\nVisit www.sc2mapster.com for updates and more information\nHead to the forum for support. Feedback is appreciated!" title:"About"
	)
)

fn M3I_AnimUI =
(
	-- Reset
	if (sc2animUI != undefined) do 
	(
		closeUtility sc2animUI
		openUtility sc2animUI
	)
)