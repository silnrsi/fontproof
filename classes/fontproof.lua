-- fontproof / a tool for testing fonts
-- copyright 2016 SIL International and released under the MIT/X11 license

local plain = SILE.require("classes/plain")
local fontproof = plain { id = "fontproof", base = plain }
SILE.scratch.fontproof = {}
SILE.scratch.fontproof = { runhead = {}, section = {}, subsection = {}, testfont = {}, groups = {} }

fontproof:declareFrame("content",     {left = "8%pw",             right = "92%pw",             top = "6%ph",              bottom = "96%ph" })
fontproof:declareFrame("runningHead", {left = "left(content)",  right = "right(content)",  top = "top(content)-3%ph", bottom = "top(content)-1%ph" })


-- set defaults
SILE.scratch.fontproof.testfont.filename = "packages/fontproofsupport/Lato2OFL/Lato-Light.ttf"
SILE.scratch.fontproof.testfont.size = "8pt"
SILE.scratch.fontproof.runhead.filename = "packages/fontproofsupport/Lato2OFL/Lato-Light.ttf"
SILE.scratch.fontproof.runhead.size = "8pt"
SILE.scratch.fontproof.section.filename = "packages/fontproofsupport/Lato2OFL/Lato-Heavy.ttf"
SILE.scratch.fontproof.section.size = "12pt"
SILE.scratch.fontproof.subsection.filename = "packages/fontproofsupport/Lato2OFL/Lato-Light.ttf"
SILE.scratch.fontproof.subsection.size = "12pt"

function fontproof:init()
  self:loadPackage("linespacing")
  self:loadPackage("lorem")
  self:loadPackage("specimen")
  self:loadPackage("fontprooftexts")
  self:loadPackage("fontproofgroups")
  SILE.settings.set("document.parindent",SILE.nodefactory.zeroGlue)
  SILE.settings.set("document.spaceskip")
  self.pageTemplate.firstContentFrame = self.pageTemplate.frames["content"]
  return plain.init(self)
end

fontproof.endPage = function(self)
  if SILE.scratch.fontproof.testfont.family then
    runheadinfo = SILE.masterFilename .. " - " .. SILE.scratch.fontproof.testfont.family .. " - " .. os.date("%d %b %Y %X")
  else
    runheadinfo = SILE.masterFilename .. " - " .. SILE.scratch.fontproof.testfont.filename .. " - " .. os.date("%d %b %Y %X")
  end
  SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
    SILE.settings.set("document.rskip", SILE.nodefactory.hfillGlue)
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.settings.set("document.spaceskip", SILE.length.new({ length = SILE.shaper:measureDim(" ") }))
    SILE.call("font", { filename = SILE.scratch.fontproof.runhead.filename,
                        size = SILE.scratch.fontproof.runhead.size
                      }, {runheadinfo})
    SILE.call("par")
  end)
  return plain.endPage(self);
end;

SILE.registerCommand("setTestFont", function (options, content)
  SILE.scratch.fontproof.testfont.size = options.size or "16pt"
  if options.family then
    SILE.scratch.fontproof.testfont.family = options.family
  else
    SILE.scratch.fontproof.testfont.filename = options.filename
  end
  local testfamily = options.family or nil
  local testfilename = options.filename or nil
  SILE.Commands["font"]({ family = testfamily, filename = testfilename, size = SILE.scratch.fontproof.testfont.size }, {})
end)

-- optional way to override defaults
SILE.registerCommand("setRunHeadStyle", function (options, content)
  SILE.scratch.fontproof.runhead.filename = options.filename
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
    SILE.call("font", { filename = SILE.scratch.fontproof.section.filename,
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
    SILE.call("font", { filename = SILE.scratch.fontproof.subsection.filename,
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
  if fam then
    family = fam
    filename = nil
  elseif file then
    family = nil
    filename = file
  else
    family = SILE.scratch.fontproof.testfont.family
    filename = SILE.scratch.fontproof.testfont.filename
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
  proof.family, proof.filename = fontsource(options.family, options.filename)
  for i = 1, #proof.sizes do
    SILE.settings.temporarily(function()
      SILE.Commands["font"]({ family = proof.family, filename = proof.filename, size = proof.sizes[i] }, {})
      SILE.call("raggedright",{},procontent)
    end)
  end
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

return fontproof
