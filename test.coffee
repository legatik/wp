require('coffee-script')
request = require("request")
cheerio = require('cheerio')
exec=require('child_process').exec
db = require './db'

{Data} = db.models

db.connection.connect()



startParse = () ->

  reqArr = []
  c = 0
  dbData = false
  arrLink = []

  options =
    url: "http://my.wape.ru/myfiles/index.php?x=3"
    headers:
      "User-Agent": "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"

  request options, (err, data) ->
    $ = cheerio.load(data.body)
    oneArr = $($($(".one").find("small")).find("a")).toArray()
    twoArr = $($($(".two").find("small")).find("a")).toArray()
    oneArr.forEach (el) ->
      arrLink.push(el.attribs.href)
    twoArr.forEach (el) ->
      arrLink.push(el.attribs.href)
  #  a = new Data {links:arrLink}
  #  a.save()
    

    Data.findOne (err, dbOne) ->
      dbData = dbOne
      if dbData
        arrLink.forEach (nLink) ->
          chek = true
          dbData.links.forEach (oLink) ->
            chek = false if nLink is oLink
          if chek
            reqArr.push("http://my.wape.ru/myfiles/" + nLink)
      else
        dbData = new Data {links:[]}
        arrLink.forEach (nLink) ->
          reqArr.push("http://my.wape.ru/myfiles/" + nLink)
      wrapFn()



  wrapFn = () ->
    url = reqArr[c]
    if url
      console.log "request №", c + 1
      getFile url, () ->
        c++
        wrapFn()
    else
      dbData.links = []
      dbData.links = arrLink
      dbData.save () ->
        console.log "------ end ------"
      
  getFile = (url, cb) ->
    optionsDetail =
      url: url
      headers:
        "User-Agent": "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"
    request optionsDetail, (err, dDetail) ->
      $$ = cheerio.load(dDetail.body)
      loadLink = $$(".count_border > a").attr("href")
      checkType = $$("#bbbb").toArray()
      folder = "picture"
      folder = "video" if checkType.length
      
      dwnFolder = __dirname + "/dwn/" + folder
      comand = "wget -P " + dwnFolder + " '" + loadLink + "'"
      exec comand, (err) ->
        console.log "err : ", err if err
        cb()
    
setInterval (->
  startParse()
), 120000
    
