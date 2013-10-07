Scraper = require("../models/scraper")
moment  = require("moment")
cheerio = require("cheerio")

#rooms option does not work
class ChoiceHotels extends Scraper
  constructor: (search) ->
    super
    @id   = "choicehotels"
    @name = "ChoiceHotels.Com"

    @baseUrl         = "http://www.choicehotels.com/"
    @requestUrl      = "http://www.choicehotels.com/ires/en-US/ajax/HotelList"
    @autocompleteUrl = "http://www.choicehotels.com/ires/en-US/PlaceSuggest/"

  translateSearch: (callback) ->
    checkout = moment @search.checkOutDate
    checkin  = moment @search.checkInDate
    self     = @
    location = @search.location.split(",")
    city     = location[0]

    @nightsCount = checkout.diff(checkin, "day")

    autocompleteRequest =
      uri : @autocompleteUrl + encodeURIComponent(city)
      qs  :
        preferredLanguage : "en"
        supportedLanguage : "en"
        interpret         : "partial"
        limit             : 10
        minPopularityToReturn           : 4
        enableSortByPopularityForCities : "true"

    @request autocompleteRequest, (res, body) ->
      try
        results = JSON.parse(body).results
        cities  = results.filter (obj)->
          obj.placeType is "City" and obj.names[0].form is "PRIMARY"

        if cities.length is 0
          throw new Error("City not found '#{self.search.location}'")

        city = cities[0]

        state      = ""
        stateComma = ""
        if (state_ = city.address.subdivision)?
          state      = state_
          stateComma = ", #{state_}"

        translatedSearch =
          ajax          : "true"
          areaid        : city.placeId
          country       : city.address.country
          state         : state
          latitude      : city.geographicLocation.latitude
          longitude     : city.geographicLocation.longitude
          dateFormat    : "mm/dd/yy"
          arrivalDate   : checkin.format("MM/DD/YY")
          departureDate : checkout.format("MM/DD/YY")
          nadult1       : self.search.parties
          nchild1       : 0
          nroom         : self.search.rooms
          placename     : "#{city.names[0].name}#{stateComma}, #{city.address.country}"
          radius        : "40"
          chain         : "A"
          srp           : "RACK"

        callback?(null, translatedSearch)
      catch e
        callback?(e)

  startFetching: (searchOptions, offset, callback) ->
    self    = @

    requestOptions =
      uri  : @requestUrl
      qs   : searchOptions

    try
      @request requestOptions, (res, body)->
        $       = cheerio.load(body)
        content = $(".hotel-list-set > div")

        accommodations = content.map (index, data)->
          hotel = $(data)

          price  = +hotel.find(".price .whole-number").html()
          price += +("0." + hotel.find(".price .decimal").html())
          price *= self.nightsCount

          accommodation =
            name         : hotel.find("a.hotel-info").html().replace(/&amp;/g, "&")
            price        : price + price * 0.15
            deeplink     : hotel.find(".get-rates a").attr("href")
            location     : [hotel.attr("data-ln"), hotel.attr("data-lt")]
            thumbnail    : self.baseUrl + hotel.find("img").attr("src")
            type         : "hotel"
            neighborhood : hotel.attr("data-ci").replace(/\+/g, " ")

        accommodations = accommodations.filter (accommodation)->
          accommodation.deeplink? and accommodation.price? and accommodation.price isnt 0

        callback?(null, accommodations, 1)
        self.endFetching()
    catch e
      callback?(e)

module.exports = ChoiceHotels
