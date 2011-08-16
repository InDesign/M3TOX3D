------------------------------------------------------------------------------------------------
-- Starcraft 2 Model Objects version 0.06
-- by NiNtoxicated (madyavic@gmail.com)
-- 3ds max objects for use with Starcraft 2 model files (.M3)
-- Created for 3ds max 2010, but should be backwards compatible to 3ds Max 9 SP2
--
-- Objects:
-- sc2material - Material plugin for setting material and layer properties
-- sc2bitmap - Bitmap plugin with extra map options
-- sc2attachment - Helper plugin to add attachments to a scene
-- sc2boundsphere -- Bounding sphere plugin for custom bounding sphere
-- sc2pemitter -- Particle emitter plugin
--
-- User Interfaces:
-- sc2animUI - Animation interface for viewing and editing animations
--
------------------------------------------------------------------------------------------------
--
-- Version History:
-- 0.06 - March 5th 2011
-- Added sc2pemitter particle emitter support
-- Added sc2attachment volume support
-- Added sc2boundsphere custom bound sphere support
-- Added sc2bitmap animation support
-- Improved sc2attachment wireframe display
-- Improved sc2bitmap support
-- Miscellaneous code fixes and improvements
--
-- 0.05c - August 15th 2010
-- Fixed animation object bug
--
-- 0.05b - July 22nd 2010
-- Attachments now retain previous settings
-- Added two new attachment ID presets
--
-- 0.05 - July 15th 2010
-- Added sc2bitmap custom map support
-- Added sc2bitmap brightness multiplier
-- Added to sc2bitmap more UV options
--
-- 0.04b - June 29th 2010
-- Fixed Start frame minusing by 1 bug in animation UI
--
-- 0.04 - June 28th 2010
-- Added attachment custom object
-- Updated material, now supports Terrain (Null) textures
-- Updated decal entry in material, now supports decals properly
-- Updated bitmap to support map channels
-- Fixed same range animation UI error
--
-- 0.03b - June 12th 2010
-- Fixed Animation data holder not being updated correctly
--
-- 0.03 - June 9th 2010
-- Updated Animation UI heavily to include editing capabilities
-- Added callback support for Animation UI
-- Added view button to sc2bitmap materials
--
-- 0.02 - May 17th 2010
-- sc2bitmap definition updated
-- Integrated animation UI
--
-- 0,01 - May 15th 2010
-- Initial objects script version
-- sc2material defined
-- sc2bitmap defined
--
------------------------------------------------------------------------------------------------
-- *****************
--  MISC GLOBALS
-- *****************
global SC2PLUGIN_VERS = 0.06

-- ***********************
--  GLOBAL FUNCTIONS
-- ***********************
fn sc2uiOpenFile ftypes &fname =
(
	local ret 
	if (fname != undefined) then
	(
		ret = getOpenFileName types:ftypes filename:fname
	)
	else
	(
		ret = getOpenFileName types:ftypes
	)
	if ret != undefined then fname = ret
)

fn sc2_toStrArray aray =
(
	local aClass = classOf aray as string
	if (aClass == "Array") then
	(
		local aReturn = #()
		for i = 1 to aray.count do
		(
			local aStr = aray[i] as string
			append aReturn aStr
		)
		
		return aReturn
	)
	else
	(
		return undefined
	)
)

