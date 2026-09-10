-- Run from this repository: ~/.local/bin/aseprite --batch --script generate_samurai.lua
-- All rasterization occurs here, one native pixel at a time, inside Aseprite.
local spr = Sprite(32, 32, ColorMode.RGB)
spr.filename = 'samurai_attack.aseprite'
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

local body = spr.layers[1]; body.name='01 • Indigo armor & sash'
local weapon = spr:newLayer(); weapon.name='02 • Arms & steel katana'
local fx = spr:newLayer(); fx.name='03 • Cut accent'
local img
local function px(x,y,c)
  x=math.floor(x); y=math.floor(y)
  assert(x>=0 and x<32 and y>=0 and y<32, 'Pixel outside canvas: '..x..','..y)
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
  {x=0,y=0, rear=10,front=19,elbow={18,19},hand={22,19},tip={28,8},tail=0},
  {x=-1,y=1,rear=9,front=18,elbow={10,19},hand={9,16},tip={3,5},tail=1},
  {x=0,y=-1,rear=10,front=19,elbow={18,15},hand={16,12},tip={28,2},tail=2},
  {x=2,y=1,rear=9,front=23,elbow={18,20},hand={19,18},tip={31,19},tail=3},
  {x=2,y=1,rear=10,front=23,elbow={19,21},hand={20,20},tip={30,30},tail=4},
  {x=1,y=0,rear=10,front=20,elbow={19,20},hand={22,20},tip={30,12},tail=1}
}

for f,p in ipairs(poses) do
  if f>1 then spr:newEmptyFrame() end
  spr.frames[f].duration=0.100
  local x,y=p.x,p.y
  img=Image(32,32,ColorMode.RGB)
  -- Feet and legs: the leading leg opens through the strike; both soles stay at y=29.
  limb({12+x,23+y},{p.rear,28},'deep')
  limb({16+x,23+y},{p.front-1,28},'armor')
  line(13+x,24+y,p.rear+1,27,'mid')
  line(17+x,24+y,p.front,27,'mid')
  rect(p.rear-2,28,p.rear+1,29,'ink'); rect(p.rear-1,28,p.rear+1,28,'steelDark')
  rect(p.front-1,28,p.front+3,29,'ink'); rect(p.front,28,p.front+2,28,'light')
  -- Red cloth behind the torso, changing silhouette with acceleration.
  local ty=21+y
  poly({{11+x,ty},{8+x,ty-1},{5+x,ty-p.tail},{6+x,ty+2},{10+x,ty+2}},'redDark')
  line(6+x,ty+1-math.floor(p.tail/2),10+x,ty+1,'red')
  px(7+x,ty-math.floor(p.tail/2),'redLight')
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
  if f==3 then
    line(24,3,27,3,'trail'); px(29,4,'trail')
  elseif f==4 then
    -- Broken arc leaves breathing room around the helmet and katana.
    line(23,3,26,5,'trail'); line(27,6,29,9,'trail')
    line(30,10,30,14,'trail'); line(29,9,29,14,'trailLight')
    line(28,7,28,10,'white'); px(30,16,'white')
  elseif f==5 then
    line(30,22,30,25,'trail'); line(29,26,28,27,'trail')
    px(27,28,'trailLight')
  end
  spr:newCel(fx,f,img,Point(0,0))
end
local tag=spr:newTag(1,6)
tag.name='attack'; tag.aniDir=AniDir.FORWARD
tag.color=Color{r=145,g=71,b=88,a=255}
app.activeSprite=spr
app.activeFrame=spr.frames[1]
spr:saveAs('samurai_attack.aseprite')
print('Created samurai_attack.aseprite: 32x32, 6 frames, 100 ms, attack tag, 3 layers')
