-- fontproof / a tool for testing fonts
-- copyright 2016-2020 SIL International and released under the MIT/X11 license

local plain = SILE.require("classes/plain")
local fontproof = plain { id = "fontproof", base = plain }
SILE.scratch.fontproof = {}
SILE.scratch.fontproof = { runhead = {}, section = {}, subsection = {}, testfont = {}, groups = {} }

fontproof:declareFrame("content",     {left = "8%pw",             right = "92%pw",             top = "6%ph",              bottom = "96%ph" })
fontproof:declareFrame("runningHead", {left = "left(content)",  right = "right(content)",  top = "top(content)-3%ph", bottom = "top(content)-1%ph" })

-- set defaults
SILE.scratch.fontproof.testfont.family = "Gentium Plus"
SILE.scratch.fontproof.testfont.size = "8pt"
SILE.scratch.fontproof.runhead.family = "Gentium Plus"
SILE.scratch.fontproof.runhead.size = "5pt"
SILE.scratch.fontproof.section.family = "Gentium Plus"
SILE.scratch.fontproof.section.size = "12pt"
SILE.scratch.fontproof.subsection.family = "Gentium Plus"
SILE.scratch.fontproof.subsection.size = "12pt"
SILE.scratch.fontproof.sileversion = SILE.version

local hb = require("justenoughharfbuzz")
SILE.scratch.fontproof.hb =  hb.version()

function fontproof:init()
  self:loadPackage("linespacing")
  self:loadPackage("lorem")
  self:loadPackage("specimen")
  self:loadPackage("rebox")
  self:loadPackage("features")
  self:loadPackage("color")
  self:loadPackage("fontprooftexts")
  self:loadPackage("fontproofgroups")
  self:loadPackage("gutenberg-client")
  SILE.settings.set("document.parindent",SILE.nodefactory.glue(0))
  SILE.settings.set("document.spaceskip")
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames["content"]
  return plain.init(self)
end

fontproof.endPage = function(self)
  if SILE.scratch.fontproof.testfont.filename then
    runheadinfo = "Fontproof for: " .. SILE.scratch.fontproof.testfont.filename .. " - Input file: " .. 
SILE.masterFilename .. ".sil - " .. os.date("%A %d %b %Y %X %z %Z") .. " - SILE " .. SILE.scratch.fontproof.sileversion .. " - HarfBuzz " ..  SILE.scratch.fontproof.hb
  else
    runheadinfo = "Fontproof for: " .. SILE.scratch.fontproof.testfont.family .. " - Input file: " .. SILE.masterFilename .. ".sil - " .. os.date("%A %d %b %Y %X %z %Z") .. " - SILE " .. SILE.scratch.fontproof.sileversion .. " - HarfBuzz " ..  SILE.scratch.fontproof.hb
  end
  SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
    SILE.settings.set("document.rskip", SILE.nodefactory.hfillglue())
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue(0))
    SILE.settings.set("document.spaceskip", SILE.shaper:measureChar(" ").width)
    SILE.call("font", { family = SILE.scratch.fontproof.runhead.family,
                        size = SILE.scratch.fontproof.runhead.size
                      }, {runheadinfo})
    SILE.call("par")
  end)
  return plain.endPage(self);
end;

SILE.registerCommand("setTestFont", function (options, content)
  local testfilename = options.filename or nil
  local testfamily = options.family or nil
  if options.size then
    SILE.scratch.fontproof.testfont.size = options.size
  end
  if testfilename == nil then
    testfilename = fontfile
    -- fontfile is a variable that can only be set on the command line (see docs)
  end
  if testfamily then
    SILE.scratch.fontproof.testfont.family = testfamily
  else
    SILE.scratch.fontproof.testfont.filename = testfilename
  end
  options.family = testfamily
  options.filename = testfilename
  options.size = SILE.scratch.fontproof.testfont.size
  SILE.Commands["font"](options, {})
end)

