--[[
	RobotCursor V1.5
	Author: Neer	
	Description: A library which allows you to move cursor on the fly!
	Note: V1.5 uses an external knife.Timer library!
]]--


local love_isDown=love.mouse.isDown

local fcursor={

	active=true,      --if the artificial cursor is active

	isVirtual,        --whether to set mouse position or an image's position
	cursorImg,        --the image of the virual cursor (if `isVirtual`)

	x=0,              --x,y tells the position of ac
	y=0,

	destx=0,          --destination: ac will move towards (destx,desty)
	desty=0,          --(iff ac has no other priorities)

	dx=1,             --dx,dy is the speed of the cursor (unit:pixel/frame)
	dy=1,


	stages={},        --the main table containing the stages
	currentStage=0,   --the current index of the stage/path table
	stageTime=0,      --delay after which ac should proceed to the next stage
	stageTimer,       --the timer for stageTime (internal variable)

	codTime=0,         --the delay after which ac should *press* on destination
	rodTime=0,         --the delay after which ac should *release* on destination
	codTimer=0,        --the timer for codTime (INTERNAL)
	rodTimer=0,        --the timer for rodTime (INTERNAL)

	-- justClicked=false, --whether *ac* just clicked on the destination
	dragging=false,    --is the cursor dragging while moving towards destination
	destReached=false, --has ac *just* reached the destination (INTERNAL)
	justClicked=nil,   --which button has ac *just* just clicked (INTERNAL)
	pressOnDest=nil,   --the button to *press* on destination
	releaseOnDest=nil,   --the button to click on destination

	--[[
	AN IMPORTANT NOTE HERE:
	------------------------
	  pressOnDest is a table meant for internal use and
	  clickOnDestination is a method meant for providing interface for end-user
	  similar is the case of destReached and destinationReached
	  And no I DON'T use hungarian notation even though some people recommend it
	  for weakly-typed languages. (cause it confuses me)
	]]--
	
	--General callback functions/handlers
	tick=function() end,    --called on every frame until destination reached
	finish=function() end,  --called after ac has reached the destination

	--Functions that define these handlers
	onupdate=function() end,


	--VIRTUAL MOUSE EVENTS: what to do when cursor is clicked,dragged
	move=function(...) love.mousemoved(...) end,
	release=function(...) love.mousereleased(...) end,
	click,
	drag
}

fcursor.click=function(x,y,btn)
	fcursor.justClicked=btn
	love.mousepressed(x,y,btn)
end

fcursor.oncomplete=function(func) fcursor.finish=func end

fcursor.drag=function(x,y)
	fcursor.justClicked=1
end

love.mouse.isDown=function(...)
	local btn=(...)
	if fcursor.active then
		return btn==fcursor.justClicked or love_isDown(...)
	end
	return love_isDown(...)
end


--a function meant for internal use (to simplify things)
local function setMP()
	if fcursor.isVirtual then return end
	love.mouse.setPosition(fcursor.x,fcursor.y)
end
	
-- this sausage code simply resets the initial values (not the chandlers)
function fcursor.reset() fcursor.isVirtual,fcursor.cursorImg,fcursor.x,fcursor.y,fcursor.dx,fcursor.dy,fcursor.stage,fcursor.stageTimer,fcursor.stageTime,codTimer,codTime,fcursor.justClicked,fcursor.dragging,fcursor.destReached,fcursor.pressOnDest=false,nil,0,0,1,1,0,0,0,0,0,false,false,false,false end

--sets ac's position
function fcursor.setPosition(x,y)
	fcursor.x,fcursor.y=x or fcursor.x,y or fcursor.y
end

--sets ac's destination
function fcursor.setDestination(x,y)
	fcursor.destx,fcursor.desty=x or fcursor.destx,y or fcursor.desty
	--reset the timers (note we are also using them as flags)
	fcursor.codTimer=0
	fcursor.rodTimer=0
end

--enable dragging so it'd click on every frame while moving towards destination
function fcursor.enableDragging(boolean)
	fcursor.dragging=boolean~=false
end

--set the speed (pixels per frame)
function fcursor.setSpeed(dx,dy)
	fcursor.dx,fcursor.dy=dx or fcursor.dx,dy or fcursor.dy
end

--should i click on reaching destination. If yes after what how many seconds and
--which button to *press*?
function fcursor.clickOnDestination(btn,delay)
	if btn then
		fcursor.codTime=delay or 0
		fcursor.pressOnDest=btn
	else
		fcursor.pressOnDest=nil
	end
end

--same as clickOnDestination except button is *released*!
function fcursor.releaseOnDestination(btn,delay)
	if btn then
		fcursor.rodTime=delay or 0
		fcursor.releaseOnDest=btn
	else
		fcursor.releaseOnDest=nil
	end
end

--sets the image cursor to given image (reference or url)
function fcursor.setVirtualCursor(img)
	fcursor.isVirtual=true
	fcursor.cursorImg=type(img)=='string' and love.graphics.newImage(img) or img
end

--if you previously called setVirtualCursor and want to reset it to default
function fcursor.setMouseCursor()
	fcursor.isVirtual=false
end

--useful *only* if you have isVirtual turned on and want to render the cursor image
function fcursor.draw(...)
	if not fcursor.isVirtual then return end
	love.graphics.draw(fcursor.cursorImg,fcursor.x,fcursor.y,...)
