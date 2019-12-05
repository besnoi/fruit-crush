GUISystem=Class()

function GUISystem:init()
	self.pauseButton=lavis.imageButton(gImages.pauseButton,50,40)
	self.pauseButton.sx,self.pauseButton.sy=0.7,0.7
	self.pauseButton:setShape('circle',self.pauseButton:getImageWidth()/2)
	self.pauseButton:setImageOrigin(self.pauseButton:getImageWidth()/2+10,self.pauseButton:getImageHeight()/2+10)
	self.pauseButton.onClick=function()
		local Game=gStateMachine.current
		print('working')
		if Game.pause then Game:pause() end
	end
	self.pauseButton.onMouseEnter=function()
		self.pauseButton:setSize(40)
	end
	self.pauseButton.onMouseExit=function()
		self.pauseButton:setSize(35)
	end
end

function GUISystem:update(dt)
	self.pauseButton:update(dt)
end

function GUISystem:render()
	self.pauseButton:render()
end

function GUISystem:mousePressed(...)
	self.pauseButton:mousepressed(...)
end

function GUISystem:mouseReleased(...)
	self.pauseButton:mousereleased(...)
end

function GUISystem:mouseMoved(...)
	self.pauseButton:mousemoved(...)
end