-- ***************
--  M3 OBJECTS
-- *************** 
plugin Material sc2material
name:"Starcraft 2" 
classID:#(0x1ccf0cb1, 0x1e0c2826)
extends:Standard replaceUI:true version:2
( 
	local teamColourIDlist = #("Custom", "White", "Red", "Blue", "Teal", "Purple", "Yellow", "Orange", "Green", "Light Pink", "Violet", "Light Grey", "Dark Green", "Brown", "Light Green", "Dark Grey", "Pink")
	local teamColourDiffList = #([255,255,255], [180,20,30], [0,66,255], [28,167,234], [84,0,129], [235,225,41], [254,138,14], [22,128,0], [204,166,252], [31,1,201], [82,84,148], [16,98,70], [78,42,4], [150,255,145], [35,35,35], [229,91,176])
	local teamColourDiffListStr = sc2_toStrArray teamColourDiffList
	local teamColourEmissList = #()
	local mattypeui, matsettui, flagsui, layersui, layers
	local isCreated = false
	
	fn TeamColourSetupUI =
	(
		local tc = this.TeamColourDiff as point3 -- convert from colour to p3
		tc = tc as string -- convert to string for comparison
		local tcFind = findItem teamColourDiffListStr tc
		if (tcFind > 0) then
		(
			this.TeamColourID = tcFind + 1
		)
		else
		(
			this.TeamColourID = 1
		)
	)
	
	parameters matsett rollout:matsettui
	(
		blendMode type:#integer default:1 ui:ddlBlendMode
		priority type:#integer default:0 ui:spnPriority
		cutoutThresh type:#integer default:0 ui:spnCutoutThresh
		specVal type:#float default:0 ui:spnSpec
		specMult type:#float default:1 ui:spnSpecMult
		emisMult type:#float default:1 ui:spnEmisMult
		layerBlendType type:#integer default:3 ui:ddlLayerBlend
		emissiveBlendType type:#integer default:3 ui:ddlEmissiveBlend
			
		on specVal set val do delegate.specularLevel = val
	)
	
	parameters flags rollout:flagsui
	(
		Unfogged type:#boolean ui:chkUnfogged
		TwoSided type:#boolean ui:chkTwoSided
		Unshaded type:#boolean ui:chkUnshaded
		NoHitTest type:#boolean ui:chkNoHitTest
		DepthPrepass type:#boolean ui:chkDepthPrepass
		UseTerrainHDR type:#boolean ui:chkTerrainHDR
		SplatUVfix type:#boolean ui:chkSplatUV
		SoftBlending type:#boolean ui:chkSoftBlend
		NoShadowsCast type:#boolean ui:chkNoShadowsCast
		NoShadowsReceived type:#boolean ui:chkNoShadowsRec
		
		on TwoSided set val do delegate.twoSided = val
	)
	
	parameters layers rollout:layersui
	(
		-- for team colour preview
		teamColourDiff type:#color default:[255,255,255] ui:clpTeamColourDiff
		teamColourEmiss type:#color default:[255,255,255] ui:clpTeamColourEmiss
		teamColourID type:#integer default:1 ui:ddlTeamColourID
		
		compMap type:#textureMap
		diffuseMap type:#textureMap ui:mbDiffuse subAnim:true
		decalMap type:#textureMap ui:mbDecal subAnim:true
		specularMap type:#textureMap ui:mbSpec subAnim:true
		selfIllumMap type:#textureMap ui:mbEmis subAnim:true
		emisMap2 type:#textureMap ui:mbEmis2 subAnim:true
		envioMap type:#textureMap ui:mbEnvio subAnim:true
		envioMaskMap type:#textureMap ui:mbEnvioMask subAnim:true
		alphaMaskMap type:#textureMap ui:mbAlphaMask subAnim:true
		bumpMap type:#textureMap ui:mbNorm subAnim:true
		heightMap type:#textureMap ui:mbHeight subAnim:true

		-- Set Team Colours
		on teamColourID set val do
		(
			if (val != 1) then
			(
				local tcInd = val - 1
				teamColourDiff = teamColourDiffList[tcInd]
			)
		)
		on teamColourDiff set val do
		(
			delegate.diffuse = val
			this.TeamColourSetupUI()
		)
		on teamColourEmiss set val do
		(
			-- not working yet
			-- delegate.selfIllumColor = val
		)
		
		-- Set Maps
		on diffuseMap set val do 
		(
			compMap.mapList[1] = val
		)
		on decalMap set val do
		(
			local dmap = val
			if (dmap != undefined) then 
			(
				local dmapClass = classOf dmap as string
				if (dmapClass == "sc2bitmap") then
				(
					dmap.isDecal = true
					dmap.preMultAlpha = false
				)
			)
			compMap.mapList[2] = dmap
		)
		on compMap set val do
		(
			delegate.diffuseMap = val
		)
		on specularMap set val do delegate.specularMap = val
		on selfIllumMap set val do delegate.selfIllumMap = val
		on bumpMap set val do delegate.bumpMap = val
		--on envioMap set val do delegate.ReflectionMap = val
	)
	
	parameters mattype rollout:mattypeui
	(
		materialType type:#integer default:2 ui:ddlMaterialType
		
		on materialType set val do
		(
			if (this.isCreated == true) then
			(
				case val of
				(
					1: 
					(
						removeRollout this.matsettui
						removeRollout this.layersui
						removeRollout this.flagsui
						
						-- blank maps
						this.diffuseMap 		= undefined
						this.decalMap 			= undefined
						this.specularMap 		= undefined
						this.selfIllumMap 		= undefined
						this.emisMap2			= undefined
						this.envioMap 			= undefined
						this.envioMaskMap	= undefined
						this.alphaMaskMap	= undefined
						this.bumpMap			= undefined
						this.heightMap			= undefined
					)
					2: 
					(
						addRollout this.matsettui
						addRollout this.layersui
						addRollout this.flagsui
					)
				)
			)
		)
	)
	
	rollout matsettui "Material Settings" category:2
	(
		group "Blend Types, Team Colour Preview"
		(
			dropdownlist ddlBlendMode "Blend Mode:" items:#("Opaque", "Alpha Blend", "Add", "Alpha Add",  "Mod", "Mod 2x") across:2 align:#left width:85
			dropdownlist ddlLayerBlend "Layer Blend Type:" items:#("Mod", "Mod 2x", "Add", "Blend", "Team Colour Emissive Add", "Team Colour Diffuse Add") selection:3 align:#left width:120 
			dropdownlist ddlEmissiveBlend "Emissive Blend Type:" items:#("Mod", "Mod 2x", "Add", "Blend", "Team Colour Emissive Add", "Team Colour Diffuse Add") selection:3 align:#left width:120
		)

		group "Properties"
		(
			spinner spnPriority "Priority: " fieldwidth:40 range:[0,1e9,0] type:#integer align:#left across:2
			spinner spnCutoutThresh "Cutout Threshold: " fieldwidth:40 range:[0,1e9,0] type:#integer scale:1 
			spinner spnSpec "Specularity: " fieldwidth:45 range:[0,1e9,0] scale:1 align:#left across:2
			spinner spnEmisMult "HDR Emissive Multiplier: " fieldwidth:45 range:[0,1e9,1] scale:1 align:#right
			spinner spnSpecMult "HDR Specular Multiplier: " fieldwidth:45 range:[0,1e9,1] scale:1 align:#right 
		)
		
		on matsettui open do
		(
			case materialType of
			(
				1: removeRollout this.matsettui
			)
		)
	)
	
	rollout flagsui "Flags" category:4
	(
		group "Flags"
		(
			checkbox chkUnfogged "Unfogged" align:#left across:3
			checkbox chkTwoSided "Two Sided"
			checkbox chkUnshaded "Unshaded"
			
			checkbox chkNoHitTest "No Hit Test" align:#left across:3
			checkbox chkDepthPrepass "Depth Pre-pass"
			checkbox chkTerrainHDr "Use Terrain HDR" 
			
			checkbox chkSplatUV "Splat UV Fix" align:#left across:3
			checkbox chkSoftBlend "Soft Blending"			
			checkbox chkNoShadowsCast "No Shadows Cast"
			
			checkbox chkNoShadowsRec "No Shadows Received"
		)
		
		on flagsui open do
		(
			case materialType of
			(
				1: removeRollout this.flagsui
			)			
		)
	)
	
	rollout layersui "Layers" category:3
	(
		group "Team Colour Preview"
		(
			dropdownlist ddlTeamColourID "Team Colour:" items:teamColourIDlist align:#left width:85 across:3
			colorPicker clpTeamColourDiff "Diffuse:" color:[255,255,255] align:#right height:30
			colorPicker clpTeamColourEmiss "Emissive:" color:[255,255,255] align:#left height:30 enabled:false visible:false
		)
		
		group "Map Layers"
		(
			label lblDiffuse "Diffuse Map: " across:2 align:#left
			mapbutton mbDiffuse "None" tooltip:"Select Diffuse Map" offset:[-45,0] width:175
			label lblDecal "Decal Map: " across:2 align:#left
			mapbutton mbDecal "None" tooltip:"Select Decal Map" offset:[-45,0] width:175
			label lblSpec "Specular Map: " across:2 align:#left
			mapbutton mbSpec "None" tooltip:"Select Specular Map" offset:[-45,0] width:175
			label lblEmis "Emissive Map: " across:2 align:#left
			mapbutton mbEmis "None" tooltip:"Select Emissive Map" offset:[-45,0] width:175
			label lblEmis2 "Emissive Map 2: " across:2 align:#left
			mapbutton mbEmis2 "None" tooltip:"Select Emissive Map" offset:[-45,0] width:175
			label lblEnvio "Envio Map: " across:2 align:#left
			mapbutton mbEnvio "None" tooltip:"Select Envio Map" offset:[-45,0] width:175
			label lblEnvioMask "Envio Mask Map: " across:2 align:#left
			mapbutton mbEnvioMask "None" tooltip:"Select Envio Mask Map" offset:[-45,0] width:175
			label lblAlphaMask "Alpha Mask Map: " across:2 align:#left
			mapbutton mbAlphaMask "None" tooltip:"Select Alpha Mask Map" offset:[-45,0] width:175
			label lblNorm "Normal Map: " across:2 align:#left
			mapbutton mbNorm "None" tooltip:"Select Normal Map" offset:[-45,0] width:175
			label lblHeight "Height Map: " across:2 align:#left
			mapbutton mbHeight "None" tooltip:"Select Height Map" offset:[-45,0] width:175
		)
		
		on layersui open do
		(
			this.TeamColourSetupUI()
			case materialType of
			(
				1: removeRollout this.layersui
			)
		)
	)

	rollout mattypeui "Material Type" category:1
	(
		dropdownlist ddlMaterialType "Material Type:" items:#("Terrain (Null)", "Normal") width:120
		
		on mattypeui open do
		(
			-- necessary for proper add/remove rollout in plugin
			if this.isCreated == false then 
			(
				this.isCreated = true
			)
		)
	)
	
	on create do
	(
		-- setup initial material
		delegate.bumpMapAmount = 100
		
		-- initialise composite
		compMap = compositeTextureMap()
		compMap.mapList.count = 2
	)
	
	on update do
	(
		if version == 1 then
		(
			this.compMap = compositeTextureMap()
			this.compMap.mapList.count = 2
			if (delegate.diffuseMap != undefined) then
			(
				local classMap = classOf delegate.diffuseMap as string
				if (classMap != "CompositeTexturemap") then 
				(
					this.compMap.mapList[1] = diffuseMap
					this.compMap.mapList[2] = decalMap
					delegate.diffuseMap = compMap
				)
			)
			this.isCreated = false
			this.materialType = 2
		)
	)
)

