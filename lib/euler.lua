--[[
	Euler: A math library for Lua dealing mainly with geometry, ranges 
	Author: Neer
]]

local euler={}

local Abs,Min,Max,Floor,Ceil=math.abs,math.min,math.max,math.floor,math.ceil
local tempx,tempy

function euler.randomSign()
	return random(1000)<500 and -1 or 1
end

function euler.constrain(value,min,max)
	return Min(Max(value,min),max)
end

function euler.clamp(value) return euler.constrain(value,0,1) end

function euler.inverse(value,type1,type2)
	type1, type2 = type1 or false, type2 or true
	return value==type1 and type2 or type1
end

function euler.comp(val1,val2,testa,testb)
	testa,testb=testa or true, testb or false
	return (val1==testa and val2==testb) or (val1==testb and val2==testa)
end

function euler.cycle(value,min,max)
	if value>max then return min
	elseif value<min then return max
	else return value end
end

function euler.inRange(value,min,max)
	return value>=min and value<=max
end

function euler.round(value,precision)
	tempx = 10^(precision or 0)	
	if value >= 0 then 
		return Floor(value * tempx + 0.5) / tempx
	else 
		return Ceil(value * tempx - 0.5) / tempx 
	end
end

function euler.frac(value)
	return value-Floor(value)
end

function euler.sgn(value)
	return value<0 and -1 or (value>0 and 1 or 0)
end

function euler.dif(...)
	if select('#',...)==2 then
		local a,b=...
		return Abs(Abs(a)-Abs(b))
	end
end

function euler.dist(x1,y1,x2,y2)
	x2, y2 = x2 or 0, y2 or 0
	return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

function euler.lerp(low,high,factor)
	return low + factor * (high - low) ;
end

function euler.map(value,low1,high1,low2,high2,constrain)
	low2, high2 = low2 or 0, high2 or 1
	value = low2 + (value - low1) / (high1 - low1) * (high2 - low2)
	if not constrain then return value end
	if low2<high2 then
		return euler.constrain(value,low2,high2)
	else
		return euler.constrain(value,high2,low2)
	end
end

function euler.closest(value,...)
	if select('#',...)==2 then
		local val1,val2=...
		return math.abs(value-val1)<=math.abs(value-val2) and val1 or val2	
	elseif select('#',...)>2 then
		local tbl={...}
		table.sort(tbl,function(val1,val2)
			return math.abs(value-val1)<=math.abs(value-val2)
		end)
		return tbl[1]
	end
	return (...) or value
end

function euler.snap(value,increment,Start,End)
	End=increment*euler.round(End/increment)
	value=euler.constrain(value,Start,End)
	if (value-Start)%increment==0 then
		print('returning here')
		return value
	end
	local newvalue1=Start+increment*math.floor((value-Start)/increment)
	local newvalue2=newvalue1+increment
	if newvalue2>End then newvalue2=newvalue1 end
	return euler.closest(value,newvalue1,newvalue2)
end

--TODO
function euler.snapVector(vector,gridx,gridy,gridw,gridh)
	if not gridw then
		gridw,gridh=gridx,gridy
		gridx,gridy=0,0
	end
end

function euler.norm(v,l,h) return euler.map(v,l,h,0,1,false) end

function euler.stair(...)
	local tbl,sum=type((...))=='table' and (...) or {...},0
	for i=1,#tbl,2 do
		if i+2>#tbl then
			sum=sum + (tbl[i]*tbl[2] - tbl[i+1]*tbl[1])
		else
			sum=sum + (tbl[i]*tbl[i+3] - tbl[i+2]*tbl[i+1])
		end
	end
	return sum/2
end

function euler.aabb(x1,y1,w1,h1, x2,y2,w2,h2)
	w2,h2=w2 or 0,h2 or 0
	return x1 <= x2+w2 and x2 <= x1+w1 and y1 <= y2+h2 and y2 <= y1+h1
end


function euler.pointInRect(x,y,w,h, x0,y0)
	return euler.aabb(x,y,w,h, x0,y0,0,0)
end