-- optional way to override defaults
SILE.registerCommand("setRunHeadStyle", function (options, content)
  SILE.scratch.fontproof.runhead.family = options.family
  SILE.scratch.fontproof.runhead.size = options.size or "8pt"
end)

-- basic text styles
SILE.registerCommand("basic", function (options, content)
  SILE.settings.temporarily(function()
    SILE.call("font", { filename = SILE.scratch.fontproof.testfont.filename,
                        size = SILE.scratch.fontproof.testfont.size }, function ()
      SILE.call("raggedright",{},content)
    end)
  end)
end)

SILE.registerCommand("section", function (options, content)
  SILE.typesetter:leaveHmode()
  SILE.call("goodbreak")
  SILE.call("bigskip")
  SILE.call("noindent")
    SILE.call("font", { family = SILE.scratch.fontproof.section.family,
                        size = SILE.scratch.fontproof.section.size }, function ()
                          SILE.call("raggedright",{},content)
    end)
  SILE.call("novbreak")
  SILE.call("medskip")
  SILE.call("novbreak")
  SILE.typesetter:inhibitLeading()
end)

SILE.registerCommand("subsection", function (options, content)
  SILE.typesetter:leaveHmode()
  SILE.call("goodbreak")
  SILE.call("bigskip")
  SILE.call("noindent")
    SILE.call("font", { family = SILE.scratch.fontproof.subsection.family,
                        size = SILE.scratch.fontproof.subsection.size }, function ()
                          SILE.call("raggedright",{},content)
    end)
  SILE.call("novbreak")
  SILE.call("medskip")
  SILE.call("novbreak")
  SILE.typesetter:inhibitLeading()
end)

-- useful functions
local function fontsource (fam, file)
  if file then
    family = nil
    filename = file
  elseif fam then
    family = fam
    filename = nil
  elseif SILE.scratch.fontproof.testfont.filename then
    filename = SILE.scratch.fontproof.testfont.filename
    family = nil
  else
    family = SILE.scratch.fontproof.testfont.family
    filename = nil
  end
  return family, filename
end

local function sizesplit (str)
  sizes = {}
  for s in string.gmatch(str,"%w+") do
    if not string.find(s,"%a") then s = s .. "pt" end
    table.insert(sizes, s)
  end
  return sizes
end

local function processtext (str)
  local newstr = str
  local temp = str[1]
  if string.sub(temp,1,5) == "text_" then
    textname = string.sub(temp,6)
    if SILE.scratch.fontproof.texts[textname] ~= nil then
      newstr[1] = SILE.scratch.fontproof.texts[textname].text
    end
  end
  return newstr
end

-- special tests
SILE.registerCommand("proof", function (options, content)
  local proof = {}
  local procontent = processtext(content)
  if options.type ~= "pattern" then
    if options.heading then
      SILE.call("subsection", {}, {options.heading})
    else
      SILE.call("bigskip")
    end
  end
  if options.size then proof.sizes = sizesplit(options.size)
                  else proof.sizes = {SILE.scratch.fontproof.testfont.size} end
  if options.shapers then
    if SILE.settings.declarations["harfbuzz.subshapers"] then
      SILE.settings.set("harfbuzz.subshapers", options.shapers)
    else SU.warn("Can't use shapers on this version of SILE; upgrade!") end
  end
  proof.family, proof.filename = fontsource(options.family, options.filename)
  SILE.call("color", options, function ()
    for i = 1, #proof.sizes do
      SILE.settings.temporarily(function()
        local fontoptions ={ family = proof.family, filename = proof.filename, size = proof.sizes[i] }
        -- Pass on some options from \proof to \font.
        local tocopy = { "language"; "direction"; "script" }
        for i = 1,#tocopy do
          if options[tocopy[i]] then fontoptions[tocopy[i]] = options[tocopy[i]] end
        end
        -- Add feature options
        if options.featuresraw then fontoptions.features = options.featuresraw end
        if options.features then
          for i in SU.gtoke(options.features, ",") do
            if i.string then
              local feat = {}
              _,_,k,v = i.string:find("(%w+)=(.*)")
              feat[k] = v
              SILE.call("add-font-feature", feat, {})
            end
          end
        end
        SILE.Commands["font"](fontoptions, {})
        SILE.call("raggedright",{},procontent)
      end)
    end
  end)
end)