plugin textureMap sc2bitmap
name:"Starcraft 2 Bitmap"
classID:#(0x48f387a2, 0x6950179f)
autoPromoteDelegateProps:true
extends:Bitmaptexture replaceUI:true version:6
remap:#(#("TexWrap"),#("TexWrap2"))
(
	local isCreated = false
	
	fn assign_bitmap =
	(
		local bmap = SelectBitmap()
		if (bmap != undefined) then
		(
			-- update bitmap
			delegate.bitmap = bmap
		)
		else
		(
			-- else leave it as it was if no custom map detected
			if (this.scCustomMap.count < 1) then
			(
				bmap = this.scbitmap
			)
		)
		return bmap
	)
	
	fn alphaSetup =
	(
		-- setup bitmap alpha
		if (this.TeamColour == true) then
		(
			delegate.alphasource = 0
		)
		else
		(
			delegate.alphasource = 2
		)
	)
	
	parameters map rollout:mapui
	(
		scbitmap type:#bitmap
		scCustomMap type:#string default:""
		isDecal type:#boolean default:false
		
		on scbitmap set val do
		(
			if (scbitmap != undefined) then
			(
				local scbitmapClass = classOf scbitmap as string
				if (scbitmapClass == "BitMap") then
				(
					if (scbitmap.filename.count > 0) then
					(
						delegate.bitmap = scbitmap
						if (isDecal == true) then delegate.preMultAlpha = false
					)
					else
					(
						delegate.bitmap.filename = ""
					)
				)
			)
		)
	)--end params
	
	parameters mapsett rollout:mapsettui
	(
		-- General Settings
		Bright_Mult type:#float default:1.0 ui:spnBright_Mult animatable:true
		
		-- Coordinate Settings
		mapChannel type:#integer default:1 ui:spnMapChannel
		
		U_Offset type:#float default:0.0 ui:spnU_Offset animatable:true
		V_Offset type:#float default:0.0 ui:spnV_Offset animatable:true
		U_Tiling type:#float default:1.0 ui:spnU_Tiling animatable:true
		V_Tiling type:#float default:1.0 ui:spnV_Tiling animatable:true
		
		U_Tile type:#boolean default:true ui:chkU_Tile
		V_Tile type:#boolean default:true ui:chkV_Tile
		
		on mapChannel set val do
		(
			delegate.coords.mapChannel = val
		)
		on U_Offset set val do
		(
			delegate.coords.U_Offset = val
		)
		on V_Offset set val do 
		(
			delegate.coords.V_Offset = val
		)
		on U_Tiling set val do
		(
			delegate.coords.U_Tiling = val
		)
		on V_Tiling set val do
		(
			delegate.coords.V_Tiling = val
		)
		on U_Tile set val do delegate.coords.U_Tile = val
		on V_Tile set val do delegate.coords.V_Tile = val

	)
	
	parameters alphasett rollout:alphasettui
	(
		-- Alpha Flags
		TeamColour type:#boolean ui:chkTeamColour
		TexAlphaOnly type:#boolean ui:chkTexAlphaOnly
		
		on TeamColour set val do
		(
			alphaSetup()
		)
		on TexAlphaOnly set val do
		(
			alphaSetup()
		)
	)

	rollout mapui "Map Path"
	(
		local mapSet
		
		group "Map"
		(
			label	lblBitmap "Bitmap:" align:#left across:2
			button btnBitmap "None" offset:[-55,0] width:260 text:"None"
			button btnViewImage "View Image" align:#right enabled:false
		)
		
		rollout mapPick "Map Type"
		(
			group "Bitmap Type"
			(
				radiobuttons mapType labels:#("3ds Max Bitmap", "Custom Bitmap")
			)
			label lblNote "Note:" align:#left
			label lblNoteDesc "Custom maps won't render in max!" align:#left height:30
			
			button bOK "OK" across:2
			button bCancel "Cancel"
			
			on bOK pressed do
			(
				case mapType.state of
				(
					1:	mapui.mapSet = #maxmap
					2: mapui.mapSet = #custom
				)
				
				Destroydialog mapPick
			)
			on bCancel pressed do
			(
				mapui.mapSet = undefined
				Destroydialog mapPick
			)
		)
	
		on mapui open do
		(
			if (scCustomMap.count > 0) then
			(
				btnBitmap.text = scCustomMap
				btnViewImage.enabled = false
			)
			else
			(
				if (scbitmap != undefined) then
				(
					btnBitmap.text = scbitmap.filename
					btnViewImage.enabled = true
				)
				else btnBitmap.text = "None"
			)
		)
		on btnBitmap pressed do
		(
			local newPos = mouse.screenpos
			newPos.x -= 85
			newPos.y -= 95
			if (createDialog mapPick modal:true pos:newPos width:185) then
			(
				case mapui.mapSet of
				(
					#maxmap:
					(
						local map = assign_bitmap()
						if (map != undefined) then
						(
							this.scbitmap = map
							this.scCustomMap = ""
							btnBitmap.text = this.scbitmap.filename
							btnViewImage.enabled = true
						)
					)
					#custom: 
					(
						sc2uiOpenFile "OGV Movie Files (*.ogv)|*.ogv|All Files|*.*|" &scCustomMap
						if (scCustomMap.count > 0) then 
						(
							if (this.scbitmap != undefined) then 
							(
								local tBitMap 
								--tBitMap.filename = ""
								--this.scbitmap = tBitMap
								delegate.filename = ""
							)
							btnBitmap.text = scCustomMap
							btnViewImage.enabled = false
						)
					)
				)
			)
		)
		on btnViewImage pressed do
		(
			if (scbitmap != undefined) then
			(
				display scbitmap
			)
		)
		on mapui reload do
		(
			if (scCustomMap.count > 0) then
			(
				btnBitmap.text = scCustomMap
				btnViewImage.enabled = false
			)
			else
			(
				if (scbitmap != undefined) then
				(
					btnBitmap.text = scbitmap.filename
					btnViewImage.enabled = true
				)
				else btnBitmap.text = "None"
			)
		)
	)--end rollout
	
	rollout mapsettui "Map Settings"
	(
		group "General Properties"
		(
			spinner spnBright_Mult "Brightness Multiplier" default:1.0 scale:0.1 width:85 align:#left
		)
		
		group "UV Coordinates"
		(
			spinner spnMapChannel "Map Channel:" type:#integer fieldWidth:45 align:#left range:[1,100,1] enabled:false
			
			label lblOffset "Offset" align:#left offset:[25, 0] across:3
			label lblTiling "Tiling" align:#left offset:[5,0]
			label lblTile "Tile" align:#left offset:[-37,0]
			
			label lblU "U:" across:4 align:#left
			spinner spnU_Offset "" type:#float default:1.0 scale:0.1 width:60 align:#left offset:[-60, 0] range:[-1e9, 1e9, 0]
			spinner spnU_Tiling "" type:#float default:1.0 scale:0.1 width:60 align:#left offset:[-60, 0] range:[-1e9, 1e9, 0]
			checkbox chkU_Tile "" checked:true align:#left offset:[-60, 0]
			
			label lblV "V:" across:4 align:#left width:10
			spinner spnV_Offset "" type:#float default:1.0 scale:0.1 width:60 align:#left offset:[-60, 0] range:[-1e9, 1e9, 0]
			spinner spnV_Tiling "" type:#float default:1.0 scale:0.1 width:60 align:#left offset:[-60, 0] range:[-1e9, 1e9, 0]
			checkbox chkV_Tile "" checked:true align:#left offset:[-60, 0]
		)
		
		fn set_decal =
		(
			if (this.isDecal == true) then
			(
				if (this.isCreated != true) then
				(
					this.mapChannel = 2
					--this.TexWrap = false
					this.TeamColour = true
					this.isCreated = true
				)
				spnMapChannel.enabled = true
			)
		)
		
		on mapsettui open do
		(
			set_decal()
		)
		on mapsettui reload do
		(
			set_decal()
		)
	)
	
	rollout alphasettui "Alpha Settings"
	(
		group "Alpha Flags"
		(
			checkbox chkTeamColour "Render Alpha as Team Colour" align:#left across:2
			checkbox chkTexAlphaOnly "Render Alpha Only" checked:false align:#right
		)	
		
		on chkTexAlphaOnly changed state do
		(
			if (state == false) then
			(
				chkTeamColour.enabled = true
			)
			else
			(
				chkTeamColour.checked = false
				chkTeamColour.enabled = false
			)
		)
		on mapsettui open do
		(
			if (chkTexAlphaOnly.checked == true) then
			(
				chkTeamColour.checked = false
				chkTeamColour.enabled = false
			)
		)
		on mapsettui reload do
		(
			if (chkTexAlphaOnly.checked == true) then
			(
				chkTeamColour.checked = false
				chkTeamColour.enabled = false
			)			
		)		
	)
	
	on create do
	(
		alphaSetup()
		
		if (this.isDecal == true) then
		(
			this.mapChannel = 2
			--this.TexWrap = false
			this.TeamColour = true
		)
	)
	
	on update do
	(
		if (version < 4) then
		(
			this.isCreated = false
			this.isDecal = false
			this.mapChannel = 1
		)
		
		if (version < 5) then
		(
			if (delegate.coords.U_Tile == true) then this.U_Tile = true else this.U_Tile = false
			if (delegate.coords.V_Tile == true) then this.V_Tile = true else this.V_Tile = false
			
			if (delegate.bitmap != undefined) then
			(
				this.scbitmap = delegate.bitmap
			)
		)
	)
)--end plugin

global sc2att_size = 0.05
global sc2att_rad = 0.2
global sc2att_id = ""
global sc2att_colour = green

