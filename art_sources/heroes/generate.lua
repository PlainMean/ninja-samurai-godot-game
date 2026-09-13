-- All new raster authorship is exclusively Aseprite Sprite/Image API.
local out=assert(app.params['out']);app.fs.makeAllDirectories(out)
local s=Sprite(48,48,ColorMode.RGB);s.layers[1].name='Kira braided tide warden and crescent poleblade'
local hex={'16283e','246e78','51c9bd','e5f4d6','dcaa87','ba7b51','34475c'}
local p={}
for i,h in ipairs(hex) do p[i]=app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local pal=Palette(#p+1);pal:setColor(0,Color{r=0,g=0,b=0,a=0})
for i,c in ipairs(p) do pal:setColor(i,Color(c)) end
s:setPalette(pal)
for f=1,4 do
 if f>1 then s:newFrame() end
 s.frames[f].duration=0.1
 local im=Image(48,48,ColorMode.RGB)
 local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do if xx>=0 and xx<48 and yy>=0 and yy<48 then im:drawPixel(xx,yy,p[c]) end end end end
 local function line(x,y,xx,yy,c,w)
  local n=math.max(math.abs(xx-x),math.abs(yy-y))
  for k=0,n do rect(math.floor(x+(xx-x)*k/math.max(n,1)),math.floor(y+(yy-y)*k/math.max(n,1)),w or 1,w or 1,c) end
 end
 local d=({0,-2,2,1})[f]
 -- Split ivory greaves; asymmetric teal skirt and exposed forward arm.
 rect(15,33,6,11,1);rect(27,33,6,11,1);rect(16,34,4,7,4);rect(28,34,4,7,4)
 rect(14,42,8,3,7);rect(27,42,9,3,7)
 for y=21,36 do rect(15+d-math.floor((y-21)/5),y,15+math.floor((y-21)/3),1,1) end
 for y=22,34 do rect(16+d-math.floor((y-22)/5),y,12+math.floor((y-22)/3),1,2) end
 rect(19+d,21,5,10,4);rect(20+d,22,3,8,3);rect(14+d,29,17,3,6)
 line(16+d,22,11+d,29,1,4);line(17+d,23,12+d,28,4,2)
 line(28+d,23,34+d,25-f,1,4);line(29+d,24,35+d,26-f,5,2)
 -- High copper braid looping left, never a ninja hood or enemy helmet.
 rect(19+d,9,10,12,1);rect(20+d,11,8,8,5);rect(26+d,14,2,1,1)
 rect(18+d,8,10,5,6);rect(18+d,10,3,8,6);rect(21+d,6,5,3,6)
 for k=0,5 do rect(15+d-math.floor(k/2),10+k*3,4,3,1);rect(16+d-math.floor(k/2),10+k*3,2,2,6) end
 rect(12+d,28,4,3,3);rect(19+d,10,10,2,3)
 -- Long diagonal poleblade with open crescent head and bright water edge.
 local x=({35,29,39,37})[f];local y=({9,5,15,11})[f]
 line(26,42,x,y+4,1,3);line(27,42,x+1,y+4,6,1)
 line(x-2,y+5,x-3,y-1,1,3);line(x-3,y-1,x+2,y-5,1,3)
 line(x+2,y-5,x+7,y-3,1,3);line(x+7,y-3,x+7,y+2,1,2)
 line(x-1,y+5,x-2,y-1,3,1);line(x-2,y-1,x+2,y-4,4,2)
 line(x+2,y-4,x+6,y-2,4,2);line(x+6,y-2,x+7,y+2,3,1)
 s.cels[f].image=im
end
local tag=s:newTag(1,4);tag.name='support'
s:saveAs(app.fs.joinPath(out,'kira.aseprite'));app.sprite=s
app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=app.fs.joinPath(out,'kira_sheet.png'),dataFilename=app.fs.joinPath(out,'kira.json'),dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true,trimSprite=false,trim=false}
s:close();print('PASS Kira: four independently posed 48px/100ms Aseprite frames')
