#AllTheRooms Scrapers

##Introduction

Use this repository to create scrapers for the AllTheRooms project.
Place the new scrapers under the scrapers/ directory.
All the scrapers must be written in coffeescript. 
Scraper classes inherit from the Scraper class.

Take a look at the Scraper class models/scraper.coffee, where you will find a set of useful comments about what functions must be implemented on the subclasses, as well as expected input and output.

Also, take a look at the scrapers under the scrapers/ directory and see how they work.

Please provide the most optimized version of the scraper as possible. Don't do unnecessary request or data parsing.

##Testing

When you think a new scraper is ready, you can test it as seen in the following example.
Let's say we want to test the airbnb scraper.

On a linux terminal window, type: 
```
$ location='New York, NY' checkInDate=2013-08-29 checkOutDate=2013-08-31 parties=1 rooms=1 scraper=airbnb offset=0 coffee test.coffee
```
If you are using Windows command prompt, type: 
```
SET location='New York, NY' 
SET checkInDate=2013-08-29 
SET checkOutDate=2013-08-31 
SET parties=1 
SET rooms=1 
SET scraper=airbnb 
SET offset=0 
coffee test.coffee
```

Here's a little description of each variable:

`location` -> 'City, Country/State'. Provide strings with no special characters

`checkInDate` -> 'YYY-MM-DD'. Valid date. Must be in future

`checkOutDate` -> 'YYY-MM-DD'. Valid date. Must be greater than `checkInDate`

`parties` -> Integer

`rooms` -> Integer

`scraper` -> id of the scraper to be tested

`offset` -> Integer. Offset to start fetching from