plugin Helper sc2attachment
name:"Attachment"
classID:#(0x2e993b39, 0x43824ff0)
category:"Starcraft 2 Objects"
extends:Dummy
version:4
(
	local AttachIDlist = #("Custom", "Ref_Center", "Ref_Damage", "Ref_Hardpoint", "Ref_Head", "Ref_Hit", "Ref_Origin", "Ref_Overhead", "Ref_Shield", "Ref_Target", "Ref_Weapon", "Ref_Weapon Left", "Ref_Weapon Right")
	local meshObj, meshPyr, meshSph, lastSize, meshNode, lastRad 
	
	fn getOwners =
	(
		for o in refs.dependents this where isValidNode o collect o
	)
	
	parameters main rollout:mainui
	(
		boxSize type:#float ui:spnBoxSize
		
		on boxSize set val do
		(
			sc2att_size = val
		)
	)
	
	parameters attachsett rollout:attachsettui
	(
		attachID type:#integer ui:ddlAttachID
		attachName type:#string ui:edtAttachID
		attachRadius type:#float ui:spnAttachRad
		showVolume type:#boolean ui:cbnShowVolume
		
		on attachID set val do
		(
			if (val > 1) then
			(
				attachName = AttachIDlist[val]
			)
		)
		on attachName set val do
		(
			if (val != "" and val != undefined) then
			(
				local attInd = findItem AttachIDlist val
				if (attInd < 2) then 
				(
					attachID = 1 
				)
				else 
				(
					attachID = attInd
				)
				sc2att_id = val
			)
			else
			(
				attachID = 1
			)
		)
		on attachRadius set val do
		(
			sc2att_rad = val
		)
	)
	
	rollout mainui "Helper Parameters"
	(
		spinner spnBoxSize "Size:" range:[0, 1e9, sc2att_size] type:#float scale:0.01
	)
	
	rollout attachsettui "Attachment Parameters"
	(
		group "Select Attachment ID"
		(
			dropdownlist ddlAttachID items:AttachIDlist
		)
		edittext edtAttachID "Attachment ID:" labelOnTop:true
		group "Attachment Volume"
		(
			spinner spnAttachRad "Radius" enabled:false align:#left type:#float scale:0.01 range:[0, 1e9, sc2att_rad]
			checkButton cbnShowVolume "Show Volume" 
		)
		
		fn spnRadOnOff val =
		(
			if ((matchPattern val pattern:"Ref_Target*") or (matchPattern val pattern:"Ref_Shield*")) then
			(
				spnAttachRad.enabled = true
				cbnShowVolume.enabled = true
			)
			else
			(
				spnAttachRad.enabled = false
				cbnShowVolume.enabled = false
				showVolume = false
			)
		)
		
		on ddlAttachID selected i do
		(
			if (i > 1) then
			(
				edtAttachID.text = ddlAttachID.selected
			)
			-- need to call the function to activate spinner if target/shield selected from dropdownlist
			edtAttachID.entered ddlAttachID.selected
		)
		on edtAttachID entered val do
		(
			local attInd = findItem AttachIDlist val
			if (attInd < 2) then ddlAttachID.selection = 1 else ddlAttachID.selection = attInd
			spnRadOnOff val
		)
		on attachsettui open do
		(
			if (edtAttachID.text != "" and edtAttachID.text != undefined) then
			(
				local attInd = findItem AttachIDlist edtAttachID.text
				if (attInd < 2) then ddlAttachID.selection = 1 else ddlAttachID.selection = attInd
			)
			edtAttachID.entered edtAttachID.text
		)
	)
	
	on getDisplayMesh do
	(
		if (showVolume == true) then
		(
			if (meshSph == undefined) then
			(
				meshSph = createInstance sphere radius:attachRadius mapCoords:false
				lastRad = attachRadius
			)
		)
		else
		(
			if (meshPyr == undefined) then
			(
				meshPyr = createInstance pyramid depth:boxSize width:boxSize height:(boxSize * 2) mapCoords:false
				lastSize = boxSize
			)
		)
		
		if ((boxSize != lastSize) and (this.showVolume == false)) then
		(
			meshPyr.depth = meshPyr.width = boxSize
			meshPyr.height = boxSize * 2
			lastSize = boxSize
		)
		
		if ((attachRadius != lastRad) and (this.showVolume == true)) then
		(
			meshSph.radius = attachRadius
			lastRad = attachRadius
		)
		
		if (this.showVolume == true) then
		(
			return meshSph.mesh
		)
		else
		(
			return meshPyr.mesh
		)
	)
	
	on create do
	(
		boxSize = sc2att_size
		attachName = sc2att_id
		attachRadius = sc2att_rad
	)

	tool create 
	( 
		on mousePoint click do 
		(
			if click == 1 then 
			(
				nodeTM.translation = gridPoint
				meshNode = getOwners()
				meshNode.wirecolor = sc2att_colour
				--delegate.boxsize = [boxSize, boxSize, boxSize]
			)
			else #stop
		)
	) 
)

global sc2par_size = 0.08
global sc2par_colour = red
global sc2par_varOld = #(#unk16X, #unk16Y, #unk16Z)
global sc2par_varNew = #(#scale2start, #scale2end, #scale2spread)
	