end

--step ac: basically increment or decrement ac's position based on destination
local function fcursor_step()
	if not fcursor.destinationReached() then

		if fcursor.destx~=0 and fcursor.destx~=fcursor.x then
			fcursor.x=fcursor.x+(fcursor.x<fcursor.destx and fcursor.dx or -fcursor.dx)
		end
		if math.abs(fcursor.destx-fcursor.x)<fcursor.dx then fcursor.x=fcursor.destx end

		if fcursor.desty~=0 and fcursor.desty~=fcursor.y then
			fcursor.y=fcursor.y+(fcursor.y<fcursor.desty and fcursor.dy or -fcursor.dy)
		end
		if math.abs(fcursor.desty-fcursor.y)<fcursor.dy then fcursor.y=fcursor.desty end
		setMP()
		if fcursor.destinationReached() then fcursor.destReached=true end
	end
	
end

--After what time should ac proceed to the *next* stage 
--(basically delay between two stages)
function fcursor.setStageDelay(time)
	fcursor.stageTime=time
end

--After what time should ac "click" on the destination
function fcursor.setClickDelay(time)
	fcursor.codTimer=time
end

function fcursor.setStages(stages)
	fcursor.stages=stages
	fcursor.currentStage=0
	fcursor.updateStage()
end

function fcursor.addStage(stage)
	fcursor.stages[#fcursor.stages]=stage
	if fcursor.currentStage==0 then fcursor.updateStage() end
end

function fcursor.updateStage()
	fcursor.currentStage=fcursor.currentStage+1
	local tbl,i=fcursor.stages,fcursor.currentStage
	if not tbl[i] then return end
	fcursor.setPosition(tbl[i]['fromX'],tbl[i]['fromY'])
	fcursor.clickOnDestination(tbl[i]['clickBtn'],tbl[i]['clickDelay'] or fcursor.codTime)
	fcursor.releaseOnDestination(tbl[i]['releaseBtn'],tbl[i]['releaseDelay'] or fcursor.rodTime)
	fcursor.setDestination(tbl[i]['toX'],tbl[i]['toY'])
	fcursor.setSpeed(tbl[i]['speedX'],tbl[i]['speedY'])		
	fcursor.enableDragging(tbl[i]['dragging'] or fcursor.dragging)
	fcursor.setStageDelay(tbl[i]['stageDelay'] or fcursor.stageTime)
	fcursor.oncomplete(tbl[i]['finish'] or fcursor.finish)
	fcursor.stageTimer=nil
end

--activates/deactivates the robot cursor
function fcursor.setActive(val) fcursor.active=val end

--Whether or not is the fcursor active
function fcursor.isActive() return fcursor.active end

function fcursor.update(dt)
	fcursor.justClicked=false	
	if not fcursor.active then return end
	fcursor_step()
	if not fcursor.destinationReached() then
		fcursor.move(fcursor.x,fcursor.y)--,fcursor.x-fcursor.px,fcursor.y-fcursor.py)
		fcursor.px,fcursor.py=fcursor.x,fcursor.y
		fcursor.tick()
		if fcursor.dragging then
			fcursor.drag(fcursor.x,fcursor.y,1)
		end
	else
		if fcursor.destReached then
			if fcursor.pressOnDest then
				--Just a flag so that rc doesn't click more than once
				if fcursor.codTimer then
					setMP()
					fcursor.codTimer=fcursor.codTimer+dt
					if fcursor.codTimer>=fcursor.codTime then
						fcursor.click(fcursor.x,fcursor.y,fcursor.pressOnDest)
						fcursor.codTimer=nil
						fcursor.pressOnDest=false
					end
				end
			end
			if fcursor.releaseOnDest then
				if fcursor.rodTimer then
					setMP()
					fcursor.rodTimer=fcursor.rodTimer+dt
					
					if fcursor.rodTimer>=fcursor.rodTime then
						fcursor.release(fcursor.x,fcursor.y,fcursor.releaseOnDest)
						--Mouse cannot be clicked after it has been released!
						fcursor.codTimer,fcursor.rodTimer=nil
						fcursor.finish()
						fcursor.destReached=false
					end
				end
			else
				fcursor.rodTimer=nil
				if not fcursor.codTimer then
					fcursor.finish()
				end
			end
			--Move on to next stage once you have pressed/released the btns (if any)
			if not fcursor.codTimer and not fcursor.rodTimer then
				fcursor.destReached=false
				fcursor.stageTimer=0
			end
		else
			if fcursor.stageTimer then
				fcursor.stageTimer=fcursor.stageTimer+dt
				if fcursor.stageTimer>=fcursor.stageTime then
					fcursor.updateStage()
					fcursor.stageTimer=nil
				end
			end
		end
	end
end

-- if the cursor has reached the destination
function fcursor.destinationReached()
	return fcursor.x==fcursor.destx and fcursor.y==fcursor.desty
end

function fcursor.getX() return fcursor.x end
function fcursor.getY() return fcursor.y end

function fcursor.getPosition()
	return fcursor.x,fcursor.y
end

--Init-ing some callback functions for you
--so you don't have to have empty functions in *your* program!

love.mousepressed = function() end
love.mousereleased = function() end
love.mousemoved = function() end

return fcursor
