HintParticle=Class{
	img,x,y
}

HINT_DURATION=3
HINT_BOUNDARY=15
HINT_SPEED=30
function HintParticle:init(dir,x,y)
	self.img=img
	self.x,self.y=x+10,y
	self.sx,self.r=1,0
	if dir=='left' then
		self.sx=-1
		self.x=self.x+90
	elseif dir=='down' then
		self.r=math.rad(90)
		self.x=self.x+35
	elseif dir=='up' then
		self.r=math.rad(-90)
		self.x=self.x+5
	end
	if dir=='right' or dir=='left' then
		self.dx,self.dy=HINT_SPEED,0
		self.bound=self.x+HINT_BOUNDARY*(dir=='left' and -1 or 1)	
	else
		self.dy,self.dx=HINT_SPEED,0
		self.bound=self.y+HINT_BOUNDARY*(dir=='up' and -1 or 1)			
	end
	self.op=0.1
	self.timer=0
end

function HintParticle:update(dt)
	self.timer=self.timer+dt
	if self.timer>HINT_DURATION then
		self.op=self.op-dt
	else
		self.op=euler.clamp(self.op+dt)
	end
	
	self.x=self.x+self.dx*dt
	self.y=self.y+self.dy*dt

	if euler.sign(self.dx)==1 and self.x>self.bound then
		self.bound=self.x-HINT_BOUNDARY
		self.dx=-HINT_SPEED
	elseif euler.sign(self.dx)==-1 and self.x<self.bound then
		self.bound=self.x+HINT_BOUNDARY
		self.dx=HINT_SPEED
	end

	if euler.sign(self.dy)==1 and self.y>self.bound then
		self.bound=self.y-HINT_BOUNDARY
		self.dy=-HINT_SPEED
	elseif euler.sign(self.dy)==-1 and self.y<self.bound then
		self.bound=self.y+HINT_BOUNDARY
		self.dy=HINT_SPEED
	end
	
end

function HintParticle:render()
	if PlayState.hintDisabled then return end
	love.graphics.setColor(1,1,1,self.op)
	iffy.draw('atlas','hint_arrow',self.x,self.y,self.r,self.sx,1)
	love.graphics.setColor(1,1,1)
end