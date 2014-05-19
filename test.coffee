require('coffee-script')
request = require("request")
cheerio = require('cheerio')
db = require './db'

{Data} = db.models

db.connection.connect()

options =
  url: "http://my.wape.ru/myfiles/index.php?x=3"
  headers:
    "User-Agent": "Mozilla/5.0 (X11; Linux i686) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"

request options, (err, data) ->
  $ = cheerio.load(data.body)
  oneArr = $($($(".one").find("small")).find("a")).toArray()
  twoArr = $($($(".two").find("small")).find("a")).toArray()
  arrLink = []
  oneArr.forEach (el) ->
    arrLink.push(el.attribs.href)
  twoArr.forEach (el) ->
    arrLink.push(el.attribs.href)
  a = new  Data {links:arrLink}
  a.save()
  console.log "arrLink",arrLink