plugin Helper sc2pemitter
name:"PEmitter"
classID:#(0x512a1e2f, 0x344d0698)
category:"Starcraft 2 Objects"
extends:Dummy
version:1
remap:#(sc2par_varOld, sc2par_varNew)
(
	local mainui, pemitsettui, pemitflagsui, pemitunkui -- ui definitions
	local pemitTypeList = #("Point", "Plane", "Sphere", "Box", "Cylinder (1)", "Disc", "Spline", "Planar Billboard", "Planar", "Cylinder (2)", "Starshaped")
	local lastSize, meshObj, meshNode, mUI, pUI, puUI, pfUI
	
	fn getOwners =
	(
		for o in refs.dependents this where isValidNode o collect o
	)
	
	fn SetColP4 p4 =
	(
		local col
		col = color 0 0 0 0
		col.blue = p4.x
		col.green = p4.y
		col.red = p4.z
		col.alpha = p4.w
		
		return col
	)
	
	fn SetByteCol val =
	(
		local ret
		if val > 255 then ret = val / 255 else ret = val
		return ret
	)
	
	fn SetP4Col col =
	(
		local p4 = [0, 0, 0, 0]
		p4.x = SetByteCol col.blue
		p4.y = SetByteCol col.green
		p4.z = SetByteCol col.red
		p4.w = SetByteCol col.alpha
		
		return p4
	)
	
	parameters main rollout:mainui
	(
		boxSize type:#float ui:spnBoxSize
		
		on boxSize set val do
		(
			sc2par_size = val
		)
	)
	
	parameters pemitsett rollout:pemitsettui
	(
		pMaterial type:#material ui:mtlPemitMaterial
		
		-- Particle Settings Group
		columns type:#integer ui:spnColumns
		rows type:#integer ui:spnRows
		
		type type:#integer ui:ddlPemitType default:1
		enableStreak type:#boolean ui:chkEnableStreak
		enableTrailing type:#boolean ui:chkEnableTrailing		
		minParticles type:#integer ui:spnMinParticles
		maxParticles type:#integer ui:spnMaxParticles
		
		lifespan type:#float ui:spnLifeSpan animatable:true
		enableDecay type:#boolean ui:chkEnableDecay
		decay type:#float ui:spnDecay animatable:true
		pivotSpread type:#float ui:spnPivotSpread animatable:true
		
		pemitScaleStart type:#float ui:spnScaleStart animatable:true
		pemitScaleEnd type:#float ui:spnScaleEnd animatable:true
		pemitScaleSpread type:#float ui:spnScaleSpread animatable:true
		
		enablePemitRotate type:#boolean ui:chkEnablePemitRotate
		pemitRotateSpread1 type:#float ui:spnRotateSpread1 animatable:true
		pemitRotateSpread2 type:#float ui:spnRotateSpread2 animatable:true
		pemitRotateSpinSpeed type:#float ui:spnRotateSpinSpeed animatable:true
		
		-- Emission Settings Group
		enableRadialEmission type:#boolean ui:chkEnableRadialEmission
		initEmissSpeed type:#float ui:spnInitEmissSpeed animatable:true
		enableSpeedVar type:#boolean ui:chkEnableSpeedVar
		speedVar type:#float ui:spnSpeedVar animatable:true
		rate type:#float ui:spnRate animatable:true
		partEmit type:#integer ui:spnPartEmit animatable:true
		
		pemitAreaWidth type:#float ui:spnAreaWidth animatable:true
		pemitAreaLength type:#float ui:spnAreaLength animatable:true
		pemitAreaSpread type:#float ui:spnAreaSpread animatable:true
		
		emissSpreadX type:#float ui:spnEmissSpreadX animatable:true
		emissSpreadY type:#float ui:spnEmissSpreadY animatable:true
		emissAngleX type:#float ui:spnEmissAngleX animatable:true
		emissAngleY type:#float ui:spnEmissAngleY animatable:true
		
		colour1start type:#point4 default:[1.0, 1.0, 1.0, 1.0] animatable:true
		colour1mid type:#point4 default:[1.0, 1.0, 1.0, 1.0] animatable:true
		colour1end type:#point4 default:[1.0, 1.0, 1.0, 1.0] animatable:true
		
		on colour1start set val do (pemitsettui.clpCol1Start.color = SetColP4 val)
		on colour1mid set val do (pemitsettui.clpCol1Mid.color = SetColP4 val)
		on colour1end set val do (pemitsettui.clpCol1End.color = SetColP4 val)
		
		enableColour2 type:#boolean ui:chkEnableCol2
		colour2start type:#point4 default:[1.0, 1.0, 1.0, 1.0] animatable:true
		colour2mid type:#point4 default:[1.0, 1.0, 1.0, 1.0] animatable:true
		colour2end type:#point4 default:[1.0, 1.0, 1.0, 1.0] animatable:true
		
		on colour2start set val do (pemitsettui.clpCol2Start.color = SetColP4 val)
		on colour2mid set val do (pemitsettui.clpCol2Mid.color = SetColP4 val)
		on colour2end set val do (pemitsettui.clpCol2End.color = SetColP4 val)
	)
	
	parameters pemitflags rollout:pemitflagsui
	(
		sort type:#boolean ui:chkSort
		collideTerrain type:#boolean ui:chkCollideTerrain
		collideObjects type:#boolean ui:chkCollideObjects
		spawnOnBounce type:#boolean ui:chkSpawnOnBounce
		useInnerShape type:#boolean ui:chkUseInnerShape
		inheritEmissionParams type:#boolean ui:chkInheritEmissionParams
		inheritParentVel type:#boolean ui:chkInheritParentVel
		sortByZHeight type:#boolean ui:chkSortByZHeight
		reverseIteration type:#boolean ui:chkReverseIteration
		smoothRotation type:#boolean ui:chkSmoothRotation
		bezSmoothRotation type:#boolean ui:chkBezSmoothRotation
		smoothSize type:#boolean ui:chkSmoothSize
		bezSmoothSize type:#boolean ui:chkBezSmoothSize
		smoothColour type:#boolean ui:chkSmoothColour
		bezSmoothColour type:#boolean ui:chkBezSmoothColour
		litParts type:#boolean ui:chkLitParts
		randFlipBookStart type:#boolean ui:chkRandFlipBookStart
		multiplyByGravity type:#boolean ui:chkMultiplyByGravity
		clampTailParts type:#boolean ui:chkClampTailParts
		spawnTrailingParts type:#boolean ui:chkSpawnTrailingParts
		fixLengthTailParts type:#boolean ui:chkFixLengthTailParts
		useVertexAlpha type:#boolean ui:chkUseVertexAlpha
		modelParts type:#boolean ui:chkModelParts
		swapYZonModelParts type:#boolean ui:chkSwapYZonModelParts
		scaleTimeByParent type:#boolean ui:chkScaleTimeByParent
		useLocalTime type:#boolean ui:chkUseLocalTime
		simulateOnInit type:#boolean ui:chkSimulateOnInit
		copy type:#boolean ui:chkCopy
	)
	
	parameters pemitunk rollout:pemitunkui
	(
		emissSpeed1 type:#float ui:spnEmissSpeed1
		emissSpeed2 type:#float ui:spnEmissSpeed2
		
		emissSpeed3X type:#float ui:spnEmissSpeed3X animatable:true
		emissSpeed3Y type:#float ui:spnEmissSpeed3Y animatable:true
		emissSpeed3Z type:#float ui:spnEmissSpeed3Z animatable:true
		
		speedUnk1X type:#float ui:spnSpeedUnk1X
		speedUnk1Y type:#float ui:spnSpeedUnk1Y
		speedUnk1Z type:#float ui:spnSpeedUnk1Z
		speedUnk1W type:#float ui:spnSpeedUnk1W
		
		enableScale2 type:#boolean ui:chkEnableScale2
		scale2start type:#float ui:spnScale2Start animatable:true
		scale2end type:#float ui:spnScale2End animatable:true
		scale2spread type:#float ui:spnScale2Spread animatable:true
		
		scaleRatio type:#float ui:spnScaleRatio
		lifespanRatio type:#float ui:spnLifespanRatio
		
		tailUnkX type:#float ui:spnTailUnkX animatable:true
		tailUnkY type:#float ui:spnTailUnkY animatable:true
		tailUnkZ type:#float ui:spnTailUnkZ animatable:true
		
		spreadUnk type:#float ui:spnSpreadUnk animatable:true
		
		unk1 type:#float ui:spnUnk1
		unk2 type:#float ui:spnUnk2
		unk3 type:#float ui:spnUnk3
		unk4 type:#float ui:spnUnk4
		unk5 type:#float ui:spnUnk5
		unk6 type:#float ui:spnUnk6
		unk7 type:#float ui:spnUnk7
		unk8 type:#float ui:spnUnk8
		unk9 type:#float ui:spnUnk9
		unk10 type:#float ui:spnUnk10
		unk11 type:#float ui:spnUnk11
		unk12 type:#float ui:spnUnk12
		unk13 type:#float ui:spnUnk13
		unk14 type:#float ui:spnUnk14
		unk15 type:#float ui:spnUnk15 animatable:true
	)
	
	rollout mainui "Helper Parameters"
	(
		spinner spnBoxSize "Size:" range:[0, 1e9, sc2par_size] type:#float scale:0.01
	)
	
	rollout pemitsettui "Particle Parameters"
	(
		group "Material Settings"
		(
			label lblPickMaterial "Particle Material:"
			materialButton mtlPemitMaterial "Pick Material"
			
			spinner spnColumns "Columns" type:#integer fieldWidth:36 align:#right
			spinner spnRows "Rows" type:#integer fieldWidth:36 align:#right
		)
		
		group "Particle Settings"
		(
			dropdownlist ddlPemitType "Particle Type:" items:pemitTypeList labelOnTop:true
			spinner spnMinParticles "Min. Particles" type:#integer fieldWidth:40 align:#right
			spinner spnMaxParticles "Max. Particles" type:#integer fieldWidth:40 align:#right
			checkbox chkEnableStreak "Enable Particle Streaks" align:#right
			checkbox chkEnableTrailing "Enable Particle Trailing" align:#right		

			label lblSpacer1 "" -- spacer

			spinner spnLifeSpan "Lifespan" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			checkbox chkEnableDecay "Enable Decay" align:#right
			spinner spnDecay "Decay" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnPivotSpread "Pivot Spread" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			
			label lblScale "Scale:"
			spinner spnScaleStart "Start" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnScaleEnd "End" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnScaleSpread "Spread" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			
			checkbox chkEnablePemitRotate "Enable Rotate" align:#right
			label lblRotate "Rotate:"
			spinner spnRotateSpread1 "Spread 1" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0] 
			spinner spnRotateSpread2 "Spread 2" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnRotateSpinSpeed "Spin Speed" type:#float fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
		)
		
		group "Emission Settings"
		(
			checkbox chkEnableRadialEmission "Enable Radial Emission" align:#right
			
			label lblSpacer2 ""
			
			spinner spnInitEmissSpeed "Initial Speed" type:#float scale:0.01 fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			checkbox chkEnableSpeedVar "Enable Speed Variation" align:#right
			spinner spnSpeedVar "Speed Variation" type:#float scale:0.01 fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnRate "Rate" type:#float scale:0.01 fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnPartEmit "*Particles Emitted" type:#integer fieldWidth:40 align:#right range:[0, 65535, 0]
			label lblPartEmit "*Note: has to be keyed" align:#right
			
			label lblSpacer3 "" -- spacer
			
			label lblArea "Area:"
			spinner spnAreaWidth "Width" type:#float scale:0.01 fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnAreaLength "Length" type:#float scale:0.01 fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
			spinner spnAreaSpread "Spread" type:#float scale:0.01 fieldWidth:40 align:#right range:[-1e9, 1e9, 0]
				
			label lblSpread "Spread:" align:#left
			spinner spnEmissSpreadX "X" type:#float scale:0.01 fieldWidth:40 range:[-1e9, 1e9, 0] across:2
			spinner spnEmissSpreadY "Y" type: #float scale:0.01 fieldWidth:40 range:[-1e9, 1e9, 0]
			
			label lblAngle "Angle:" align:#left
			spinner spnEmissAngleX "X" type:#float scale:0.01 fieldWidth:40 range:[-1e9, 1e9, 0] across:2
			spinner spnEmissAngleY "Y" type: #float scale:0.01 fieldWidth:40 range:[-1e9, 1e9, 0]
		)
		
		group "Particle Colour"
		(
			label lblCol1 "Colour 1" align:#left
			label lblCol1Start "Start" across:3
			label lblCol1Mid "Middle"
			label lblCol1End "End"
			
			colorPicker clpCol1Start alpha:true color:[255,255,255] fieldWidth:30 height:30 across:3
			colorPicker clpCol1Mid alpha:true color:[255,255,255] fieldWidth:30 height:30 
			colorPicker clpCol1End alpha:true color:[255,255,255] fieldWidth:30 height:30
			
			on clpCol1Start changed val do (colour1start = SetP4Col val)
			on clpCol1Mid changed val do (colour1mid = SetP4Col val)
			on clpCol1End changed val do (colour1end = SetP4Col val)
			
			label lblCol2 "Colour 2" align:#left
			checkBox chkEnableCol2 "Enable Colour 2" align:#left
			label lblCol2Start "Start" across:3
			label lblCol2Mid "Middle"
			label lblCol2End "End"
			
			colorPicker clpCol2Start alpha:true color:[255,255,255] fieldWidth:30 height:30 across:3
			colorPicker clpCol2Mid alpha:true color:[255,255,255] fieldWidth:30 height:30
			colorPicker clpCol2End alpha:true color:[255,255,255] fieldWidth:30 height:30
			
			on clpCol2Start changed val do (colour2start = SetP4Col val)
			on clpCol2Mid changed val do (colour2mid = SetP4Col val)
			on clpCol2End changed val do (colour2end = SetP4Col val)
		)
		
		fn setColour2Status val =
		(
			if (val == true) then
			(
				-- labels
				lblCol2Start.enabled = true
				lblCol2Mid.enabled = true
				lblCol2End.enabled = true
				
				-- colour pickers
				clpCol2Start.enabled = true
				clpCol2Mid.enabled = true
				clpCol2End.enabled = true
			)
			else
			(
				-- labels
				lblCol2Start.enabled = false
				lblCol2Mid.enabled = false
				lblCol2End.enabled = false
				
				-- colour pickers
				clpCol2Start.enabled = false
				clpCol2Mid.enabled = false
				clpCol2End.enabled = false				
			)
		)
		
		-- enable settings
		on chkEnableDecay changed val do
		(
			if (val == true) then 
			(
				spnDecay.enabled = true
			)
			else
			(
				spnDecay.enabled = false
			)
		)
		
		on chkEnablePemitRotate changed val do
		(
			if (val == true) then
			(
				lblRotate.enabled = true
				spnRotateSpread1.enabled = true
				spnRotateSpread2.enabled = true
				spnRotateSpinSpeed.enabled = true
			)
			else
			(
				lblRotate.enabled = false
				spnRotateSpread1.enabled = false
				spnRotateSpread2.enabled = false
				spnRotateSpinSpeed.enabled = false
			)
		)
		
		on chkEnableSpeedVar changed val do
		(
			if (val == true) then
			(
				spnSpeedVar.enabled = true
			)
			else
			(
				spnSpeedVar.enabled = false
			)
		)
		
		on chkEnableCol2 changed val do
		(
			setColour2Status val
		)
		
		on pemitsettui open do
		(
			-- setup colour pickers
			chkEnableCol2.changed this.enableColour2
			
			-- colour1
			pemitsettui.clpCol1Start.color = this.colour1start
			pemitsettui.clpCol1Mid.color = this.colour1mid
			pemitsettui.clpCol1End.color = this.colour1end
			
			-- colour2
			pemitsettui.clpCol2Start.color = this.colour2start
			pemitsettui.clpCol2Mid.color = this.colour2mid
			pemitsettui.clpCol2End.color = this.colour2end
			
			-- setup UI bools
			chkEnableDecay.changed this.enableDecay
			chkEnablePemitRotate.changed this.enablePemitRotate
			chkEnableSpeedVar.changed this.enableSpeedVar
		)
	)
	
	rollout pemitunkui "Unknown Particle Settings" rolledUp:true
	(
		group "Emission"
		(
			spinner spnEmissSpeed1 "Speed 1" type:#float range:[-1e9, 1e9, 0] scale:0.1 fieldWidth:40 
			spinner spnEmissSpeed2 "Speed 2" type:#float range:[-1e9, 1e9, 0] scale:0.1 fieldWidth:40 
			
			label lblEmissSpeed3 "Speed 3:"
			spinner spnEmissSpeed3X "X" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:42 align:#right
			spinner spnEmissSpeed3Y "Y" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:42 align:#right
			spinner spnEmissSpeed3Z "Z" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:42 align:#right
			
			label lblSpeedUnk1 "Speed Unknown:" align:#left
			spinner spnSpeedUnk1X "X" type:#float scale:0.01 fieldWidth:40 across:2 range:[0,1,0]
			spinner spnSpeedUnk1Y "Y" type: #float scale:0.01 fieldWidth:40 range:[0,1,0]
			spinner spnSpeedUnk1Z "Z" type:#float scale:0.01 fieldWidth:40 across:2 range:[0,1,0]
			spinner spnSpeedUnk1W "W" type: #float scale:0.01 fieldWidth:40 range:[0,1,0]
			
			checkBox chkEnableScale2 "Enable Scale 2" align:#right
			label lblScale2 "Scale 2:"
			spinner spnScale2Start "Start" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:40 align:#right
			spinner spnScale2End "End" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:40 align:#right
			spinner spnScale2Spread "Spread" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:40 align:#right
		)
		
		group "Miscellaneous"
		(
			spinner spnScaleRatio "Scale Ratio" type:#float scale:0.1 range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnLifespanRatio "Lifespan Ratio" type:#float scale:0.1 range:[-1e9, 1e9, 0] fieldWidth:40
			
			label lblTailUnk "Tail:"
			spinner spnTailUnkX "X" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:40 align:#right 
			spinner spnTailUnkY "Y" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:40 align:#right
			spinner spnTailUnkZ "Z" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:40 align:#right
			
			label lblSpreadUnk "Spread 1:" align:#left
			spinner spnSpreadUnk "Spread 2:" type:#float animatable:true scale:0.1 range:[-1e9, 1e9, 0] fieldWidth:40
		)
		
		group "Unknown Values"
		(
			spinner spnUnk1 "1:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40 across:2
			spinner spnUnk2 "2:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnUnk3 "3:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40 across:2
			spinner spnUnk4 "4:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnUnk5 "5:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40 across:2
			spinner spnUnk6 "6:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnUnk7 "7:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40 across:2
			spinner spnUnk8 "8:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnUnk9 "9:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40 across:2
			spinner spnUnk10 "10:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnUnk11 "11:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40 across:2
			spinner spnUnk12 "12:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnUnk13 "13:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40 across:2
			spinner spnUnk14 "14:" type:#float range:[-1e9, 1e9, 0] fieldWidth:40
			spinner spnUnk15 "15:" type:#float animatable:true range:[-1e9, 1e9, 0] fieldWidth:40
		)
		
		on chkEnableScale2 changed val do
		(
			if (val == true) then
			(
				lblScale2.enabled = true
				spnScale2Start.enabled = true
				spnScale2End.enabled = true
				spnScale2Spread.enabled = true
			)
			else
			(
				lblScale2.enabled = false
				spnScale2Start.enabled = false
				spnScale2End.enabled = false
				spnScale2Spread.enabled = false
			)
		)
		
		on pemitunkui open do
		(
			-- setup UI bools
			chkEnableScale2.changed this.enableScale2
		)
	)
	
	rollout pemitflagsui "Particle Flags" rolledUp:true
	(
		checkBox chkSort "Sort"
		checkBox chkCollideTerrain "Collide Terrain"
		checkBox chkCollideObjects "Collide Objects"
		checkBox chkSpawnOnBounce "Spawn On Bounce"
		checkBox chkUseInnerShape "Use Inner Shape"
		checkBox chkInheritEmissionParams "Inherit Emission Parameters"
		checkBox chkInheritParentVel "Inherit Parent Velocity"
		checkBox chkSortByZHeight "Sort By Z Height"
		checkBox chkReverseIteration "Reverse Iteration"
		checkBox chkSmoothRotation "Smooth Rotation"
		checkBox chkBezSmoothRotation "Bezier Smooth Rotation"
		checkBox chkSmoothSize "Smooth Size"
		checkBox chkBezSmoothSize "Bezier Smooth Size"
		checkBox chkSmoothColour "Smooth Colour"
		checkBox chkBezSmoothColour "Bezier Smooth Colour"
		checkBox chkLitParts "Lit Parts"
		checkBox chkRandFlipBookStart "Random Flipbook Start"
		checkBox chkMultiplyByGravity "Multiply By Gravity"
		checkBox chkClampTailParts "Clamp Tail Parts"
		checkBox chkSpawnTrailingParts "Spawn Trailing Parts"
		checkBox chkFixLengthTailParts "Fix Length Tail Parts"
		checkBox chkUseVertexAlpha "Use Vertex Alpha"
		checkBox chkModelParts "Model Parts"
		checkBox chkSwapYZonModelParts "Swap YZ On Model Parts"
		checkBox chkScaleTimeByParent "Scale Time By Parent"
		checkBox chkUseLocalTime "Use Local Time"
		checkBox chkSimulateOnInit "Simulate On Init"
		checkBox chkCopy "Copy"
	)
	
	on getDisplayMesh do
	(
		if (meshObj == undefined) then
		(
			meshObj = createInstance pyramid depth:boxSize width:boxSize height:boxSize mapCoords:false 
			lastSize = boxSize
		)
		
		if (boxSize != lastSize) then
		(
			meshObj.depth = meshObj.width = meshObj.height = boxSize 
			lastSize = boxSize
		)

		meshObj.mesh
	)
	
	on create do
	(
		boxSize = sc2par_size
	)

	tool create 
	( 
		on mousePoint click do 
		(
			if click == 1 then 
			(
				nodeTM.translation = gridPoint
				meshNode = getOwners()
				meshNode.wirecolor = sc2par_colour
			)
			else #stop
		)
	) 
)