SILE.registerCommand("pattern", function(options, content)
  --SU.required(options, "reps")
  chars = std.string.split(options.chars,",")
  reps = std.string.split(options.reps,",")
  format = options.format or "table"
  size = options.size or SILE.scratch.fontproof.testfont.size
  cont = processtext(content)[1]
  paras = {}
  if options.heading then SILE.call("subsection", {}, {options.heading})
                     else SILE.call("bigskip") end
  for i, c in ipairs(chars) do
    local char, group = chars[i], reps[i]
    if string.sub(group,1,6) == "group_" then
      groupname = string.sub(group,7)
      gitems = SU.splitUtf8(SILE.scratch.fontproof.groups[groupname])
    else
      gitems = SU.splitUtf8(group)
    end
    local newcont = ""
    for r = 1, #gitems do
      newstr = string.gsub(cont,char,gitems[r])
      newcont = newcont .. char .. newstr
    end
    cont = newcont
  end
  if format == "table" then
    if chars[2] then
      paras = std.string.split(cont,chars[2])
    else
      table.insert(paras,cont)
    end
  elseif format == "list" then
    for i, c in ipairs(chars) do
      cont = string.gsub(cont,c,chars[1])
    end
    paras = std.string.split(cont,chars[1])
  else
    table.insert(paras,cont)
  end
  for i, p in ipairs(paras) do
    local para = paras[i]
    for j, c in ipairs(chars) do
      para = string.gsub(para,c," ")
    end
    SILE.Commands["proof"]({size=size,type="pattern"}, {para})
  end
end)

SILE.registerCommand("patterngroup", function(options, content)
  SU.required(options, "name")
  group = content[1]
  SILE.scratch.fontproof.groups[options.name] = group
end)

-- Try and find a dictionary
local dict = {}
local function shuffle(tbl)
  local size = #tbl
  for i = size, 1, -1 do
    local rand = math.random(size)
    tbl[i], tbl[rand] = tbl[rand], tbl[i]
  end
  return tbl
end

SILE.registerCommand("adhesion", function(options,content)
  local chars = SU.required(options, "characters")
  local f
  if #dict == 0 then
    if options.dict then
      f = io.open(options.dict, "r")
    else
      f,e = io.open("/usr/share/dict/words", "r")
      if not f then
        f = io.open("/usr/dict/words", "r")
      end
    end
    if f then
      for line in f:lines() do
        line = line:gsub("\n","")
        table.insert(dict, line)
      end
    else
      SU.error("Couldn't find a dictionary file to use")
    end
  end

  local wordcount = options.wordcount or 120
  words = {}
  shuffle(dict)
  for _, word in ipairs(dict) do
    if wordcount == 0 then break end
    -- This is fragile. Would be better to check and escape.
    if word:match("^["..chars.."]+$") then
      table.insert(words, word)
      wordcount = wordcount - 1
    end
  end
  SILE.typesetter:typeset(table.concat(words, " ")..".")
end)

local hasGlyph = function(g)
  local options = SILE.font.loadDefaults({})
  local newItems = SILE.shapers.harfbuzz:shapeToken(g, options)
  for i =1,#newItems do
    if newItems[i].gid > 0 then
      return true
    end
  end
  return false
end

SILE.registerCommand("pi", function (options, content)
  local digits = tonumber(options.digits) or 100
  local url = "https://uploadbeta.com/api/pi/?n="..(digits+4)
  if not pcall(function() http = require("ssl.https") end) then
    SU.error("Install luasec from luarocks")
  end
  local result, statuscode, content = http.request(url)
    if statuscode ~= 200 then
    SU.error("Could not read pi from "..url..": "..statuscode)
  end
  digits = "3."..result:sub(4,-2)
  for i = 1,#digits do
    SILE.typesetter:typeset(digits:sub(i,i))
    SILE.typesetter:pushPenalty({}) -- Ugly
  end
end)

