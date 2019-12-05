require 'src.util'	
function love.load()
	love.window.setTitle('Fruita Crush!!!')
	playSound('music')
end

function love.update(dt)
	gStateMachine:update(dt)
end

function love.draw()
	gStateMachine:render()
end

function love.mousepressed(...)
	gStateMachine:mousePressed(...)
end

function love.mousereleased(...)
	gStateMachine:mouseReleased(...)
end

function love.mousemoved(...)
	gStateMachine:mouseMoved(...)
end

function love.keypressed(...)
	gStateMachine:keyPressed(...)
end