-- global sc2bndsph_rad = 0.1
global sc2bndsph_colour = (color 6 134 58) -- dark green

plugin Helper sc2boundsphere
name:"Bound Sphere"
classID:#(0x5bd5a942, 0x5b0e266)
category:"Starcraft 2 Objects"
extends:Dummy
version:1
(
	local meshObj, lastRad, lastScale, meshNode
	
	fn getOwners =
	(
		for o in refs.dependents this where isValidNode o collect o
	)
	
	parameters main rollout:mainui
	(
		bndRadius type:#float ui:spnRadius default:0.0 animatable:true
		
		on bndRadius set val do
		(
			-- sc2bndsph_rad = val
		)
	)
	
	rollout mainui "Sphere Parameters"
	(
		spinner spnRadius "Radius:" range:[0, 1e9, 0.0] type:#float scale:0.01
	)
	
	on getDisplayMesh do
	(
		if (meshObj == undefined) then
		(
			meshObj = createInstance sphere radius:bndRadius mapCoords:false
			lastRad = bndRadius
		)
		
		if (radius != lastRad) then
		(
			meshObj.radius = bndRadius
			lastRad = bndRadius
		)
		
		meshObj.mesh
	)
	
	tool create 
	( 
		on mousePoint click do 
		(
			if click == 1 then
			(
				nodeTM.translation = gridPoint
				meshNode = getOwners()
				meshNode.wirecolor = sc2bndsph_colour
			) else #stop
		)
		on mouseMove click do
		(
			local lrgDist = 0.0

			for i = 1 to 3 do
			(
				if (lrgDist < GridDist[i]) then lrgDist = GridDist[i]
			)

			bndRadius = lrgDist
		)
	) 
)

