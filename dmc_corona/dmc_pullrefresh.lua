--====================================================================--
-- widget_pullrefresh.lua
--
--
-- by David McCuskey
--====================================================================--

--[[

Copyright (C) 2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]




--====================================================================--
-- DMC Library Setup
--====================================================================--

local dmc_lib_data, dmc_lib_func
dmc_lib_data = _G.__dmc_library
dmc_lib_func = dmc_lib_data.func


--====================================================================--
-- Imports
--====================================================================--

local Utils = require( dmc_lib_func.find('dmc_utils') )
local Objects = require( dmc_lib_func.find('dmc_objects') )
local States = require( dmc_lib_func.find('dmc_states') )


--====================================================================--
-- Setup, Constants
--====================================================================--

-- setup some aliases to make code cleaner
local inheritsFrom = Objects.inheritsFrom
local CoronaBase = Objects.CoronaBase

local LOCAL_DEBUG = false


--====================================================================--
-- Pull Refresh Widget Class
--====================================================================--

local PullRefresh = inheritsFrom( CoronaBase )
PullRefresh.NAME = "Scroller View Base Class"

States.mixin( PullRefresh )
-- States.setDebug( true )


--== Class Constants

PullRefresh.TRANSITION_TIME = 100


--== State Constants

PullRefresh.STATE_INIT = "state_init"
-- show 'Pull to Refresh'
PullRefresh.STATE_IDLE = "state_idle"
-- being pulled, can be ready to refresh or not
-- show 'Release to Refresh'
PullRefresh.STATE_RELEASE = "state_release"
-- released when in limit of can_refresh
-- show 'Refreshing Data'
PullRefresh.STATE_REFRESH = "state_refresh"


--== Event Constants

PullRefresh.EVENT = "scroller_view"
PullRefresh.STATE_CHANGE = "state_change_event"




--====================================================================--
--== Start: Setup DMC Objects


function PullRefresh:_init( params )
	-- print( "PullRefresh:_init" )
	params = params or {}
	self:superCall( "_init", params )
	--==--


	--== Create Properties ==--

	self._width = params.width
	self._height = params.height

	self._activation = params.activation
	self._do_refresh = false

	--== Display Groups ==--

	--== Object References ==--

	self._primer = nil

end
--[[
function PullRefresh:_undoInit()
	-- print( "PullRefresh:_undoInit" )

	--==--
	self:superCall( "_undoInit" )
end
--]]

-- _createView()/_undoCreateView()
--
function PullRefresh:_createView()
	-- print( "PullRefresh:_createView" )
	self:superCall( "_createView" )
	--==--

	local W,H = self._width, self._height
	local H_CENTER, V_CENTER = W*0.5, H*0.5

	local o

	-- prime the display group
	o = display.newRect( 0, 0, W, H )
	o:setFillColor(0,0,0,0)
	if gDEPLOY == 'DEV' and LOCAL_DEBUG then
		o:setFillColor(255, 190, 0, 0.5)
	end
	o.anchorX, o.anchorY = 0.5, 0
	o.x, o.y = 0, 0

	self:insert( o )
	self._primer = o

	self.anchorX, self.anchorY = 0.5, 0
	self.x, self.y = 0, 0

end

function PullRefresh:_undoCreateView()
	-- print( "PullRefresh:_undoCreateView" )

	local o
	o = self._primer
	o:removeSelf()
	self._primer = nil

	--==--
	self:superCall( "_undoCreateView" )
end


-- _initComplete()
--
function PullRefresh:_initComplete()
	-- print( "PullRefresh:_initComplete" )
	self:superCall( "_initComplete" )
	--==--

	local o, f

	self:setState( self.STATE_INIT )
	self:gotoState( self.STATE_IDLE )

end
--[[
function PullRefresh:_undoInitComplete()
	-- print( "PullRefresh:_undoInitComplete" )
	--==--
	self:superCall( "_undoInitComplete" )
end
--]]


--== END: Setup DMC Objects
--====================================================================--




--====================================================================--
--== Public Methods



function PullRefresh.__setters:activation( value )
	-- print( "PullRefresh.__setters:activation" )
	if value ~= nil and value ~= self._activation then
		self._activation = value
	end
end
function PullRefresh.__getters:activation( value )
	-- print( "PullRefresh.__getters:activation" )
	return self._activation
end


function PullRefresh.__setters:offset( value )
	-- print( "PullRefresh.__setters:offset" )
	if value ~= nil then
		self:_checkOffsetValue( value )
	end
end


function PullRefresh.__setters:do_refresh( value )
	-- print( "PullRefresh.__setters:do_refresh" )
	if value ~= nil and value ~= self._do_refresh then
		self._do_refresh = value
		if value == true then
			self:gotoState( self.STATE_REFRESH )
		else
			self:gotoState( self.STATE_IDLE )
		end
	end
end
function PullRefresh.__getters:do_refresh( value )
	-- print( "PullRefresh.__getters:do_refresh" )
	return self._do_refresh
end




--====================================================================--
--== Private Methods



function PullRefresh:_checkOffsetValue( value )
	-- print( "PullRefresh:_checkOffsetValue", value )

	local curr_state = self:getState()
	local activate = self._activation

	if value < activate and curr_state == self.STATE_RELEASE then
		self:gotoState( self.STATE_IDLE )

	elseif value > activate and curr_state == self.STATE_IDLE then
		self:gotoState( self.STATE_RELEASE )

	elseif self._do_refresh and curr_state == self.STATE_RELEASE then
		self:gotoState( self.STATE_REFRESH )

	end

end


--======================================================--
--== START: PULL REFRESH STATE MACHINE


-- state_init()
--
function PullRefresh:state_init( next_state, params )
	-- print( "PullRefresh:state_create: >> ", next_state )

	if next_state == self.STATE_IDLE then
		self:do_state_idle( params )

	else
		print( "WARNING :: PullRefresh:state_create > " .. tostring( next_state ) )
	end

end



function PullRefresh:updateStateIdle( params )
	-- print( "PullRefresh:updateStateIdle", params  )
	print( "WARNING:: PullRefresh:updateStateIdle OVERRIDE")
end


function PullRefresh:do_state_idle( params )
	-- print( "PullRefresh:do_state_idle", params  )
	params = params or {}
	--==--

	local state = self.STATE_IDLE

	self:updateStateIdle()

	self:setState( state )
	self:_dispatchEvent( self.STATE_CHANGE, { state=state }, { merge=true } )

end

function PullRefresh:state_idle( next_state, params )
	-- print( "PullRefresh:state_idle: >> ", next_state )

	if next_state == self.STATE_RELEASE then
		self:do_state_release( params )

	elseif next_state == self.STATE_REFRESH then
		self:do_state_refresh( params )

	else
		print( "WARNING :: PullRefresh:state_idle > " .. tostring( next_state ) )
	end

end



function PullRefresh:updateStateRelease( params )
	-- print( "PullRefresh:updateStateRelease", params  )
	print( "WARNING:: PullRefresh:updateStateRelease OVERRIDE")
end

function PullRefresh:do_state_release( params )
	-- print( "PullRefresh:do_state_release", params  )
	params = params or {}
	--==--

	local state = self.STATE_RELEASE

	self:updateStateRelease()

	self:setState( state )
	self:_dispatchEvent( self.STATE_CHANGE, { state=state }, { merge=true } )

end

function PullRefresh:state_release( next_state, params )
	-- print( "PullRefresh:state_release: >> ", next_state )

	if next_state == self.STATE_IDLE then
		self:do_state_idle( params )

	elseif next_state == self.STATE_REFRESH then
		self:do_state_refresh( params )

	else
		print( "WARNING :: PullRefresh:state_release > " .. tostring( next_state ) )
	end

end



function PullRefresh:updateStateRefresh( params )
	-- print( "PullRefresh:updateStateRefresh", params  )
	print( "WARNING:: PullRefresh:updateStateRefresh OVERRIDE")
end

function PullRefresh:do_state_refresh( params )
	-- print( "PullRefresh:do_state_refresh", params  )
	params = params or {}
	--==--

	local state = self.STATE_REFRESH

	self:updateStateRefresh()

	self:setState( state )
	self:_dispatchEvent( self.STATE_CHANGE, { state=state }, { merge=true } )

end

function PullRefresh:state_refresh( next_state, params )
	-- print( "PullRefresh:state_refresh: >> ", next_state )

	if next_state == self.STATE_IDLE then
		self:do_state_idle( params )

	elseif next_state == self.STATE_RELEASE then
		self:do_state_release( params )

	else
		print( "WARNING :: PullRefresh:state_refresh > " .. tostring( next_state ) )
	end

end


--== END: PULL REFRESH STATE MACHINE
--======================================================--




--====================================================================--
--== Event Handlers




return PullRefresh
