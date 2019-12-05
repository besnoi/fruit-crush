MainMenuState=State()

function MainMenuState:init()
	self.y=100
	self.rectOp=0
	self.scale=.3
	self.playBtn=lavis.imageButton(gImages.playBtn,330,100)
	self.playBtn:setShape('circle',130)
	self.playBtn:setImageOrigin(95,95)
	self.playBtn:setPosition(398,470)
	self.playBtn:setImagePosition(385,440)
	self.playBtn.onClick=function()
		self.playBtn:setImageSize(2*100)
	end
	self.playBtn.onRelease=function()
		self.playBtn:setImageSize(2*130)
		if not self.playBtn:isHovered() then
			return
		end
		flux.to(self,2,{
			rectOp=1
		}):oncomplete(function()
			gStateMachine:change('roundOver',{
				level=1,
				target=100,
				time=60
			})
		end)
	end
	self.playBtn.onMouseEnter=function()
		self.playBtn:setImageSize(2*120)
	end
	self.playBtn.onMouseExit=function()
		self.playBtn:setImageSize(2*130)
	end
	self:tween()
	Timer.after(5,function() self:tween() end)
end

function MainMenuState:tween()
	flux.tween(self,2,{
		y=self.y==200 and 100 or 200
	}):oncomplete(function()
		flux.tween(self,2,{
			scale=self.scale==.3 and .25 or .3
		})
	end)
	self.r=100
end

function MainMenuState:update(dt)
	self.r=self.r+dt
	self.playBtn:update(dt)
	Timer.update(dt)
	flux.update(dt)
end

function MainMenuState:render()
	love.graphics.setColor(1,1,1)
	love.graphics.draw(gImages.gameBackground)
	love.graphics.draw(gImages['logo'],400,self.y,0,self.scale,self.scale,1900/2,1208/2)
	love.graphics.draw(gImages['starbust'],self.playBtn.imgX+20,self.playBtn.imgY,self.r,2.8,2.8,135/2,136/2)
	self.playBtn:render()
	love.graphics.setColor(1,1,1,self.rectOp)
	love.graphics.rectangle('fill',0,0,800,600)
end


function MainMenuState:mousePressed(...)
	self.playBtn:mousepressed(...)
end

function MainMenuState:mouseReleased(...)
	self.playBtn:mousereleased(...)
end

function MainMenuState:mouseMoved(...)
	self.playBtn:mousemoved(...)
end
