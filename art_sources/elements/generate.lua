-- Every new raster pixel is authored with Aseprite Sprite/Image APIs.
-- Four distinct silhouettes: curling surf, rising flame, shattered stone, air arcs.
local out=assert(app.params['out'])
app.fs.makeAllDirectories(out)
local palettes={water={{50,142,230},{112,203,250},{23,73,148}},fire={{239,73,60},{255,145,108},{142,36,42}},earth={{164,119,70},{209,167,109},{94,65,45}},wind={{255,255,255},{222,232,244},{163,180,203}}}
for _,name in ipairs({'water','fire','earth','wind'}) do
 local s=Sprite(48,48,ColorMode.RGB)
 s.layers[1].name=name..' impact'
 local pal={}
 for i,c in ipairs(palettes[name]) do pal[i]=app.pixelColor.rgba(c[1],c[2],c[3],255) end
 for f=1,4 do
  if f>1 then s:newFrame() end
  s.frames[f].duration=0.1
  local img=Image(48,48,ColorMode.RGB)
  local function dot(x,y,c)
   x=math.floor(x);y=math.floor(y)
   if x>=0 and x<48 and y>=0 and y<48 then img:drawPixel(x,y,pal[c]) end
  end
  local function rect(x,y,w,h,c)
   for yy=y,y+h-1 do for xx=x,x+w-1 do dot(xx,yy,c) end end
  end
  if name=='water' then
   for x=5,41 do
    local crest=25+math.floor(6*math.sin((x+f*3)/8))
    for y=crest,crest+5 do dot(x,y,1) end
    dot(x,crest,2);dot(x,crest+6,3)
   end
   for a=0,26 do
    local angle=a/10
    local r=8+f
    local x=27+math.cos(angle)*r;local y=20-math.sin(angle)*r
    rect(x,y,3,3,1);dot(x,y,2)
   end
   for i=1,6 do rect(4+i*6,8+(i*7+f*3)%13,2,3,2) end
  elseif name=='fire' then
   for y=8,39 do
    local half=math.floor((y-5)/3)
    local center=24+math.floor(math.sin((y+f*4)/6)*4)
    for x=center-half,center+half do dot(x,y,1) end
    if y>21 then rect(center-2,y,4,1,2) end
    dot(center+half,y,3)
   end
   for i=1,5 do rect(6+i*7,4+(i*9-f*3)%18,2,3,1) end
  elseif name=='earth' then
   for i=0,6 do
    local x=5+i*5;local y=30-math.floor(math.sin(i*1.4+f)*7)
    local h=6+(i*3+f)%7
    for yy=0,h do
     local inset=math.abs(yy-h/2)>h/3 and 1 or 0
     rect(x+inset,y+yy,5-inset*2,1,1)
    end
    rect(x+1,y,3,2,2);rect(x+3,y+3,2,h-3,3)
   end
   for i=1,7 do rect(4+i*5,8+(i*7+f*4)%16,3,3,1) end
  else
   for band=0,2 do
    for x=4,43 do
     local y=13+band*9+math.floor(math.sin((x+f*4+band*3)/9)*4)
     rect(x,y,1,2,1)
     if x%7<3 then dot(x,y+2,2) end
    end
   end
   for i=1,5 do rect(5+i*7,5+(i*11+f*3)%36,3,1,1) end
  end
  s.cels[f].image=img
 end
 local tag=s:newTag(1,4);tag.name=name
 s:saveAs(app.fs.joinPath(out,name..'.aseprite'))
 app.sprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=app.fs.joinPath(out,name..'_sheet.png'),dataFilename=app.fs.joinPath(out,name..'.json'),dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true,trimSprite=false,trim=false}
 s:close()
end
print('PASS authored four elemental effects in Aseprite')
