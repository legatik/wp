Scraper = require('../models/scraper')
querystring = require 'querystring'
cheerio = require 'cheerio'
moment = require 'moment'
request = require 'request'

class Hotelclub extends Scraper

  constructor: (search) ->
    super
    @id = "hotelclub"
    @name = "hotelclub"
  translateSearch: (callback) ->
    self = @
    checkInDate = moment(@search.checkInDate, 'YYYY-MM-DD')
    checkOutDate = moment(@search.checkOutDate, 'YYYY-MM-DD')
    @timeStay = (checkOutDate - checkInDate)/3600000
    checkInDate = checkInDate.format('DD/MM/YYYY')
    checkOutDate = checkOutDate.format('DD/MM/YYYY')
    if checkOutDate < checkInDate
      console.log 'check-out date should be after check-in date!'
      @endFetching()
    else if new moment() > checkInDate
      console.log 'check-in date should be after present moment!'
      @endFetching()
    else
        data = {
          location: @search.location.replace(" ","+")
          parties:  @search.parties
          rooms:    @search.rooms
          checkIn:  checkInDate
          checkOut: checkOutDate
        }
        callback?(null, data) 
  startFetching: (searchOptions, offset, callback) ->
    offset = offset||1
    self = @
    self.elsLen
    @pageNumber
    chkin = searchOptions.checkIn.replace(/\//g,"%2F")
    chkout = searchOptions.checkOut.replace(/\//g,"%2F")
    rooms = searchOptions.rooms
    path1 = "http://www.hotelclub.com/shop/hotelsearch?type=hotel&hotel.type=keyword&hotel.coord=&hotel."
    path2 = "keyword.key="+searchOptions.location+"&hotel.locId=&hotel.chkin="+chkin+"&hotel.chkout="+chkout+"&hotel.rooms%5B0%5D.adlts="+rooms+"&hotel."
    path3 = "rooms%5B0%5D.chlds=0&hotel.rooms%5B0%5D.chldAge%5B0%5D=&hotel.rooms%5B0%5D.chldAge%5B1%5D=&hotel.rooms%5B0%5D.chldAge%5B2%5D=&hotel.rooms%5B0%5D.chldAge%5B3%5D=&hotel.rooms%5B0%5D.chldAge%5B4%5D=&hotel."
    path4 = "rating=&hotel.hname=&hotel.couponCode=&search=Search&hsv.page="+offset+"&curr=USD&locale=EN"
    uri = path1 + path2 + path3 + path4
    preRequest = 
      uri : path1 + path2 + path3 + path4
    @request preRequest, (res, body) =>
      try
        $ = cheerio.load(body)
        els = $(".hotelResultCardHiDensity")
        self.elsLen = els.length
        console.log "self.elsLen",self.elsLen
        if self.elsLen > 0
          accommodations = els.map (i) ->
            data = $(els[i]).attr("data-map-info")
            jsonData = JSON.parse data
            if(jsonData.label)
              price = jsonData.label.replace("US$","")
              days = self.timeStay/24
              price = price*days*1.1
            else
              price = ""
            thumbnailTxt = $(els[i]).find(".slide").attr("data-agent")
            thumbnailJson = JSON.parse thumbnailTxt
            thumbnail = thumbnailJson.params.src
            deeplink = $(els[i]).find(".hotelNameLink").attr("href")
            accommodation =
              name:           jsonData.name
              price:          price
              thumbnail:      thumbnail
              deeplink:       deeplink
              location:       [jsonData.lat, jsonData.lng]
              type:           jsonData.type
              rating:         jsonData.rating
              stars:          jsonData.stars
            return accommodation
        if self.elsLen > 0
          callback?(null, accommodations, offset+1)
          self.startFetching(searchOptions, offset+1, callback)
        else
          self.endFetching()
      catch error
        callback?(error)

module.exports = Hotelclub
