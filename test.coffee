require('coffee-script')

search =
  location: process.env.location
  checkInDate: process.env.checkInDate
  checkOutDate: process.env.checkOutDate
  parties: process.env.parties
  rooms: process.env.rooms
  property: process.env.property

scraperId = process.env.scraper
offset = if process.env.offset? then parseInt(process.env.offset) else 0

ScraperConstructor = require("./scrapers/#{scraperId}")
scraper = new ScraperConstructor(search)

console.log("Starting test for #{scraperId} scraper with search:\n")
console.log(JSON.stringify(search, null, "\t"))

scraper.fetch(offset)

