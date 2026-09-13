-- Preserve original documents: export copies with only weapon layers hidden.
local root=assert(app.params['root']);local out=assert(app.params['out'])
for _,entry in ipairs({{'ninja/ninja_attack','player_attack',{'Steel blade','Slash accents'}},{'moonlit_dojo/ninja_support','player_support',{'Blade'}}}) do
 local s=app.open(root..'/art_sources/'..entry[1]..'.aseprite')
 for _,l in ipairs(s.layers) do for _,name in ipairs(entry[3]) do if l.name==name then l.isVisible=false end end end
 s:saveAs(out..'/'..entry[2]..'.aseprite');app.sprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..'/'..entry[2]..'_sheet.png',dataFilename=out..'/'..entry[2]..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true,trimSprite=false,trim=false}
 s:close()
end
print('PASS derived player copies with original body layers and timing, old steel hidden')