-- ********************
--  M3 UI ELEMENTS
-- ********************
-- Animation UI dependents
struct sc2anim
(
	-- Default values incase not found
	name = "Stand", seqInd = 0, 
	cstart = 0, cend = 1000, 
	freq = 100, moveSpeed = 0, looping = false
)

fn sc2_AnimToStrm anim =
(
	local ss = stringStream ""
	format ".name:%\n" anim.name to:ss
	format ".seqInd:%\n" anim.seqInd to:ss
	format ".cstart:%\n" anim.cstart to:ss
	format ".cend:%\n" anim.cend to:ss
	format ".freq:%\n" anim.freq to:ss
	format ".moveSpeed:%\n" anim.moveSpeed to:ss
	format ".looping:%\n" anim.looping to:ss
	return ss
)

fn sc2_Set_Scene_Data obj animdata =
(
	local aheader = stringstream ""
	format ".version:%\n" SC2PLUGIN_VERS to:aheader
	format ".count:%\n" animdata.count to:aheader
	setAppData obj 1 aheader
	for i = 1 to animdata.count do
	(
		local aind = i + 1
		local ad = animdata[i]
		
		local adss = sc2_AnimToStrm ad
		setAppData obj aind adss
	)
)

fn sc2_Get_ssData stringStrm property type:#value =
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

fn sc2_Get_AnimData animss sc2Vers =
(
	local anim = sc2anim()
	
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
				anim.freq		= sc2_Get_ssData animss ".freq:"
				anim.moveSpeed = sc2_Get_ssData animss ".moveSpeed:"
				anim.looping	= sc2_Get_ssData animss ".looping:" type:#boolean
			)
		)
	)
	else
	(
		anim.freq			= 100
		anim.moveSpeed 	= 0.0
		anim.looping		= false
	)
	
	return anim
)

