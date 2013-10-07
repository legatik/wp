Scraper = require('../models/scraper')
moment = require('moment')
cheerio = require('cheerio')

class Hotels extends Scraper

  constructor: (search) ->
    super
    @id = "hotels"
    @name = "Hotels.com"
    @requestUrl = "http://www.hotels.com/search.do"

  translateSearch: (callback) ->
    headers = {}
    headers["Host"] = "searchru1.anextour.com"
    headers["Origin"] = "http://searchru1.anextour.com"
    headers["Referer"] = "http://searchru1.anextour.com/searchresult.aspx"


    translatedSearch =
      checkIn:"2013-10-06-00-00-00"
      checkIn2:"2013-10-06-00-00-00"
      nightsFrom:7
      nightsTo:7
      adult:2
      child:0
      chdAge1:''
      chdAge2:''
      chdAge3:''
      chdAge4:''
      SearchPriceFrom:''
      SearchPriceTo:''
      holPack:''
      depCity:175
      town:''
      village:''
      country:1189
      captcha:''
      stopSaleControl:true
      flightControl:false
      curr:'USD'
      firstIsNotRed:false
      secondIsNotRed:false
      category:''
      hotel:''
      board:''
      airline:""
    requestOptions =
      headers:headers
      method:"POST"
      form:translatedSearch
      uri: "http://searchru1.anextour.com/Price/GetPrice.aspx"
    callback?(null,requestOptions)
  startFetching: (searchOptions, offset, callback) ->
    offset = offset||1
    accommodations = []
    check = 0
    @request searchOptions, (res, body) =>
      try
        $ = cheerio.load(body)
        elArr = $(".results > tbody > tr")
        tourArr = elArr.filter (index, element) =>
          if $(element).attr("id") then return element
        if tourArr.length
          tourArr.map (index, element) =>
            accommodation =
              settlement : $(element).find("td").eq(1).text().replace(/[ \n\t\r]+/g,"")
              dayNight   : $(element).find("td").eq(2).text().replace(/[ \n\t\r]+/g,"")
              tour       : $(element).find("td").eq(3).text().replace(/[ \n\t\r]+/g,"")
              nameHotel  : $(element).find(".hotel > div > a").text().replace(/[ \n\t\r]+/g,"")
              deeplink  : $(element).find(".hotel > div > a").attr("href")
              nutrition  : $(element).find("td").eq(5).text().replace(/[ \n\t\r]+/g,"")
              roomsType  : $(element).find("td").eq(7).text().replace(/[ \n\t\r]+/g,"")
              price      : $(element).find("td").eq(9).text().replace(/[ \n\t\r]+/g,"")
            searchDeepOptions =
              method:"GET"
              headers:
                Cookie:"regionid=175"
              uri:accommodation.deeplink
             @request searchDeepOptions, (res, body) =>
               $ = cheerio.load(body)
               imgElArr = $(".ax-hoteldetail-v2-imglist >li")
               if imgElArr.length > 0
                 imgLinkArr = imgElArr.map (index,element) =>
                   "http://www.anextour.com/"+$(element).find("a").attr("href")
                 accommodation.images = imgLinkArr
               accommodation.discription = $(".ax-toggle").text()
               collectTour(accommodation,tourArr.length)
#               Можно забрать еще ссылку на сайт,
#               но он не у всех есть, по ходу дела
        else
          @endFetching()
      catch error
        callback?(error)
    collectTour = (tour,lengthArr) =>
      check++
      accommodations.push(tour)
      if check == lengthArr
        callback?(null, accommodations, offset+1)
        offset++
        searchOptions =
          method:"POST"
          uri:"http://searchru1.anextour.com/Price/GetPrice.aspx"
          form:
            pageIndex:offset
            captcha:""
        @startFetching(searchOptions, offset+1, callback)


module.exports = Hotels

