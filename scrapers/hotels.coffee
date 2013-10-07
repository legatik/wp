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
    translatedSearch =
      destination: @search.location
      arrivalDate: moment(@search.checkInDate, "YYYY-MM-DD").format("MM/DD/YY")
      departureDate: moment(@search.checkOutDate, "YYYY-MM-DD").format("MM/DD/YY")
      rooms: @search.rooms

    requestOptions =
      uri: "http://www.hotels.com?locale=en_US&pos=HCOM_US"

    @request requestOptions, (res, body) -> #Request to get cookies
      callback?(null, translatedSearch)

  startFetching: (searchOptions, offset, callback) ->
    searchOptions.pn = offset+1

    requestOptions =
      uri: @requestUrl
      qs: searchOptions

    @request requestOptions, (res, body) =>
      try
        $ = cheerio.load(body)

        accommodations = $('div.hotel-basic-info').map (index, element) ->
          element = $(element)
          accommodation = {}
          rating = element.find("div.guest-rating-value strong").text()
          if rating?.length
            accommodation.rating = parseFloat(rating.trim().replace(',','.')) * 20
          else
            rating = null
          stars = element.find("span.sprites_star_rating").text()
          if stars?.length
            accommodation.stars = parseFloat(stars.replace('stars', ''))
          else
            accommodation.stars = 0
          accommodation.type = 'hotel'
          accommodation.name = element.find("a.hotelNameLink").text().trim()
          accommodation.deeplink = "http://www.hotels.com#{element.find("a.hotelNameLink").attr("href")}"
          accommodation.thumbnail = element.find('.hotel-image img').attr('src')
          if element.find("div.price").find("span").length > 0
             accommodation.price = parseFloat(element.find("div.price").find("span").text().replace("$",'').replace(",",''))
          else
             accommodation.price = parseFloat(element.find("div.price").find("ins").text().replace("$",'').replace(",",''))
          return accommodation

        if accommodations.length
          callback?(null, accommodations, offset+1)
          @startFetching(searchOptions, offset+1, callback)
        else
          @endFetching()
      catch error
        callback?(error)


module.exports = Hotels
