Scraper = require('../models/scraper')
querystring = require 'querystring'
cheerio = require 'cheerio'
moment = require 'moment'
request = require 'request'


class Homeaway extends Scraper

  
  constructor: (search) ->
    super
    @id = "homeaway"
    @name = "homeaway"

  translateSearch: (callback) ->
    checkOutDate = moment(@search.checkOutDate, 'YYYY-MM-DD')
    checkInDate = moment(@search.checkInDate, 'YYYY-MM-DD')
    bedrooms = @search.rooms
    location = @search.location.replace(" ","+")
    sleeps = @search.parties
    @timeStay = (checkOutDate - checkInDate)/3600000
    if checkOutDate < checkInDate
      console.log 'check-out date should be after check-in date!'
      @endFetching()

    if @timeStay < 48
        console.log "residence time should not be less than two days"
        @endFetching()
   
    else if new moment() > checkInDate
      console.log 'check-in date should be after present moment!'
      @endFetching()
    else
      data =
        checkOutDate: checkOutDate
        checkInDate: checkInDate
        bedrooms: bedrooms
        location: location
        sleeps: sleeps
      callback?(null,data)

  startFetching: (searchOptions, offset, callback) ->
    self = @
    offset = offset||1
    self.offset = offset
    self.accommodationArr=[]
    self.pageNumbers
    self.checkArr =[]
    preRequest =
      uri: "http://www.homeaway.com/search/refined/keywords:"+searchOptions.location+"/Bedrooms:"+searchOptions.bedrooms+"/Sleeps:"+searchOptions.sleeps+"/arrival:"+searchOptions.checkInDate._i+"/departure:"+searchOptions.checkOutDate._i+"/page:"+self.offset+""
    request preRequest, (err, res, body) ->
      $ = cheerio.load(body)
      els = $('.listing-faces')
      nextPageHref = $("#main").find(".page > span").text()
      self.pageNumbers = nextPageHref.substring(nextPageHref.indexOf('of ')+3, nextPageHref.indexOf('of ')+10)
      self.pageNumbers = self.pageNumbers.replace(",","")/30
      self.pageNumbers = Math.ceil(self.pageNumbers)
      accommodations = els.map (i) ->
        listingCl =  $(els[i]).parent().attr('ref')
        preRequest =
          uri: "http://www.homeaway.com/unit/preview?spu="+listingCl+""
        request preRequest, (err, res, body) ->
          cLat = body.substring(body.indexOf('cLat')+6, body.indexOf('cLong'))
          cLat = cLat.replace("'","")
          cLat = cLat.replace(",","")
          cLong = body.substring(body.indexOf('cLong')+7, body.indexOf("exact"))
          cLongLen = cLong.length
          cLong = cLong.slice(0,cLongLen-15)
          cLong = cLong.replace("'","")
          cLong = cLong.replace(",","")
          cLong = unescape(cLong)
          cLat = unescape(cLat)
          location =[]
          location.push(cLong)
          location.push(cLat)
          
          price =  $(els[i]).find('.price').text().split(" ")[0]
          price = (price.slice(1,price.length))
          price = price.replace(new RegExp(",",'g'),"")
          price = price * self.timeStay/24 + "$"
          neighborhood = $(els[i]).find('.last > span').text()
          thumbnail = $(els[i]).find('.listing-img').attr("ref")
          name =  $(els[i]).find('.listing-title > .listing-url').text()
          deeplinkPath =$(els[i]).find('.listing-title > .listing-url').attr("href")
          deeplink = "http://www.homeaway.com"+deeplinkPath

          minStayEl = $(els[i]).find('.min-stay')
          minStayText = $(minStayEl).text()
          push = true
          if(minStayText)
              minStay = minStayText.replace(/[^0-9]/g,'')
              if(minStay  < self.timeStay/24 ) then push = false
            
          if(push)
            accommodation = {
              name:name,
              price:price,
              neighborhood:neighborhood,
              thumbnail:thumbnail,
              deeplink:deeplink,
              type:'apartment rentals',
              location:location
            }
            reverFunction(accommodation,i)
            return accommodation
          else
            reverFunction(false,i)


    reverFunction = (data,i) =>
      self.checkArr.push(i)
      if(data)
        self.accommodationArr.push(data)
      if self.checkArr.length == 30
        if self.offset is self.pageNumbers
          self.endFetching()
        else
          callback?(null, self.accommodationArr, self.offset+1)
          self.startFetching(searchOptions, self.offset+1, callback)

module.exports = Homeaway
