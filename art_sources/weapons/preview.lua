-- Aseprite-only contact sheet for visual review (not a runtime asset).
local src=assert(app.params['src']);local out=assert(app.params['out'])
local s=Sprite(384,112,ColorMode.RGB);local im=Image(384,112,ColorMode.RGB)
local bg=app.pixelColor.rgba(24,27,44,255)
for y=0,111 do for x=0,383 do im:drawPixel(x,y,bg) end end
for i,name in ipairs({'water','fire','earth','wind'}) do
 local sheet=Image{fromFile=src..'/'..name..'_sheet.png'}
 for y=0,47 do for x=0,47 do local c=sheet:getPixel(x,y)
  if app.pixelColor.rgbaA(c)>0 then for yy=0,1 do for xx=0,1 do im:drawPixel((i-1)*96+x*2+xx,y*2+8+yy,c) end end end
 end end
end
s.cels[1].image=im;s:saveCopyAs(out);s:close()
print('PASS Aseprite contact sheet: WATER FIRE EARTH WIND, 2x nearest')
