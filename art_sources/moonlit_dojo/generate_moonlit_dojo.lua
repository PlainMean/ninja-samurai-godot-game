-- Authored/exported exclusively by Aseprite Sprite/Image APIs.
-- Support drawing routines adapted from supplied generators, never executed in place.
local out=app.params['out'] or '.'
app.fs.makeAllDirectories(out)
local function finish(s,name,tags)
 for _,t in ipairs(tags) do local tag=s:newTag(t[2],t[3]);tag.name=t[1];tag.aniDir=AniDir.FORWARD end
 s:saveAs(app.fs.joinPath(out,name..'.aseprite'))
 app.sprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=app.fs.joinPath(out,name..'_sheet.png'),dataFilename=app.fs.joinPath(out,name..'.json'),dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true,trimSprite=false,trim=false,splitLayers=false,splitTags=false,innerPadding=0,borderPadding=0,shapePadding=0}
 s:close()
end

do
-- All rasterization is performed with Aseprite Image:drawPixel.
local s = Sprite(32,32,ColorMode.RGB)

local C = {
 ink={9,12,23}, deep={17,23,39}, navy={29,40,60}, light={46,63,83},
 edge={68,86,103}, red={183,32,54}, scarlet={239,62,71}, wine={104,22,43},
 skin={213,164,125}, skinlight={248,206,155}, steel={157,184,198},
 white={228,247,247}, blue={86,122,148}, arc={164,218,228,210}
}
for k,v in pairs(C) do C[k]=app.pixelColor.rgba(v[1],v[2],v[3],v[4] or 255) end
local palette=Palette(14)
palette:setColor(0,Color{r=0,g=0,b=0,a=0})
for i,k in ipairs({'ink','deep','navy','light','edge','red','scarlet','wine','skin','skinlight','steel','white','blue'}) do palette:setColor(i,Color(C[k])) end
s:setPalette(palette)
local img
local function px(x,y,c)
 x=math.floor(x); y=math.floor(y)
 if x>=0 and x<32 and y>=0 and y<30 then img:drawPixel(x,y,C[c]) end
