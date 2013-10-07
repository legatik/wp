Scraper = require("../models/scraper")
moment  = require("moment")
cheerio = require("cheerio")

class Olotels extends Scraper
  constructor: (search) ->
    super
    @id = "olotels"
    @name = "Olotels.com"
    @requestUrl = "http://www.olotels.com/city.php"
    @autocompleteUrl = "http://www.olotels.com/ajax-list-regions.php?langid=1&getCountriesByLetters=1&letters="

  translateSearch: (callback) ->
    checkout     = moment @search.checkOutDate
    checkin      = moment @search.checkInDate
    checkCity    = @search.location.split(",")[0]
    @nightsCount = checkout.diff(checkin, "day")
    self         = @
    @request uri : @autocompleteUrl + encodeURIComponent(checkCity), (res, body) ->
      try
        cityId = null
        cities = body.split("|")
        search = self.search

        checkCity = checkCity.toLowerCase()

        cities.pop()
        for city in cities
          city    = city.split("###")
          city[1] = city[1].toLowerCase()

          if city[1].match(checkCity)
            cityId = city[0]
            break

        if !cityId?
          callback?(new Error("City '#{searchCity}' not Found, sorry"))
          return

        if search.rooms > 3
          callback?(new Error("Can not search rooms more than 3"))
          return

        if search.parties > 4
          callback?(new Error("Can not have more tan 4 people in one room"))
          return

        searchKey  = checkin.format("YYYYMMDD")
        searchKey += checkout.format("YYYYMMDD")
        searchKey += search.rooms
        searchKey += search.parties
        searchKey += "0500001050000105000011111"
        searchKey += cityId

        translatedSearch =
          "key"   : searchKey
          "stars" : "11111"
          "type"  : "Card"
          "count" : "50"
          "curid" : "USD"

        callback?(null, translatedSearch)
      catch e
        callback?(e)

  startFetching: (searchOptions, offset, callback) ->
    searchOptions.page_num = offset + 1

    requestOptions =
      uri : @requestUrl
      qs  : searchOptions

    self = @
    @request requestOptions, (res, body) ->
      try
        $ = cheerio.load(body)

        results  = $("#search-details-list > li")
        pages    = []
        currPage = +$("#ddlPage").val()

        $("#ddlPage option").each (index, page) ->
          page = +$(page).val()

          pages[page] = switch
            when page is currPage then "curr"
            when page >  currPage then "next"
            when page <  currPage then "prev"

        nextPage = pages.indexOf("next")

        accommodations = results.map (index, elem)->
          elem  = $(elem)
          photo = elem.find("img.photo").attr("src")

          if !photo?
            return

          details    = $(elem.find(".details p")[0])
          nightPrice = parseInt(details.find("em > span.right > span").text())
          totalPrice = nightPrice * self.nightsCount
          deeplink   = details.find("a")
          name       = deeplink.text()
          stars      = details.children("span").children("span").length

          accommodation =
            name      : name
            price     : totalPrice
            type      : "hotel"
            stars     : stars
            thumbnail : photo
            deeplink  : deeplink.attr("href")

        if searchOptions.page_num isnt currPage
          self.endFetching()
          return

        callback?(null, accommodations, offset+1)
        if searchOptions.page_num < nextPage
          self.startFetching(searchOptions, offset+1, callback)
        else
          self.endFetching()
      catch e
        callback?(e)

module.exports = Olotels
