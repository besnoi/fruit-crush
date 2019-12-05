ScoreParticle=Class{
	img,x,y
}

SCORE_PARTICLE_RESISTANCE=0

function ScoreParticle:init(value,x,y)
	self.score='+'..value
	self.x,self.y=x+32,y+32
	self.origY=self.y
	self.dy=-100
	self.op=1
end

function ScoreParticle:update(dt)
	self.y=self.y+self.dy*dt
	self.op=self.op-dt*(self.y-self.origY>200 and 1/10 or 1)
	self.dy=self.dy+SCORE_PARTICLE_RESISTANCE
end

defaultFont=love.graphics.newFont(15)
function ScoreParticle:render()
	love.graphics.push()
	love.graphics.scale(.8)
	love.graphics.translate(100,50)
	love.graphics.setColor(1,1,1,self.op)
	love.graphics.setFont(numberFont)
	love.graphics.print(self.score,self.x,self.y)
	love.graphics.setColor(1,1,1)
	love.graphics.setFont(defaultFont)
	love.graphics.pop()
end