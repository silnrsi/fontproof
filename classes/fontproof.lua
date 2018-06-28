-- fontproof / a tool for testing fonts
-- copyright 2016 SIL International and released under the MIT/X11 license

local plain = SILE.require("classes/plain")
local fontproof = plain { id = "fontproof", base = plain }
SILE.scratch.fontproof = {}
SILE.scratch.fontproof = { runhead = {}, section = {}, subsection = {}, testfont = {}, groups = {} }

fontproof:declareFrame("content",     {left = "8%pw",             right = "92%pw",             top = "6%ph",              bottom = "96%ph" })
fontproof:declareFrame("runningHead", {left = "left(content)",  right = "right(content)",  top = "top(content)-3%ph", bottom = "top(content)-1%ph" })

-- set defaults
SILE.scratch.fontproof.testfont.filename = SILE.resolveFile("packages/fontproofsupport/Lato2OFL/Lato-Light.ttf")
SILE.scratch.fontproof.testfont.size = "8pt"
SILE.scratch.fontproof.runhead.filename = SILE.resolveFile("packages/fontproofsupport/Lato2OFL/Lato-Light.ttf")
SILE.scratch.fontproof.runhead.size = "5pt"
SILE.scratch.fontproof.section.filename = SILE.resolveFile("packages/fontproofsupport/Lato2OFL/Lato-Heavy.ttf")
SILE.scratch.fontproof.section.size = "12pt"
SILE.scratch.fontproof.subsection.filename = SILE.resolveFile("packages/fontproofsupport/Lato2OFL/Lato-Light.ttf")
SILE.scratch.fontproof.subsection.size = "12pt"
SILE.scratch.fontproof.sileversion = SILE.version

local hb = require("justenoughharfbuzz")
SILE.scratch.fontproof.hb =  hb.version()

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
    runheadinfo = "Fontproof for: " .. SILE.scratch.fontproof.testfont.family .. " - Input file: " .. SILE.masterFilename .. ".sil - " .. os.date("%A %d %b %Y %X %z %Z") .. " - SILE " .. SILE.scratch.fontproof.sileversion .. " - HarfBuzz " ..  SILE.scratch.fontproof.hb
  else
    runheadinfo = "Fontproof for: " .. SILE.scratch.fontproof.testfont.filename .. " - Input file: " .. 
SILE.masterFilename .. ".sil - " .. os.date("%A %d %b %Y %X %z %Z") .. " - SILE " .. SILE.scratch.fontproof.sileversion .. " - HarfBuzz " ..  SILE.scratch.fontproof.hb
  end
  SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
    SILE.settings.set("document.rskip", SILE.nodefactory.hfillGlue)
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.zeroGlue)
    SILE.settings.set("document.spaceskip", SILE.length.new({ length = SILE.shaper:measureChar(" ").width }))
    SILE.call("font", { filename = SILE.scratch.fontproof.runhead.filename,
                        size = SILE.scratch.fontproof.runhead.size
                      }, {runheadinfo})
    SILE.call("par")
  end)
  return plain.endPage(self);
end;