-- Animation UI
utility sc2animUI "M3 - Sequences"
(
	local animList = #("None")
	local aobj = $_M3_Anim_Data
	local aObjClass = classOf aobj as string
	local adata = #()
	
	Group "Select Animation"
	(
		dropdownlist	dlAnim items:#("None")
	)
	
	Group "Edit"
	(
		edittext		edtAnimName "Animation Name:" labelOnTop:true enabled:false
		spinner			spnSeqInd "Sequence Index:" range:[0,1e9,0] type:#integer width:125 align:#right enabled:false
		label				lblAnimRange "Animation Ranges" align:#left offset:[0,10]
		spinner			spnStart "Time Start:" range:[0,1e9,0] type:#integer enabled:false
		spinner			spnEnd "Time End:" range:[0,1e9,0] type:#integer enabled:false
		spinner			spnFreq "Frequency (%):" range:[0,100,100] type:#integer enabled:false fieldwidth:50
		spinner			spnMoveSpeed "Move Speed:" range:[0,1e6,0] type:#float enabled:false scale:1
		checkbox		chkLooping "Looping" align:#right enabled:false
		label				lblSpacer1 height:5
		button btnAdd "Add" align:#left across:2 width:60
		button btnRemove "Remove" align:#right enabled:false
	)
	
	fn NoneSelected =
	(
		if (adata.count > 0) then 
		(
			local lastFrame = 0
			for i = 1 to adata.count do
			(
				local ad = adata[i]
				if ad.cend > lastFrame then lastFrame = ad.cend
			)
			animationRange = interval 0 lastFrame
			spnEnd.value = lastFrame
		)
		else 
		(
			animationRange = interval 0 1000
			spnEnd.value = 1000
		)
		spnStart.value = 0
		
		-- Reset and disable UI elements
		edtAnimName.text = ""
		edtAnimName.enabled = false
		spnSeqInd.value = 0
		spnSeqInd.enabled = false
		spnStart.enabled = false
		spnEnd.enabled = false
		spnFreq.enabled = false
		spnMoveSpeed.enabled = false
		chkLooping.checked = false
		chkLooping.enabled = false
		btnRemove.enabled = false
	)
	
	fn Selected sel =
	(
		dlAnim.selection = sel

		if sel == 1 then 
		(
			NoneSelected()
		)
		else
		(
			local ad = adata[sel-1]
			animationRange = interval ad.cstart ad.cend
			sliderTime = ad.cstart
			edtAnimName.text = ad.name
			spnSeqInd.value = ad.seqInd
			spnStart.value = ad.cstart
			spnEnd.value = ad.cend
			spnFreq.value = ad.freq
			spnMoveSpeed.value = ad.moveSpeed
			chkLooping.checked = ad.looping
			
			-- Enable UI elements
			edtAnimName.enabled = true
			spnSeqInd.enabled = true
			spnStart.enabled = true
			spnEnd.enabled = true
			spnFreq.enabled = true
			spnMoveSpeed.enabled = true			
			chkLooping.enabled = true
			btnRemove.enabled = true
		)
	)
	
	fn List_Repop  =
	(
		animList = dlAnim.items
		animList = #("None")
		for i = 1 to adata.count do
		(
			ad = adata[i]
			--echo (anim_data[i].name)
			local aname = ad.name + ("["+ad.seqInd as string+"]")
			append animList aname
		)
		
		dlAnim.items = animList
	)
	
	fn List_Pop =
	(
		if (aobj != undefined and isValidNode aobj == true and aObjClass == "Point") then
		(	
			--reset vars
			adata = #()
			
			local acss = (getAppData aobj 1) as stringstream
			if (acss != undefined) then
			(
				local sc2Vers = sc2_Get_ssData acss ".version:"
				local animCount = sc2_Get_ssData acss ".count:"
				if (animCount != 0) then
				(
					adata[animCount] = 0
					for h = 1 to animCount do
					(
						local stcInd = h + 1
						local stcss = (getAppData aobj stcInd) as stringstream
						local anim = sc2_Get_AnimData stcss sc2Vers
						
						-- Update with new version data
						local animss = sc2_AnimToStrm anim
						
						setAppData aobj stcInd animss
						
						adata[h] = anim
					)
				)
				
				-- Update animation storage to current version
				-- (AppData) Update Animation Count
				local adss = stringstream ""
				format ".version:%\n" SC2PLUGIN_VERS to:adss
				format ".count:%\n" adata.count to:adss
				setAppData aobj 1 adss
				
				List_Repop()
			)
		)
	)
	
	fn UpdateEntry val entryid =
	(
		-- sanity check
		local aind = dlAnim.selection - 1
		if (aind > 0) then
		(
			-- grab AD
			local ad = adata[aind]
			objInd = aind + 1 -- obj index for replacing user data
			
			-- Set new value
			case entryid of
			(
				#name: ad.name = val
				#seqInd: ad.seqInd = val
				#cstart: ad.cstart = val
				#cend: ad.cend = val
				#freq: ad.freq = val
				#moveSpeed: ad.moveSpeed = val
				#looping: ad.looping = val
			)
			
			if (entryid == #cstart or entryid == #cend) then animationRange = interval ad.cstart ad.cend
			
			local adss = sc2_AnimToStrm ad
			-- Update app data
			setAppData aobj objInd adss
			
			-- Update UI data container
			adata[aind] = ad
			List_Repop() -- Refresh UI
		)
	)
	
	on sc2animUI open do
	(
		List_Pop()
		if (adata.count > 0) then
		(
			local standFound = 0
			for i = 1 to adata.count do
			(
				local ad = adata[i]
				local aname = ad.name
				if ((matchPattern aname pattern:"Stand") == true) then
				(
					standFound = i
				)
			)
			
			local dlsel = 1
			if (standFound > 0) then
			(
				dlsel = standFound
			)
			else
			(
				local rsel = random 1 adata.count
				dlsel = rsel
			)
			dlAnim.selection = dlsel + 1 -- skip "none" in array
			Selected dlAnim.selection
		)
	)
	on dlAnim selected i do
	(
		if (adata.count > 0) then
		(
			if (i == 1) then
			(
				NoneSelected()
			)
			else
			(
				Selected i
			)
		)
	)
	-- UI value updates
	on edtAnimName entered txt do (UpdateEntry txt #name)
	on spnSeqInd changed val do (UpdateEntry val #seqInd)
	on spnStart changed val do 
	(
		local nval
		if (val != spnEnd.value) then
		(
			nval = val
		)
		else
		(
			nval = val - 1
		)		
		UpdateEntry nval #cstart
		spnStart.value = nval
	)
	on spnEnd changed val do 
	(
		local nval
		if (val != spnStart.value) then
		(
			nval = val
		)
		else
		(
			nval = val + 1
		)
		UpdateEntry nval #cend
		spnEnd.value = nval
	)
	on spnFreq changed val do (UpdateEntry val #freq)
	on spnMoveSpeed changed val do (UpdateEntry val #moveSpeed)
	on chkLooping changed val do (UpdateEntry val #looping)
	on btnAdd pressed do
	(
		-- Create new animation data placeholder
		ad = sc2anim()
		if (adata.count > 0) then
		(
			ad.seqInd	= (adata[adata.count].seqInd) + 1
			ad.cstart 	= (adata[adata.count].cend as integer) + 1000
			ad.cend		= (ad.cstart as integer) + 1000
			ad.freq		= 100
			ad.moveSpeed = 0
			ad.looping = false
		)
		
		-- Append to UI animation data collection
		append adata ad
		local aObjClass = classOf aObj as string
		if (isValidNode aobj != true or aObjClass != "Point") then
		(
			-- Initiate Scene Object
			if ($_M3_Anim_Data != undefined) then delete($_M3_Anim_Data)
			-- Create scene object to house animation information
			local adObj = point size:0.001 pos:[0,0,0]
			adObj.name = "_M3_Anim_Data"
			adObj.renderable = off
			adObj.isHidden = true
			adObj.wirecolor = color 8 8 136
			
			aobj = adObj
		)
		-- (AppData) Update Animation Count
		local adss = stringstream ""
		format ".version:%\n" SC2PLUGIN_VERS to:adss
		format ".count:%\n" adata.count to:adss
		setAppData aobj 1 adss
		
		-- (AppData) Add Entry
		local adss = sc2_AnimToStrm ad
		local objInd = adata.count + 1
		setAppData aobj objInd adss
		
		-- update list
		List_Pop()
		Selected (adata.count + 1)
	)
	on btnRemove pressed do
	(
		local ind = dlAnim.selection - 1
		if (ind != 0) then
		(
			adata = deleteItem adata ind 
			sc2_Set_Scene_Data aobj adata -- Fix scene data
			
			-- Reset list and selection
			List_Pop()
			Selected ind
		)
	)
)

fn sc2animUIreset =
(
	-- Reset
	if (sc2animUI != undefined) do closeUtility sc2animUI
)

fn sc2bndSphCheck =
(
	local bndSphs = #()
	
	for i = 1 to objects.count do
	(
		local obj = objects[i]
		objClass = classOf obj.baseObject as string
		
		if (objClass == "sc2boundSphere") then
		(
			append bndSphs obj
		)
	)
	
	if (bndSphs.count > 1) then
	(
		for i = 1 to (bndSphs.count - 1) do
		(
			delete bndSphs[i]
		)
		
		-- check and resolve incremented name
		local bsph = bndSphs[bndSphs.count]
		local bname = bsph.name
		if (bname[bname.count] == "2") then bname[bname.count] = "1"
		bsph.name = bname
	)
)

-- Max Reset causes Animation UI to close
callbacks.removeScripts id:#m3animrs
callbacks.removeScripts id:#m3attach
callbacks.removeScripts id:#m3bndsph
callbacks.addScript #systemPostReset "sc2animUIreset()" id:#m3animrs
callbacks.addScript #systemPostReset "sc2att_size = 0.08; sc2par_size = 0.08; sc2att_id = \"\"; " id:#m3attach
callbacks.addScript #filePostOpen "sc2animUIreset()" id:#m3animrs
callbacks.addScript #filePostOpen "sc2att_size = 0.08; sc2par_size = 0.08; sc2att_id = \"\"" id:#m3attach
callbacks.addScript #nodeCreated "sc2bndSphCheck()" id:#m3bndsph
