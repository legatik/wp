Scraper = require("../models/scraper")
moment  = require("moment")
cheerio = require("cheerio")

class MrAndMrsSmith extends Scraper
  constructor: (search) ->
    super
    @id = "mrandmrssmith"
    @name = "MrAndMrsSmith.com"
    @requestUrl = "http://www.mrandmrssmith.com/us/hotel-search-results"
    @baseUrl = "http://www.mrandmrssmith.com/"

  translateSearch: (callback) ->
    checkout = moment @search.checkOutDate
    checkin  = moment @search.checkInDate

    self = @
    @request uri : @requestUrl, (res, body) ->
      try
        $ = cheerio.load(body)
        
        cities     = $("#location_select option").toArray()
        cityId     = null
        searchCity = self.search.location.toLowerCase().split(',')[0]

        cities.shift()
        for city in cities
          city     = $(city)
          cityName = city.text().toLowerCase()

          if cityName.match(searchCity) or searchCity.match(cityName)
            cityId = city.val()
            break

        if !cityId?
          callback?(new Error( "City '#{searchCity}' not Found, sorry"))
          return

        translatedSearch =
          "search"                  : "Search"
          "search-hotel-adults"     : self.search.parties
          "search-hotel-destination": cityId
          "search-hotel-date-from"  : checkin.format("YYYY-MM-DD")
          "search-hotel-nights"     : checkout.diff(checkin, 'days')
          "search-hotel-price"      : "atoz"
          "search-instance"         : "default"

        callback?(null, translatedSearch)
      catch e
        callback?(e)

  startFetching: (searchOptions, offset, callback) ->
    page = offset + 1
    requestOptions =
      method : "POST"
      uri    : "#{@requestUrl}?page=#{page}"
      form   : searchOptions

    self = @
    @request requestOptions, (res, body) ->
      try
        $ = cheerio.load(body)

        currPage = $(".page_numbers .active")
        nextPage = +currPage.next().html()
        currPage = +currPage.html()

        accommodations  = $(".hotel").map (index, elem)->
          elem       = $(elem)
          details    = elem.find(".details")
          nightPrice = details.find(".inc-tax .currency-to-convert").attr("rate_usd")
          fullPrice  = details.find(".ex-tax .currency-to-convert").attr("rate_usd")
          fullPrice  = fullPrice ? nightPrice * +searchOptions["search-hotel-nights"]
          hotel      =
            type      : "hotel"
            name      : details.find("h3 a").text().trim()
            deeplink  : self.baseUrl + elem.find(".view a").attr("href")
            thumbnail : elem.find('.view img').attr("src")
            price     : fullPrice * 0.1 # add tax 10%
          return hotel

        if page isnt currPage
          self.endFetching()
          return

        callback?(null, accommodations, offset+1)
        if page < nextPage
          self.startFetching(searchOptions, offset+1, callback)
        else
          self.endFetching()
      catch e
        callback?(e)

module.exports = MrAndMrsSmith