SILE.registerCommand("setTestFont", function (options, content)
  local testfilename = options.filename or nil
  local testfamily = options.family or nil
  SILE.scratch.fontproof.testfont.size = options.size or "16pt"
  if testfilename == nil then
    for j=1,#(_G.unparsed) do
      if _G.unparsed[j]=="-f" then
        testfilename = _G.unparsed[j+1]
      end
    end
  end
  if testfamily then
    SILE.scratch.fontproof.testfont.family = testfamily
  else
    SILE.scratch.fontproof.testfont.filename = testfilename
  end
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

SILE.registerCommand("proof:arrowroot",function(options, content)
  SILE.typesetter:typeset("Arrowroot Barley Chervil Dumpling Endive Flaxseed Garbanzo Hijiki Ishtu Jicama Kale Lychee Marjoram Nectarine Oxtail Pizza Quinoa Roquefort Squash Tofu Uppuma Vanilla Wheat Xergis Yogurt Zweiback")
end)

SILE.registerCommand("proof:capslower",function(options, content)
  SILE.typesetter:typeset("Another Aorta. Boastful Bnai. Contemporary Cnith. Donated Dry. Enough Eons. Forensic Fnord. Gneiss Gonads. Hospital Hnuh. Iodine India. Jon Jnada. Koala Knife. Lord Lning. More Mnemonics. None Nnung. Oops Onion. Pneumatic Portal. Queen. Roast Rnip. Sorted Snorted. Toast Tnanga. Unable Uove. Vocal Vning. Woven Wnoon. Xono Xnuno. Yokel Yngwe. Zoom Znana.")
end)

SILE.registerCommand("proof:bringhurst", function (options,content)
  SILE.typesetter:typeset("I “Ask Jeff” or ‘Ask Jeff’. Take the chef d’œuvre! Two of [of] (of) ‘of’ “of” of? of! of*. Ydes, Yffignac and Ygrande are in France: so are Ypres, Les Woëvres, the Fôret de Wœvres, the Voire and Vauvise. Yves is in heaven; D’Amboise is in jail. Lyford’s in Texas & L’Anse-aux-Griffons in Québec; the Łyna in Poland. Yriarte, Yciar and Ysaÿe are at Yale. Kyoto and Ryotsu are both in Japan, Kwikpak on the Yukon delta, Kvæven in Norway, Kyulu in Kenya, not in Rwanda.… Walton’s in West Virginia, but «Wren» is in Oregon. Tlálpan is near Xochimilco in México. The Zygos & Xylophagou are in Cyprus, Zwettl in Austria, Fænø in Denmark, the Vøringsfossen and Værøy in Norway. Tchula is in Mississippi, the Tittabawassee in Michigan. Twodot is here in Montana, Ywamun in Burma. Yggdrasil and Ymir, Yngvi and Vóden, Vídrið and Skeggjöld and Týr are all in the Eddas. Tørberget and Våg, of course, are in Norway, Ktipas and Tmolos in Greece, but Vázquez is in Argentina, Vreden in Germany, Von-Vincke-Straße in Münster, Vdovino in Russia, Ytterbium in the periodic table. Are Toussaint L’Ouverture, Wölfflin, Wolfe, Miłosz and Wū Wŭ all in the library? 1510–1620, 11:÷00 pm, and the 1980s are over.")
end)

SILE.registerCommand("proof:allkernpairs", function(options,content)
  SILE.typesetter:typeset([[jw Shahjahanpur supercalifragilisticexpialidocious acquaintanceship
dichlorodifluoromethane insightfulnesses jl Erzgebirge vx kx Overijssel
solemnifying roofgarden boxberries fq substratosphere bxs Gewurztraminer
disconnectedly jg Thanksgivings bugbears Allhallowmas labdanums pq adjt
chymotrypsin sleepwalked kibitka awlworts unobjectionable sheqel
magnetohydrodynamics anthropomorphize goldfields Chappaquiddick Moskva clxii
misjudgment tx Panmunjom px earthquake outperform mx Netzahualcoyotl Skopje
bandwidths clavicytherium clampdown zx convolvulaceous honeysuckle qf fz
Gelbvieh succinylsulfathiazole sixfold bogtrotter subcultural pkwy eurhythmy
Ecbatana qx jimjams cml crowfeet prajna Flaxman Kafkaesque weekday Reykjavik
manoeuvrability Hochheimer sauerbraten cobwebby wv Schwarzkopf xrefs
aftergrowth schnozzle Prokopyevsk Liederkranz eggplant abmho overwhelmingly wx
Rajput machzor snuffboxes dumdum Fujiyama backgammon xk Qiqihar blowgun
Oxycontin Tsongkhapa qv Bernbach qp syrinx blowzier Yellowknife
halfheartedness abhenries Acrux exquisite qn fv Algonquian jf Karlsruhe
switchgear syzygy nextdoor Mahfouz Iroquoian bq Houyhnhnm Berezniki vq Osmanli
yukky vj tramroad vf jz cg zj duumvir Aduwa Vazquez Akbar Elroy newsflash xxxv
colicweed bkcy Leipzig qt hdqrs Alzheimer Balikpapan fwd kudzu Fuzzbuster
conferva mfd hamza Manxwoman Trabzon Bydgoszcz beachcomber jh qz pulpboard
Fafnir wq acpt seqq qj Axum Ahvenanmaa qc Abner avdp cj Concepcion Freyja
Albuquerque yq showjumping Geulincx mkt qk Artaxerxes Macdonald jct
Bodhisattva baggywrinkle Jodhpur Fitzsimmons bpm qy Hoffman Arjuna foxglove
Baroja jb Gujranwala Aramco Adkins zf kz exactness mtg gx cf qoph Cuxhaven
Bradbury ql bevvy jq Azrael myxoedema evzone campground Cuthbert Aqaba
disbandment qwerty qm Urumqi Oldcastle Bangweulu twayblade Chongjin Qingdao
Amway Mazda crabgrass Betjeman zugzwang Dreyfus hryvnia Fitzpatrick sx qd xcvi
Newcastle Sejm qg Avalokitesvara Ghazvanid pvt vb Bitolj Oxnard Shawwal
Bigfoot Atbara xj Hovhaness dvandva fx Daugavpils vw Chongqing Beckford jx
misdoubt Sumgait Catawba Iqbal Pfc Guadalquivir Bexley cotquean hx qs
flexdollars kq dx Noxzema Altman Ayyubid dogvane Changchun Azikiwe Boltzmann
vm Eijkman Gerlachovka fp hajj Novgorod Cowpens jy Avlona jv fjeld vc
Ashkenazi Hypnos qh Nejd Procne Liebfraumilch]])
end)

SILE.registerCommand("proof:jafkerns", function(options,content)
  SILE.typesetter:typeset("Tords,' stoweve fording, antlay,” ars. Tomplum Mateds,” Takedis,” dis: 365 nuting,” Gody, be contach art,' Int,” weed; any.' Debta,” fordifir,' beetwe's mulare. Tork. Willy. Lany,” Conal ar, Counta.” vacquilly-Chredis, thavel’s. A. Aphy,” may,” anted) ow,' Tary,” watedif,” ingly,” to Smaxon's,” ing,” Trated wayste.” Somy, ov, ated: Civedy,” (mumbee yedinvis velike,” ourecul at, Expora's aultea,' aw.' istach's joy,” Cam an’s,” istays.' Timate” ings.” droute,” Whys,” (Jullys,” Mureate,” ing.” Aughte. Any.' Tormal’s.” aporia; bear,' Suffeca’s fecute. Satted; bown) ack; ar, aves, we.' likey’s bablive,” ante,” whatiat,” townwelifix-dintom thaved dis, Peteduat’s,” by,” Medshey,” Whys.” is,” Tecompe watight.” throris.” ow,” sych) ardifing,” Takes.' stimpat,' win's,” rating).” Eveated; Finted; Rommunn’s really. Apost,' Eurcal’s for, Fightly,” Turtan atimplin's-storee,' In res.” stedur, Eur,” by,” othated” If Fords.” To-ort-co-Paurty,” autpon’s is. Hom).” Tabst,” ingete.” orthat,” sy.” Ashavin excedur, whys,” Grates.” Meturs,” aged” (ablinve.” istell; willumate,” difing.' wis,” for,” ontativ. Liffic.” staxte,” Treed) ovinte.” my. Pea, torece, Whypeat havelly,' res,” ate,” Accorlik,' thaw.' 'Butly,” thy,” Seared; edurun'stinvey,” aut wat, aw,” aving,” invoinuat.' - foo, andhamb, ought.” Cark: Tres beget’s way,” Jountim; thavoy,' havis ratedife,” worshat,” To thumply, unnumb. Foximun atight.” Hebt,” If, wily.” (abstual’s pated’s toodia. Behave,” ant.” con: Tarece,' (wiligan,' age,' Afteate,” Opte be.” (dur.” (ges,' Hinatto, pat ontly, angs,” (co, thaved” wary,” anked; hung,” istany.” tock,” arm: have.” ot; be) complin’t unton’s,” ing,” my.” Tur.' To parce,” ant,” Evisto, ing,” whavelve.' Intat-tedurd), th's quirs.” Irany,” ang.” ton plight,' arday.” Accongly; atedive,” Tecompla, frecon; cartat,” wought,” istures.” con’s ke,” Ovelf,” Geords,” Chumpla,” Souted comyst,” hirequal” hatedifir,” ang: Astapp. Fampeca.” Tay, an's wignavin; Ambeek,” Outhap. Nowilif, antedly,” inte.' whave,” Intive.” Inted” Bece” wily, Evoce,” frount’s.” thavel's,' is ornall: Accutc.” D.C. Amy.' Tow, ap. hanatin: my, ablist, Requir,” intedly.” Cativinn’s rods, sy,' thaves,” thatim’s vateave,” Pos, “abliblibe.” Pow,” invelf.” imparce,” atedur.' Troves,' hatech ing). 40 say,” int. Ming,” ifirs,” ont’s,” evellis, of th: “hatilivin toweatz, youreb. To-cornagratt,” Teauta,' Heatelie.” Uning.” th any,” ing.' thated; work: Tobjece.” beedur,” Duking, Jource.” Buromps,” Artant,” Tobjecat, Recant,” stint,” whis,” (affirob. Aftedia,” Tor.” Navell: antly.” (banatinna, intorat be.” Sys,' Contarry.” Ack,” complat.” tedirt, Intedis,” Offe,” ings,” by,” In than's.' Burvinte,” ox, Cypown's ally,” Atte,” al’s Islive wordre. To gly-Wely,' an argativing,” Sevathave.” Toduablin.” flative.' - Tecaught.' Toyear.' How glardia,” (forly. In als.' still pors.” body’s.” th’s tomakes.” tood ing: Stanth’s,” optedur, apeall), wordiump,” ontedin's,” whatia.' lim; any,” behavir, wrow,” wish thany,” Counte,” Use.” weeduang,” re.")
end)

return fontproof
