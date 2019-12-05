clove = require 'lib.clove'
gImages=clove.loadImages("assets/graphics",true)
clove.requireAll('lib')
require 'src.StateMachine'
require 'src.State'
clove.requireAll('src/Entities')
clove.requireAll('src/Particles')
clove.requireAll('src/Scenes')
gSounds=clove.loadSounds("assets",true)
gSettings={playAudio=true}

random=love.math.random
local letters="abcdefghijklmnopqrstuvwxyz"
local numbers="0123456789"
local others=":;<=>?@*+,-./!\"#$%' "
local characters=letters..letters:upper()..numbers..others

WINDOW_WIDTH,WINDOW_HEIGHT=800,600
numberFont=love.graphics.newImageFont("assets/font/numberFont.png","0123456789+")
greenFont=love.graphics.newImageFont("assets/font/greenFont.png",characters)
whiteFont=love.graphics.newImageFont("assets/font/whiteFont.png",characters)
background=love.graphics.newImage('assets/background.png')

iffy.newAtlas('assets/atlas.png')
iffy.newAtlas('assets/scoreBoard.png')

function playSound(source)
	-- if gSounds[source]:isPlaying() then
	-- 	-- print('working')
	-- 	gSounds[source]:seek(1,'seconds')
	-- end
	-- love.audio.stop()
	if gSettings.playAudio then
		gSounds[source]:play()
	end
end

gStateMachine=StateMachine{
	['mainMenu']=function() return MainMenuState() end,
	['pause']=function() return PauseState() end,
	['roundOver']=function() return RoundOverState() end,
	['play']=function() return PlayState() end
}

gStateMachine:change('mainMenu')