function euler.pointInLine(x1,y1,x2,y2, x0,y0)
	return euler.aabb(Min(x1,x2),Min(y1,y2),Abs(x1-x2),Abs(y1-y2),x0,y0)
		and Abs(euler.dist(x1,y1,x0,y0)+euler.dist(x2,y2,x0,y0)-euler.dist(x1,y1,x2,y2))<0.5
end

function euler.pointInEllipse(x,y,a,b, x0,y0)
	return euler.aabb(x-a,y-b,2*a,2*b, x0,y0) and 
		(((x-x0)/a)^2 + ((y-y0)/b)^2<=1)
end

function euler.pointInCircle(x,y,r, x0,y0)
	return euler.pointInEllipse(x,y,r,r, x0,y0)
end

function euler.lineInLine(ax1,ay1,ax2,ay2,bx1,by1,bx2,by2)
	local denominator=(by2-by1)*(ax2-ax1) - (bx2-bx1)*(ay2-ay1)
	tempx = ((bx2-bx1)*(ay1-by1) - (by2-by1)*(ax1-bx1)) / denominator
	tempy = ((ax2-ax1)*(ay1-by1) - (ay2-ay1)*(ax1-bx1)) / denominator
	if (euler.inRange(tempx,0,1) and euler.inRange(tempy,0,1)) then 
		return ax1 + (tempx * (ax2-ax1)), ay1 + (tempx * (ay2-ay1))
	end
end

function euler.lineInRect(x1,y1,x2,y2, x,y,width,height)
	if euler.pointInRect(x,y,width,height,x1,y1) then return x1,y1 end
	if euler.pointInRect(x,y,width,height,x2,y2) then return x2,y2 end
	if not euler.aabb(Min(x1,x2),Min(y1,y2),Abs(x1-x2),Abs(y1-y2),x,y,width,height) then return end
	local rx={x,x+width,x+width,x}
	local ry={y,y,y+height,y+height}
	for i=1,4 do
		tempx,tempy=euler.lineInLine(x1,y1,x2,y2, rx[i],ry[i],rx[i==4 and 1 or i+1],ry[i==4 and 1 or i+1])
		if tempx then return tempx,tempy end
	end
end

function euler.lineInCircle(x1,y1,x2,y2, x,y,r)
	if euler.pointInCircle(x,y,r,x1,y1) then return x1,y1 end
	if euler.pointInCircle(x,y,r,x2,y2) then return x2,y2 end
	if euler.pointInCircle(x,y,r,(x1+x2)/2,(y1+y2)/2) then return (x1+x2)/2,(y1+y2)/2 end
	if not euler.aabb(Min(x1,x2),Min(y1,y2),Abs(x1-x2),Abs(y1-y2),x-r,y-r,2*r,2*r) then return end
	local dist = ((x-x1)*(x2-x1) + (y-y1)*(y2-y1)) / ((x1-x2)^2 + (y1-y2)^2)
	tempx,tempy = x1 + dist*(x2-x1), y1 + dist*(y2-y1)
	if not euler.pointInLine(x1,y1,x2,y2, tempx,tempy) then return end
	if euler.dist(tempx - x, tempy - y)<=r then
		return tempx,tempy
	end
end

function euler.lineInEllipse(x1,y1,x2,y2, x,y,r1,r2)
	if euler.pointInEllipse(x,y,r1,r2,x1,y1) then return x1,y1 end
	if euler.pointInEllipse(x,y,r1,r2,x2,y2) then return x2,y2 end
	if euler.pointInEllipse(x,y,r1,r2,(x1+x2)/2,(y1+y2)/2) then return (x1+x2)/2,(y1+y2)/2 end
	if not euler.aabb(Min(x1,x2),Min(y1,y2),Abs(x1-x2),Abs(y1-y2),x-r1,y-r2,2*r1,2*r2) then return end
	local dot = ((x-x1)*(x2-x1) + (y-y1)*(y2-y1)) / ((x1-x2)^2 + (y1-y2)^2)
	tempx = x1 + dot * (x2-x1)
	tempy = y1 + dot * (y2-y1)
	if not euler.pointInLine(x1,y1,x2,y2, tempx,tempy) then return end
	if not euler.pointInEllipse(x,y,r1,r2, tempx,tempy) then return end
	if euler.dist(tempx - x, tempy - y)<=Max(r1,r2) then
		return tempx,tempy
	end