end
local function rect(x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end
end
local function line(x0,y0,x1,y1,c,r)
 local n=math.max(math.abs(x1-x0),math.abs(y1-y0))
 for i=0,n do
  local t=n==0 and 0 or i/n
  local x=math.floor(x0+(x1-x0)*t+.5)
  local y=math.floor(y0+(y1-y0)*t+.5)
  rect(x-(r or 0),y-(r or 0),1+2*(r or 0),1+2*(r or 0),c)
 end
end
local function poly(p,c)
 for y=0,31 do for x=0,31 do
  local inside=false
  local j=#p
  for i=1,#p do
   local a,b=p[i],p[j]
   if (a[2]>y+.5)~=(b[2]>y+.5) and x+.5<(b[1]-a[1])*(y+.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
   j=i
  end
  if inside then px(x,y,c) end
 end end
end
local layers={}
s.layers[1].name='Scarf'
layers[1]=s.layers[1]
for _,name in ipairs({'Body','Blade'}) do local l=s:newLayer(); l.name=name; layers[#layers+1]=l end
for i=2,12 do s:newEmptyFrame() end
-- Head origin, front elbow, hand, blade tip, rear foot, forward foot.
local poses={
 {11,7,19,18,22,16,28,7,9,22}, {11,7,19,18,22,16,28,7,9,22},
 {10,8,19,15,21,13,27,4,9,22}, {10,8,18,13,21,11,25,2,9,22},
 {9,10,16,21,19,20,27,15,8,21}, {8,12,15,23,18,22,26,18,8,20}, {7,13,15,24,18,23,26,20,8,20},
 {9,8,15,22,18,20,25,15,8,21}, {10,9,17,21,20,19,27,13,9,22},
 {10,11,18,25,21,23,28,20,9,22}, {10,13,18,27,21,25,29,24,9,22}, {11,15,19,28,22,27,30,27,9,22}
}
for f,p in ipairs(poses) do
 s.frames[f].duration=({400,400,100,100,100,100,100,100,100,100,100,200})[f]/1000
 local hx,hy,ex,ey,gx,gy,tx,ty,back,front=table.unpack(p)
 local bx,by=hx+2,math.min(23,hy+10)
 for li,l in ipairs(layers) do
  img=Image(32,32,ColorMode.RGB); img:clear()
  if li==1 then
   local lift=({0,-1,-2,-2,0,1,2,-2,0,0,1,2})[f]
   poly({{hx+2,hy+9},{hx-2,hy+7},{3,hy+5+lift},{5,hy+9+lift},{1,hy+11+lift},{hx-1,hy+11}},'wine')
   poly({{hx+1,hy+9},{hx-3,hy+8},{3,hy+5+lift},{6,hy+8+lift},{4,hy+9+lift},{hx-1,hy+10}},'red')
   line(5,hy+7+lift,hx-1,hy+9,'scarlet')
  elseif li==2 then
   -- Two bent legs and planted tabi boots.
   line(bx,by+4,back+2,25,'ink',2); line(back+2,25,back,28,'ink',2)
   line(bx,by+4,back+2,25,'navy',1); line(back+2,25,back,28,'deep',1)
   line(bx+2,by+4,front-2,24,'ink',2); line(front-2,24,front,28,'ink',2)
   line(bx+2,by+4,front-2,24,'light',1); line(front-2,24,front,28,'navy',1)
   rect(back-2,28,6,2,'ink'); rect(front-2,28,7,2,'ink')
   line(front-1,28,front+3,28,'light'); line(back-1,28,back+1,28,'navy')
   poly({{hx,hy+8},{hx+6,hy+8},{bx+5,by+5},{bx-3,by+6},{hx-2,hy+13}},'ink')
   poly({{hx+1,hy+9},{hx+5,hy+9},{bx+3,by+3},{bx-2,by+4},{hx-1,hy+13}},'navy')
   line(hx+2,hy+10,bx+1,by+2,'light')
   line(hx,hy+11,hx-2,hy+15,'ink',1); line(hx-2,hy+15,hx+2,hy+17,'ink',1)
   line(hx,hy+11,hx-2,hy+15,'light'); line(hx-2,hy+15,hx+2,hy+17,'navy')
   line(bx-2,by+3,bx+4,by+3,'ink'); line(bx-1,by+4,bx+3,by+4,'wine')
   -- Hood, eye slit, and face mask: facing right.
   poly({{hx+1,hy-1},{hx+6,hy-1},{hx+8,hy+2},{hx+8,hy+7},{hx+5,hy+9},{hx,hy+8},{hx-2,hy+5},{hx-2,hy+2}},'ink')
   poly({{hx+1,hy},{hx+5,hy},{hx+7,hy+2},{hx+7,hy+6},{hx+4,hy+8},{hx,hy+7},{hx-1,hy+4}},'navy')
   line(hx+1,hy,hx+4,hy,'light'); line(hx-1,hy+2,hx-1,hy+4,'light')
   rect(hx+3,hy+3,5,2,'skin'); line(hx+4,hy+3,hx+7,hy+3,'skinlight')
   px(hx+6,hy+3,'ink'); px(hx+7,hy+3,'white')
   rect(hx+2,hy+5,6,2,'deep'); line(hx+3,hy+5,hx+6,hy+5,'light')
   line(hx,hy+8,hx+5,hy+8,'red'); line(hx+1,hy+8,hx+3,hy+8,'scarlet')
   line(hx+5,hy+11,ex,ey,'ink',2); line(ex,ey,gx,gy,'ink',1)
   line(hx+5,hy+11,ex,ey,'light',1); line(ex,ey,gx,gy,'navy')
   rect(gx-1,gy-1,3,3,'ink'); rect(gx,gy-1,2,2,'edge')
  elseif li==3 then
   local dx,dy=tx-gx,ty-gy
   local n=math.sqrt(dx*dx+dy*dy); local ux,uy=dx/n,dy/n
   local sx,sy=math.floor(gx+ux*3+.5),math.floor(gy+uy*3+.5)
   line(gx,gy,sx,sy,'ink',1); line(gx,gy,sx,sy,'wine')
   line(sx-uy*2,sy+ux*2,sx+uy*2,sy-ux*2,'steel')
   local ax,ay=sx+ux,sy+uy
   line(ax,ay,tx,ty,'blue',1)
   line(ax,ay,tx,ty,'steel'); line(ax-uy,ay+ux,tx,ty,'white')
  elseif li==4 then
   if f==3 then
    line(20,2,25,3,'blue'); line(25,3,29,6,'arc'); line(29,6,31,10,'white')
    line(23,5,26,6,'arc')
   elseif f==4 then
    line(29,7,31,11,'blue'); line(31,12,31,16,'arc')
    line(27,10,29,13,'arc'); px(30,21,'white'); px(28,22,'blue')
   elseif f==5 then
    line(31,21,30,25,'arc'); line(30,25,27,28,'blue'); px(29,19,'white')
   end
  end
  s:newCel(l,f,img,Point(0,0))
 end
end
finish(s,'ninja_support',{{'idle',1,2},{'guard',3,4},{'dodge',5,7},{'hurt',8,9},{'defeat',10,12}})
end
do
-- Run from this repository: ~/.local/bin/aseprite --batch --script generate_samurai.lua
-- All rasterization occurs here, one native pixel at a time, inside Aseprite.
local spr = Sprite(32, 32, ColorMode.RGB)

local colors = {
  ink='151625', deep='23253e', armor='353b60', mid='505c80', light='7485a0',
  redDark='572c40', red='914758', redLight='be6b70',
  goldDark='766044', gold='b89a61', goldLight='e0c887',
  skin='c29880', skinLight='ebc6a0', steelDark='6d8397', steel='b7cbd3',
  white='edf2df', trail='7fabb8', trailLight='c5ded9'
}
local P = {}
for k,v in pairs(colors) do
  P[k] = app.pixelColor.rgba(tonumber(v:sub(1,2),16), tonumber(v:sub(3,4),16), tonumber(v:sub(5,6),16),255)
end
local palette = Palette(19)
palette:setColor(0,Color{r=0,g=0,b=0,a=0})
local order={'ink','deep','armor','mid','light','redDark','red','redLight','goldDark','gold','goldLight','skin','skinLight','steelDark','steel','white','trail','trailLight'}
for i,k in ipairs(order) do palette:setColor(i,Color(P[k])) end
spr:setPalette(palette)

local body = spr.layers[1]; body.name='Armor'
local weapon = spr:newLayer(); weapon.name='Arms and blade'
local fx = spr:newLayer(); fx.name='Cloth'
local img
local function px(x,y,c)
  x=math.floor(x); y=math.floor(y)
  if x<0 or x>=32 or y<0 or y>=30 then return end
  img:drawPixel(x,y,P[c])
end
local function rect(x1,y1,x2,y2,c)
  for y=y1,y2 do for x=x1,x2 do px(x,y,c) end end
end
local function line(x0,y0,x1,y1,c)
  local dx,dy=math.abs(x1-x0),-math.abs(y1-y0)
  local sx,sy=x0<x1 and 1 or -1,y0<y1 and 1 or -1
  local err=dx+dy
  while true do
    px(x0,y0,c)
    if x0==x1 and y0==y1 then break end
    local e=2*err
    if e>=dy then err=err+dy; x0=x0+sx end
    if e<=dx then err=err+dx; y0=y0+sy end
  end
end
local function poly(points,c)
  local ymin,ymax=31,0
  for _,p in ipairs(points) do ymin=math.min(ymin,p[2]); ymax=math.max(ymax,p[2]) end
  for y=ymin,ymax do
    local hits={}
    for j,a in ipairs(points) do
      local b=points[j % #points+1]
      if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then
        hits[#hits+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])
      end
    end
    table.sort(hits)
    for j=1,#hits-1,2 do for x=math.ceil(hits[j]),math.floor(hits[j+1]) do px(x,y,c) end end
  end
  for j,a in ipairs(points) do local b=points[j % #points+1]; line(a[1],a[2],b[1],b[2],c) end
end
local function limb(a,b,c)
  line(a[1],a[2]-1,b[1],b[2]-1,'ink')
  line(a[1],a[2]+1,b[1],b[2]+1,'ink')
  line(a[1]-1,a[2],b[1]-1,b[2],'ink')
  line(a[1]+1,a[2],b[1]+1,b[2],'ink')
  line(a[1],a[2],b[1],b[2],c)
end
local function stamp(rows,ox,oy,key)
  for y,row in ipairs(rows) do for x=1,#row do
    local c=key[row:sub(x,x)]; if c then px(ox+x-1,oy+y-1,c) end
  end end
end
local helmet={
  '....g....g....',
  '....Go..oG....',
  '....gGooGg....',
  '...ooGGGoo....',
  '..oammmmaao...',
  '.oammllmaaaao.',
  '.omaaaaaaaao..',
  'ooooddddoSSo..',
  '.oamaadoSwo...',
  'oamadddoidoo..',
  '.oaddddommo...',
  '..oooooddo....'
}
local key={o='ink',d='deep',a='armor',m='mid',l='light',g='goldDark',G='gold',S='skin',w='skinLight',i='steelDark'}
local poses={
 {x=0,y=0,rear=10,front=19,elbow={18,19},hand={22,19},tip={28,8},tail=0},
 {x=0,y=0,rear=10,front=19,elbow={18,19},hand={22,19},tip={28,8},tail=1},
 {x=0,y=-1,rear=10,front=19,elbow={18,15},hand={19,13},tip={29,5},tail=2},
 {x=-1,y=-2,rear=9,front=18,elbow={15,13},hand={14,9},tip={25,1},tail=3},
 {x=-2,y=1,rear=9,front=18,elbow={16,23},hand={19,21},tip={27,15},tail=2},
 {x=-1,y=0,rear=10,front=19,elbow={18,21},hand={21,20},tip={29,12},tail=1},
 {x=0,y=3,rear=10,front=19,elbow={18,25},hand={21,24},tip={29,21},tail=0},
 {x=0,y=5,rear=10,front=19,elbow={18,27},hand={21,26},tip={29,25},tail=1},
 {x=1,y=7,rear=10,front=19,elbow={19,28},hand={22,28},tip={29,28},tail=2}
}

for f,p in ipairs(poses) do
  if f>1 then spr:newEmptyFrame() end
  spr.frames[f].duration=({400,400,100,100,100,100,100,100,200})[f]/1000
  local x,y=p.x,p.y
  img=Image(32,32,ColorMode.RGB)
  -- Feet and legs: the leading leg opens through the strike; both soles stay at y=29.
  limb({12+x,23+y},{p.rear,28},'deep')
  limb({16+x,23+y},{p.front-1,28},'armor')
  line(13+x,24+y,p.rear+1,27,'mid')
  line(17+x,24+y,p.front,27,'mid')
  rect(p.rear-2,28,p.rear+1,29,'ink'); rect(p.rear-1,28,p.rear+1,28,'steelDark')
  rect(p.front-1,28,p.front+3,29,'ink'); rect(p.front,28,p.front+2,28,'light')
  -- Split armored skirt, with dark seams and restrained horizontal plate edges.
  poly({{10+x,20+y},{18+x,20+y},{21+x,25+y},{16+x,26+y},{14+x,24+y},{10+x,26+y},{8+x,25+y}},'ink')
  poly({{10+x,22+y},{13+x,22+y},{12+x,25+y},{9+x,25+y}},'armor')
  poly({{15+x,22+y},{18+x,22+y},{20+x,25+y},{16+x,25+y}},'armor')
  line(10+x,23+y,12+x,23+y,'mid'); line(16+x,23+y,18+x,23+y,'mid')
  line(9+x,25+y,11+x,25+y,'mid'); line(17+x,25+y,19+x,25+y,'mid')
  -- Breastplate and rear shoulder.
  poly({{11+x,15+y},{17+x,15+y},{19+x,18+y},{18+x,22+y},{10+x,22+y},{9+x,18+y}},'ink')
  rect(11+x,16+y,17+x,20+y,'armor')
  line(12+x,16+y,16+x,16+y,'light')
  line(12+x,18+y,17+x,18+y,'mid')
  line(11+x,20+y,17+x,20+y,'mid')
  px(12+x,17+y,'goldDark'); px(16+x,19+y,'goldDark')
  rect(10+x,21+y,18+x,22+y,'redDark')
  line(11+x,21+y,18+x,21+y,'red')
  rect(16+x,21+y,17+x,22+y,'redLight')
  poly({{9+x,16+y},{12+x,16+y},{12+x,19+y},{8+x,19+y}},'ink')
  line(9+x,17+y,11+x,17+y,'mid'); line(9+x,18+y,11+x,18+y,'armor')
  -- Scabbard angles behind the sash.
  line(8+x,23+y,5+x,26+y,'ink'); line(8+x,23+y,6+x,25+y,'deep'); px(8+x,23+y,'gold')
  -- Kabuto crest, flared neck plates, right-facing eye and steel face guard.
  stamp(helmet,8+x,5+y,key)
  spr:newCel(body,f,img,Point(0,0))

  img=Image(32,32,ColorMode.RGB)
  -- Two-handed grip and bent elbow produce a different pose on each frame.
  limb({15+x,17+y},p.elbow,'armor')
  limb(p.elbow,p.hand,'mid')
  local h=p.hand; local t=p.tip
  local dx,dy=t[1]-h[1],t[2]-h[2]
  local n=math.max(math.abs(dx),math.abs(dy))
  local ux,uy=dx/n,dy/n
  local function round(v) return math.floor(v+0.5) end
  local base={round(h[1]+ux*3),round(h[2]+uy*3)}
  local pom={round(h[1]-ux*2),round(h[2]-uy*2)}
  line(pom[1],pom[2],base[1],base[2],'ink')
  line(h[1],h[2],base[1],base[2],'redDark')
  -- Steel blade: dark back edge, cool midtone, bright cutting edge and pointed tip.
  local nx,ny=math.abs(dx)>=math.abs(dy) and 0 or 1,math.abs(dx)>=math.abs(dy) and 1 or 0
  line(base[1]+nx,base[2]+ny,t[1]+nx,t[2]+ny,'ink')
  line(base[1],base[2],t[1],t[2],'steel')
  line(base[1]-nx,base[2]-ny,t[1]-nx,t[2]-ny,'white')
  px(t[1],t[2],'white')
  -- Brass tsuba crosses the blade at its root.
  line(base[1]-nx*2,base[2]-ny*2,base[1]+nx*2,base[2]+ny*2,'goldDark')
  px(base[1]-nx,base[2]-ny,'goldLight')
  px(h[1],h[2],'skinLight'); px(h[1]-1,h[2]+1,'skin')
  px(pom[1],pom[2],'goldDark')
  spr:newCel(weapon,f,img,Point(0,0))

  img=Image(32,32,ColorMode.RGB)
  -- Red cloth behind the torso, changing silhouette with acceleration.
  local ty=21+y
  poly({{11+x,ty},{8+x,ty-1},{5+x,ty-p.tail},{6+x,ty+2},{10+x,ty+2}},'redDark')
  line(6+x,ty+1-math.floor(p.tail/2),10+x,ty+1,'red')
  px(7+x,ty-math.floor(p.tail/2),'redLight')
  spr:newCel(fx,f,img,Point(0,0))
end
finish(spr,'samurai_support',{{'idle',1,2},{'warn_cut',3,3},{'warn_heavy',4,4},{'hurt',5,6},{'defeat',7,9}})
end
local colors={'151625','23253E','353B60','505C80','7485A0','572C40','914758','766044','B89A61','E0C887','B7CBD3','EDF2DF','7FABB8','493B45','9AAEB2'}
local P={};for i,h in ipairs(colors) do P[i]=app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local img,W,H
local function px(x,y,c) assert(x>=0 and x<W and y>=0 and y<H,'canvas bounds');img:drawPixel(x,y,P[c]) end
local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end end
local function line(x,y,xx,yy,c) local n=math.max(math.abs(xx-x),math.abs(yy-y));for i=0,n do local t=n==0 and 0 or i/n;px(math.floor(x+(xx-x)*t+.5),math.floor(y+(yy-y)*t+.5),c) end end
local function disk(x,y,r,c) for yy=y-r,y+r do for xx=x-r,x+r do if (xx-x)^2+(yy-y)^2<=r*r then px(xx,yy,c) end end end end
local function make(name,w,h,layers,tags,draw)
 W=w;H=h;local s=Sprite(w,h,ColorMode.RGB);local pal=Palette(16);pal:setColor(0,Color{r=0,g=0,b=0,a=0});for i,c in ipairs(P) do pal:setColor(i,Color(c)) end;s:setPalette(pal)
 local ls={s.layers[1]};ls[1].name=layers[1];for i=2,#layers do ls[i]=s:newLayer();ls[i].name=layers[i] end
 local f=0;local ranges={}
 for _,tag in ipairs(tags) do local first=f+1;for k,ms in ipairs(tag[2]) do f=f+1;if f>1 then s:newEmptyFrame() end;s.frames[f].duration=ms/1000;for l,layer in ipairs(ls) do img=Image(w,h,ColorMode.RGB);draw(f,l,tag[1],k-1);s:newCel(layer,f,img,Point(0,0)) end end;ranges[#ranges+1]={tag[1],first,f} end
 finish(s,name,ranges)
end
make('dojo_backdrops',195,128,{'Sky or wall','Architecture','Floor'},{{'gate',{100}},{'courtyard',{100}},{'dojo',{100}}},function(f,l)
 if l==1 then
  rect(0,0,195,128,1);rect(0,22,195,77,2)
  if f<3 then disk(96,26,16,4);disk(94,24,13,11);rect(0,62,195,37,3);for x=0,194 do line(x,60+math.floor(math.abs((x%53)-26)/3),x,98,2) end
  else rect(13,8,169,89,14);rect(22,19,151,72,4) end
 elseif l==2 then
  if f==1 then
   rect(19,32,8,67,14);rect(168,32,8,67,14);rect(15,28,166,7,14);rect(22,36,151,3,8)
   rect(13,25,169,5,1);rect(24,20,147,5,1);line(26,22,167,22,4);line(7,27,25,22,1);line(170,22,188,27,1)
   rect(0,85,195,14,4);line(0,85,194,85,5);rect(0,89,195,2,3)
  elseif f==2 then
   rect(0,77,195,22,4);line(0,77,194,77,5);for x=0,194,25 do line(x,79,x,97,3) end
   for x=5,23,6 do rect(x,20,2,57,3);for y=28,67,13 do line(x-3,y,x+5,y-5,4);px(x,y+2,5) end end
   for x=176,188,6 do rect(x,12,2,65,3);for y=20,66,12 do line(x-5,y,x+3,y-5,4) end end
  else
   for x=24,156,33 do rect(x,20,30,67,11);rect(x+2,22,26,63,15);line(x+15,20,x+15,86,4);line(x,42,x+29,42,4);line(x,64,x+29,64,4) end
   rect(72,16,50,52,2);disk(97,42,22,3);disk(97,39,15,11);rect(95,17,3,49,14);line(76,42,118,42,14)
   rect(14,88,168,11,4);line(14,88,181,88,8)
  end
 else
  rect(0,99,195,29,5);line(0,99,194,99,11);rect(0,101,195,3,4)
  for y=108,126,9 do line(0,y,194,y,4);for x=(y%2)*18,194,39 do line(x,y+1,x,math.min(127,y+8),4) end end
  for x=11,180,37 do line(x,106,x+12,106,15) end
 end
end)
make('dojo_props',16,32,{'Fixture','Light or emblem'},{{'lantern',{300,300}},{'banner_gate',{100}},{'banner_retainer',{100}},{'banner_master',{100}}},function(f,l)
 if f<=2 then
  if l==1 then line(7,0,7,5,8);rect(3,5,10,2,1);rect(2,7,12,15,8);rect(3,22,10,2,1);line(7,24,7,29,8);rect(6,29,3,2,9)
  else rect(4,8,8,13,9);rect(6,8,4,13,10);line(4,12,11,12,8);line(4,17,11,17,8);rect(f==1 and 5 or 8,9,2,2,12);rect(f==1 and 8 or 5,18,2,2,12) end
 else
  if l==1 then rect(1,2,14,2,8);rect(3,4,10,25,2);line(3,4,3,28,8);line(12,4,12,28,8);line(3,29,6,26,2);line(9,26,12,29,2)
  else for n=1,f-2 do rect(5,7+n*4,6,2,10) end;px(7,24,9) end
 end
end)
make('combat_fx',32,32,{'Core','Accents'},{{'block',{60,60,100}},{'dodge',{80,80,80}},{'hit',{60,60,100}},{'seal',{100,100,200}}},function(f,l,tag,k)
 local r=3+k*4
 if tag=='block' then
  if l==1 then line(16-r,16,16+r,16,11);line(16,16-r,16,16+r,12) else line(16-r,16-r,13,13,9);line(19,19,16+r,16+r,10);px(19+r,13-r,11) end
 elseif tag=='dodge' then
  if l==1 then line(7-k*2,23-k,13-k,20-k,15);line(15+k,24-k,23+k*2,22-k,5) else px(4+k,20-k*2,15);line(11,26-k,20+k,26-k,4) end
 elseif tag=='hit' then
  if l==1 then line(14-r,14-r,12,12,11);line(20,20,18+r,18+r,11) else line(18+r,14-r,20,12,7);line(12,20,14-r,18+r,7) end
 else
  if l==1 then line(16-r,16,16,16-r,10);line(16,16-r,16+r,16,10);line(16+r,16,16,16+r,10);line(16,16+r,16-r,16,10) else px(4+k,6,12);px(26-k,8+k,12);line(15,14,17,16,12) end
 end
end)
local tags={};for _,name in ipairs({'heart_full','heart_empty','seal_empty','seal_full','cut','heavy','double_cut','mend','long_breath','iron_resolve'}) do tags[#tags+1]={name,{100}} end
make('dojo_icons',16,16,{'Outline','Fill'},tags,function(f,l)
 if f<=2 then
  if l==1 then line(1,5,4,2,11);line(4,2,8,5,11);line(8,5,11,2,11);line(11,2,14,5,11);line(1,5,1,7,11);line(14,5,14,7,11);line(1,7,8,14,11);line(14,7,8,14,11)
  else for y=5,12 do local half=math.min(5,13-y);line(8-half,y,8+half,y,f==1 and 7 or 2) end;if f==1 then line(3,5,5,5,10) end end
 elseif f<=4 then
  if l==1 then line(5,1,10,1,9);line(10,1,14,5,9);line(14,5,14,10,9);line(14,10,10,14,9);line(10,14,5,14,9);line(5,14,1,10,9);line(1,10,1,5,9);line(1,5,5,1,9)
  else rect(4,4,8,8,f==4 and 10 or 2);if f==4 then line(5,8,7,10,1);line(7,10,11,5,1) end end
 elseif f==5 or f==7 then
  if l==1 then line(3,13,12,2,11);line(4,13,13,2,12);line(2,10,6,13,9) elseif f==7 then line(2,9,9,1,11);line(1,7,4,10,9) else px(13,1,12) end
 elseif f==6 then
  if l==1 then line(3,13,12,2,11);line(7,7,12,2,12);line(8,8,13,3,11);line(2,11,5,14,9) else line(2,3,2,6,10);px(2,8,10);line(8,11,12,13,7) end
 elseif f==8 then
  if l==1 then rect(2,2,12,12,3);rect(6,3,4,10,11);rect(3,6,10,4,11) else rect(7,4,2,8,12);rect(4,7,8,2,12) end
 elseif f==9 then
  if l==1 then line(2,5,12,5,11);line(2,8,10,8,13);line(4,11,13,11,5) else px(13,4,11);px(11,7,13);px(14,10,5) end
 else
  if l==1 then line(2,2,13,2,9);line(2,2,2,9,9);line(13,2,13,9,9);line(2,9,8,14,9);line(13,9,8,14,9) else rect(4,4,8,5,4);line(5,9,8,12,4);line(8,12,11,9,4);line(7,5,7,9,11) end
 end
end)
print('Created six layered sources, 51 frames; Aseprite '..tostring(app.version))
