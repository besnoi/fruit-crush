--
-- StateMachine - a state machine
--
-- Credit: Colton Ogden
--
--

StateMachine = Class{}

function StateMachine:init(states)
	self.empty = {
		render = function() end,
		update = function() end,
		enter = function() end,
		exit = function() end
	}
	self.states = states or {} -- [name] -> [function that returns states]
	self.current = self.empty
end

function StateMachine:change(stateName, enterParams)
	assert(self.states[stateName],"Oops! State Doesn't Exist")
	self.current:exit()
	self.current = self.states[stateName]()
	self.current:enter(enterParams)
	return self
end
StateMachine.switch=StateMachine.change

local callbacks={
	'update','render',
	'keyPressed','keyReleased',
	'mousePressed','mouseMoved','mouseReleased'
}

for i=1,#callbacks do
	StateMachine[callbacks[i]]=function(this,...)
		this.current[callbacks[i]](this.current,...)
	end
end