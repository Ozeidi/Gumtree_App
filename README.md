# Gumtree_App
A project to scrap gumtree.com.au cars content and introduce in an interactive shiny-leaflet application.

Description: 
01. Scraper:
This script collect cars content from gumtree.com.au, including 25 variables per listing. Note that this scraper is based on multiple htt get requests ,due to the lack of server side API. Hence, it might take a long period to complete.
Excesive runs might get your IP to be blocked by the domain.

How to use:
In a PC with scrapy installed and within this source code directory invoke the scraper with following syntex:
scrapy crawl Gumtree -o [outputfile]
eg. scrapy crawl Gumtree -o sample.csv
The output will be avaiable in same code directory.

02. App:
Shiny R application that use the data collected from the above script to display listing on an interactive map.
A deployed version of the app can be accessed on the link: https://ozeidi.shinyapps.io/gumtree_car_app/ .
Note that this version is limited to 5000 listings to minimize application latency, since it's currently hosted on the free shinyapps.io.