end

function euler.lineIntersect(a1,b1,c1, a2,b2,c2)
	if a1/a2-b1/b2<0.05 then return end
	return (b2*c1 - b1*c2)/(a1*b2-a2*b1),(a1*c2 - a2*c1)/(a1*b2-a2*b1)
end

function euler.getCircle(x1,y1,x2,y2,x3,y3)
	local a1,b1,c1=euler.getLine(x1,y1,x2,y2)
	print(a1,b1,c1,"here")
	
	c1=(a1*(x1+x2)/2)-(b1*(y1+y2)/2)
	print(a1,b1,c1)

	local a2,b2,c2=euler.getLine(x2,y2,x3,y3)
	a2,b2=b2,-a2
	c2=(a2*(y2+y3)/2)-(b2*(x2+x3)/2)
	print(a2,b2,c2,"her")
	
	
	tempx,tempy=euler.lineIntersect(a1,b1,c1, a2,b2,c2)
	return tempx,tempy,euler.dist(tempx,tempy,(x1+x2)/2,(y1+y2)/2)
end

function euler.circleInCircle(x1, y1, r1, x2, y2, r2)
	if euler.aabb(x1-r1,y1-r1,2*r1,2*r1,x2-r2,y2-r2,2*r2,2*r2)
		and euler.dist(x1,y1,x2,y2)<=r1+r2 then
		return
			(x1*r2 + x2*r1) / (r1 + r2),
			(y1*r2 + y2*r1) / (r1 + r2)
	end
end

function euler.circleInRect(cx,cy,r, x,y,w,h)
	return euler.aabb(cx-r,cy-r,2*r,2*r, x,y,w,h)
		and euler.dist(cx-euler.constrain(cx,x,x+w),cy-euler.constrain(cy,y,y+h))<=r
end

function euler.ellipseInEllipse(x1,y1,a1,b1, x2,y2,a2,b2)	
end

function euler.ellipseInRect(cx,cy,r1,r2,x,y,w,h)
	v1=euler.dist(cx-euler.constrain(cx,x,x+w),cy-euler.constrain(
		cy,y,y+h))
	v2=euler.dist(r1,r2)
	return euler.aabb(cx-r1,cy-r2,2*r1,2*r2, x,y,w,h)
		and euler.dist(cx-euler.constrain(cx,x,x+w),cy-euler.constrain(
			cy,y,y+h))<=euler.dist(r1,r2)
end

function euler.getVector(angle,magnitude)
	return math.cos(angle) * magnitude, math.sin(angle) * magnitude
end

function euler.getRGB(h,s,l,a)
	if s<=0 then return l,l,l,a end
	h, s, l = h*6, s, l
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return (r+m),(g+m),(b+m),a
end

function euler.getAngle(x1,y1,x2,y2)
	return math.atan2(y2-y1,x2-x1)
end

function euler.getLine(x1,y1,x2,y2)
	tempx,tempy=y2 - y1, x1 - x2
	return tempx,tempy,tempx*x1+tempy*y1
end

function euler.fact(value)
	return value>1 and value*euler.fact(value-1) or 1
end

function euler.permute(n,r)
	return euler.fact(n)/euler.fact(n-r)
end

function euler.select(n,r)
	return euler.permute(n,r)/euler.fact(r)
end

function euler.derange(value)
	if value==4 then
		return 9
	elseif value==2 then
		return 1
	else
		return Floor(euler.fact(value)/euler.exp(1))
	end
end

euler.difference=euler.dif
euler.normalize=euler.norm
euler.signum=euler.sgn
euler.sign=euler.sgn
euler.permutation=euler.permute
euler.combination=euler.select
euler.choose=euler.select
euler.testComplement=euler.comp
euler.circleIntersect=euler.circleInCircle
euler.segmentIntersect=euler.lineInLine
euler.circleContains=euler.pointInCircle
euler.lineContains=euler.pointInLine
euler.getRGBA=euler.getRGB
euler.withinBounds=euler.inRange
euler.toggle=euler.inverse
euler.toRGB=euler.getRGB
return euler
