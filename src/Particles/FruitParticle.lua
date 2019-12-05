FruitParticle=Class{
	img,x,y
}

FRUIT_GRAVITY=30

function FruitParticle:init(img,x,y,dx,dy,da)
	self.img=img
	self.x,self.y=x+32,y+32
	self.dx,self.da=dx,da
	self.dy=dy
	self.r,self.op=0,1
end

function FruitParticle:update(dt)
	self.x=self.x+self.dx*dt
	self.r=self.r+self.da*dt
	self.y=self.y+self.dy*dt
	self.dy=self.dy+FRUIT_GRAVITY
	self.op=self.op-dt*1.5
end

function FruitParticle:render()
	love.graphics.setColor(1,1,1,self.op)
	iffy.draw('atlas',self.img,self.x,self.y,self.r,1,1,32,32)
	love.graphics.setColor(1,1,1)
end