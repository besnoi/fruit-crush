ParticleSystem=Class{
	particles
}

function ParticleSystem:init()
	self.particles={}
end

function ParticleSystem:newHintParticleHelper(x,y,dir)
	if dir=='left' then x=x-70 y=y+10
	elseif dir=='right' then x=x+10 y=y-10
	elseif dir=='down' then y=y+35
	elseif dir=='up' then y=y+30
	end
	table.insert(self.particles,HintParticle(dir,x,y))
end

function ParticleSystem:newHintParticle(x,y,dir)
	self:newHintParticleHelper(x,y,dir)
	-- dir=oppositeDir(dir)
	if dir=='left' then x=x-64
	elseif dir=='right' then x=x+64
	elseif dir=='down' then y=y+64
	elseif dir=='up' then y=y-64
	end
	self:newHintParticleHelper(x,y,oppositeDir(dir))	
end

function ParticleSystem:newScoreParticle(score,x,y)
	table.insert(
		self.particles, ScoreParticle(score,x,y)
	)
end

function ParticleSystem:newFruitParticle(img,x,y)
	img=img=='7' and '6' or img
	table.insert(
		self.particles, FruitParticle('particle_'..img..'1',x,y,-150,-100,(random(1,5)))
	)
	table.insert(
		self.particles, FruitParticle('particle_'..img..'2',x,y,150,0,-(random(1,5)))
	)
end

function ParticleSystem:update(dt)
	for i=#self.particles,1,-1 do
		if self.particles[i].op<=0.05 then
			table.remove(self.particles,i)
		else
			self.particles[i]:update(dt)		
		end
	end
end

function ParticleSystem:render()
	for i=1,#self.particles do
		self.particles[i]:render()
	end
end