Scraper = require("../models/scraper")
moment  = require("moment")
cheerio = require("cheerio")

#rooms option does not work
class Venere extends Scraper
  constructor: (search) ->
    super
    @id = "venere"
    @name = "Venere.com"
    @requestUrl = "http://www.venere.com/passthru/ajax/properties_service_proxy.php"
    @autocompleteUrl = "http://www.venere.com/passthru/ajax/autocomplete_suggestion_loader.php?lg=en&name="

  translateSearch: (callback) ->
    checkout     = moment @search.checkOutDate
    checkin      = moment @search.checkInDate
    checkCity    = @search.location.split(",")[0]
    self         = @
    @request uri : @autocompleteUrl + encodeURIComponent(checkCity), (res, body) ->
      try
        search = self.search
        data   = JSON.parse(body).ResultSet
        first  = data.firstResultPosition - 1
        city   = data.Result[first]

        if !data? or !city? or !city.geoid?
          callback?(new Error("City not found for: #{checkCity}"))
          return

        translatedSearch =
          sd    : checkin.format("DD")
          sm    : checkin.format("MM")
          sy    : checkin.format("YYYY")
          ed    : checkout.format("DD")
          em    : checkout.format("MM")
          ey    : checkout.format("YYYY")
          rgval : "#{search.parties}||-1"  #adult0|adult1...adultN||child0_childAge0|child1_childAge1|...childN_childAgeN
                                           # where N is number of ROOMS
          geoid : city.geoid
          cur   : "USD"
          pskip : 1                        #page number
          lg    : "en"
          country_code : "US"
          pricerange   : "r6"              #all prices
          orderby      : "venere_ranking"
        callback?(null, translatedSearch)
      catch e
        callback?(e)

  startFetching: (searchOptions, offset, callback) ->
    self = @
    page = offset + 1
    searchOptions.pskip = page
    requestOptions =
      uri : @requestUrl
      qs  : searchOptions

    @request requestOptions, (res, body) ->
      try
        data  = JSON.parse body

        accommodations = data.properties.map (prop, index)->
          type = switch prop.typology
            when "C" then "hotel"
            when "P" then "hostel"
            when "I" then "inn"

          if !type?
            return

          accommodation =
            name      : prop.name
            stars     : prop.rating
            rating    : prop.user_rating * 10
            price     : prop.total_price
            deeplink  : prop.hotel_url
            location  : [prop.lon, prop.lat]
            thumbnail : prop.image_hotel
            type      : type

            neighborhood : prop.area_name
          return accommodation

        accommodations = accommodations.filter (prop)->
          return prop?

        if page <= data.tot_pages
          callback?(null, accommodations, offset+1)
          if page < data.tot_pages
            self.startFetching(searchOptions, offset+1, callback)
        else
          self.endFetching()
      catch e
        callback?(e)

module.exports = Venere
