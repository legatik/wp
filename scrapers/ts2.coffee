Scraper = require('../models/scraper')
moment = require('moment')
cheerio = require('cheerio')
Iconv = require("iconv")
Buffer = require('buffer').Buffer

class Hotels extends Scraper

  constructor: (search) ->
    super
    @id = "hotels"
    @name = "Hotels.com"
    @requestUrl = "http://www.hotels.com/search.do"

  translateSearch: (callback) ->


    translatedSearch =
      samo_action:"PRICES"
      TOWNFROMINC:2
      STATEINC:134
      TOURINC:0
      PROGRAMINC:0
      CHECKIN_BEG:20131019
      NIGHTS_FROM:6
      CHECKIN_END:20131020
      NIGHTS_TILL:14
      ADULT:2
      CURRENCY:1
      PRICE_MIN:0
      CHILD:0
      PRICE_MAX:0
      TOWNTO_ANY:1
      TOWNTO:""
      STARS_ANY:1
      STARS:""
      hotelsearch:0
      HOTELS_ANY:1
      HOTELS:""
      MEAL:""
      FREIGHT:0
      FILTER:0
      HOTELTYPES:""
      PACKET:0
#      PRICEPAGE:2
    requestOptions =
      method:"GET"
      encoding: 'binary'
      qs:translatedSearch
      uri: "http://online3.anextour.com/search_tour?"
    callback?(null,requestOptions)
  startFetching: (searchOptions, offset, callback) ->
    offset = offset||1
    searchOptions.qs["PRICEPAGE"] = offset
    console.log "searchOptions",searchOptions
    accommodations = []
    check = 0
    @request searchOptions, (res, body) =>
      try
        body = new Buffer(body, 'binary')
        conv = new Iconv.Iconv('windows-1251', 'utf8')
        body = conv.convert(body).toString()
        html = body.substring(body.indexOf('ehtml')+6, body.indexOf("'); if (typeof"))
        $ = cheerio.load html
        tourArr = $("tbody > tr")
        if tourArr.length
          tourArr.map (index, element) =>
            accommodation =
              settlement : $(element).find("td").eq(0).text().replace(/[ \n\t\r\\n\\]+/g,"")
              tour       : $(element).find("td").eq(1).text().replace(/[ \n\t\r]+/g,"")
              dayNight   : $(element).find("td").eq(2).text().replace(/[ \n\t\r]+/g,"")
              nameHotel  : $(element).find('td').eq(3).find("a").text().replace(/[ \n\t\r]+/g,"")
              deeplink   : $(element).find('td').eq(3).find("a").attr("href").replace(/[\\"]+/g,"")
              nutrition  : $(element).find("td").eq(4).text().replace(/[ \n\t\r]+/g,"")
              roomsType  : $(element).find("td").eq(5).text().replace(/[ \n\t\r]+/g,"")
              price      : $(element).find("td").eq(8).text().replace(/[ \n\t\r]+/g,"")
#!!!          на http://searchru1.anextour.com  данных "typePrice" и "transport" нет
              typePrice  : $(element).find("td").eq(9).text().replace(/[ \n\t\r]+/g,"")
              transport  : $(element).find("td").eq(10).text().replace(/[ \n\t\r\\n\\]+/g,"")
            searchDeepOptions =
              encoding: 'binary'
              method:"GET"
              uri:accommodation.deeplink
            @request searchDeepOptions, (res, body) =>
              body = new Buffer(body, 'binary')
              conv = new Iconv.Iconv('windows-1251', 'utf8')
              body = conv.convert(body).toString()
              $ = cheerio.load(body)
              imgElArr = $("#pictures > a")
              if imgElArr.length > 0
                imgLinkArr = imgElArr.map (index,element) =>
                  "http://www.anextour.com/"+$(element).attr("href")
                accommodation.images = imgLinkArr

              accommodation.discription = $(".hotel_layout").text()
#               Можно забрать отдельно контакты (эта инфа сейчас в discription),
              collectTour(accommodation,tourArr.length)
        else
          @endFetching()
      catch error
        callback?(error)
    collectTour = (tour,lengthArr) =>
      check++
      console.log "check",check
      accommodations.push(tour)
      if check == lengthArr
        callback?(null, accommodations, offset+1)
        offset++
        @startFetching(searchOptions, offset, callback)


module.exports = Hotels