SILE.registerCommand("unicharchart", function (options, content)
  local type = options.type or "all"
  local rows = tonumber(options.rows) or 16
  local columns = tonumber(options.columns) or 12
  local charsize = tonumber(options.charsize) or 14
  local usvsize = tonumber(options.usvsize) or 6
  local glyphs = {}
  local rangeStart
  local rangeEnd
  if type == "range" then
    rangeStart = tonumber(SU.required(options, "start"),16)
    rangeEnd = tonumber(SU.required(options, "end"),16)
    for cp = rangeStart,rangeEnd do
      local uni = SU.utf8charfromcodepoint(tostring(cp))
      glyphs[#glyphs+1] = { present = hasGlyph(uni), cp = cp, uni = uni }
    end
  else
    -- XXX For now, brute force inspect the glyph set
    local allglyphs = {}
    for cp = 0x1,0xFFFF do
      allglyphs[#allglyphs+1] = SU.utf8charfromcodepoint(tostring(cp))
    end
    local s = table.concat(allglyphs,"")
    local options = SILE.font.loadDefaults({})
    local items = SILE.shapers.harfbuzz:shapeToken(s, options)
    for i in ipairs(items) do
      local cp = SU.codepoint(items[i].text)
      if items[i].gid ~= 0 and cp > 0 then
        glyphs[#glyphs+1] = { present = true, cp = cp, uni = items[i].text }
      end
    end
  end
  local maxrows = math.ceil(#glyphs / rows)
  local maximum = rows * columns
  local width = SILE.measurement("100%fw"):absolute() / columns
  local done = 0
  while done < #glyphs do
    -- header row
    if type == "range" then
      SILE.call("font", {size=charsize}, function()
        for j = 0,columns-1 do
          local ix = done + j * rows
          local cp = rangeStart+ix
          if cp > rangeEnd then break end
          SILE.call("hbox")
          SILE.call("hbox", {}, function ()
            local header = string.format("%04X",cp)
            local hexDigits = string.len(header) - 1
            SILE.typesetter:typeset(header:sub(1,hexDigits))
          end)
          local nbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
          local centeringglue = SILE.nodefactory.glue((width-nbox.width)/2)
          SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = centeringglue
          SILE.typesetter:pushHbox(nbox)
          SILE.typesetter:pushGlue(centeringglue)
          SILE.call("hbox")
        end
      end)
      SILE.call("bigskip")
      SILE.call("hbox")
    end

    for i = 0,rows-1 do
      for j = 0,columns-1 do
        local ix = done + j * rows + i
        SILE.call("font", {size=charsize}, function()
          if glyphs[ix+1] then
              local char = glyphs[ix+1].uni
              if glyphs[ix+1].present then
                local left = SILE.shaper:measureChar(char).width
                local centeringglue = SILE.nodefactory.glue((width-left)/2)
                SILE.typesetter:pushGlue(centeringglue)
                SILE.typesetter:typeset(char)
                SILE.typesetter:pushGlue(centeringglue)
              else
                SILE.typesetter:pushGlue(SILE.nodefactory.glue(width))
              end
              SILE.call("hbox")
          end
        end)

      end
      SILE.call("par")
      SILE.call("hbox")
      SILE.call("font", {size=usvsize}, function()
        for j = 0,columns-1 do
          local ix = done + j * rows + i
          if glyphs[ix+1] then
            SILE.call("hbox", {}, function ()
              SILE.typesetter:typeset(string.format("%04X",glyphs[ix+1].cp))
            end)
            local nbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
            local centeringglue = SILE.nodefactory.glue((width-nbox.width)/2)
            SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = centeringglue
            SILE.typesetter:pushHbox(nbox)
            SILE.typesetter:pushGlue(centeringglue)
            SILE.call("hbox")
          end
        end
      end)
      SILE.call("bigskip")
    end
    SILE.call("pagebreak")
    done = done  +rows*columns
  end
end)

return fontproof
