# -*- coding: utf-8 -*-
###################################################################
################## Script Name: Gumtree Scraper####################
# Description: This script collect the complete cars content
#               from gumtree.com.au, including 25 variables per
#               listing. Note that this is based on multiple http
#               get requests ,due to the lack of server side API, and
#               might take a long period to complete.
#               Hence, excesive use might get your IP to be blocked
#               by the domain.
#How to use:    In a PC with scrapy installed and within this source code directory
#               invoke the scraper with following syntex:
#               scrapy crawl Gumtree -o [outputfile]
#               eg. scrapy crawl Gumtree -o sample.csv
#               The output will be avaiable in same code directory
#Dependency packages: scrapy
import scrapy
import datetime
class Gumtree(scrapy.Spider):
    name = 'Gumtree'
    
    #List of available car makes on Gumtree, The scraper will start from vehicles homepage
    # and got to car "makes" one by one
    #this approach is done to maximiz the number of vehicles scraped, as the webiste limits
    # the number of pages per query to 48.
    Makes=[ 'abarth', 'alfaromeo', 'armstrongsiddeley', 'astonmartin', 'audi', 
    'austinhealey', 'austin', 'bedford', 'bentley', 'bertone', 'bmw', 'bmwalpina', 
    'buick', 'cadillac', 'chery', 'chevrolet', 'chrysler', 'citroen', 'daewoo', 'daihatsu', 
    'daimler', 'datsun', 'detomaso', 'dodge', 'eunos', 'ferrari', 'fiat', 'ford', 'foton', 
    'freightliner', 'geely', 'greatwall', 'haval', 'hillman', 'hino', 'holden', 'honda', 'hsv', 
    'hummer', 'hyundai', 'infiniti', 'isuzu', 'iveco', 'jaguar', 'jeep', 'jensen', 'jmc', 'kia', 
    'lamborghini', 'lancia', 'landrover', 'ldv', 'lexus', 'leyland', 'lotus', 'mahindra', 'maserati', 
    'maybach', 'mazda', 'mclaren', 'mercedes', 'mercedesamg', 'mercedesmaybach', 'mg', 'mini', 
    'mitsubishi', 'mitsubishifuso', 'morgan', 'morris', 'nissan', 'opel', 'performax', 'peugeot', 
    'pontiac', 'porsche', 'proton', 'ram', 'rambler', 'rangerover', 'renault', 'rollsroyce', 'rover', 
    'saab', 'seat', 'skoda', 'smart', 'ssangyong', 'standard', 'studebaker', 'subaru', 'sunbeam', 'suzuki', 
    'tata', 'tesla', 'toyota', 'triumph', 'vauxhall', 'volkswagen', 'volvo', 'wolseley', 'othrmake']
        
    #start_urls = ['https://www.gumtree.com.au/s-cars-vans-utes/c18320']

    def start_requests(self):

        for Make in self.Makes:
            for Year in range(1900,2019,1):
                print ('{}--{}'.format(Make,Year))
                self.logger.info('{}--{}'.format(Make,Year))
                url='https://www.gumtree.com.au/s-cars-vans-utes/carmake-{}/caryear-{}__{}/c18320'\
                .format(Make,Year,Year)
                yield scrapy.Request(url,callback=self.parse_make)
    def parse_make(self,response):
        root_url='https://www.gumtree.com.au/'
        for url in response.css('a.ad-listing__title-link::attr(href)').extract():
            url='{}{}'.format(root_url,url)
            yield scrapy.Request(url,callback=self.parse_vehicle)
        try:
            print (response.url)
            Next_Page =response.css('a[class="paginator__button paginator__button-next"]::attr(href)').extract()
            Next_Page='{}{}'.format(root_url,Next_Page)
            yield scrapy.Request(Next_Page,callback=self.parse_make)
        except:
            pass
    def get_list(self,lst, index):
        return lst[index] if isinstance(lst,list) and len(lst)>index else "N/A"

    def parse_vehicle(self,response):
        yield{
            't': datetime.datetime.now(),
            'url':response.url,
            'Title': response.css('#ad-map span::attr(data-title)').extract(),
            'City':  response.css('#ad-map span::text').extract()[0].replace('  ',' ').replace('\n',''),
            'Lat': response.css('#ad-map span::attr(data-lat)').extract(),
            'Lng': response.css('#ad-map span::attr(data-lng)').extract(),
            'Price':  response.css('span.j-original-price::text').extract()[1].replace('  ','').replace('\n',''),
            'DateListed':response.css('dd.ad-details__ad-attribute-value::text')\
            .extract()[0].replace('\n','').replace('               ',''),
            'LastEdit':  response.css('dd.ad-details__ad-attribute-value::text')\
            .extract()[1].replace('\n','').replace('               ',''),
            'SelerType': self.get_list(response.css('dd[id="c-cars.forsaleby_s"]::text')\
            .extract(),0).replace('\n','').replace('  ',''),
            'Make': self.get_list(response.css('a[id="content-link-cars.carmake_s"]::text')\
            .extract(),0).replace('\n',''),
            'Model':self.get_list(response.css('a[id="content-link-cars.carmodel_s"]::text')\
            .extract(),0).replace('\n',''),
            'Variant':  self.get_list(response.css('dd[id="c-cars.variant_s"]::text')\
            .extract(),0).replace('\n','').replace('  ',''),
            'BodyType':  self.get_list(response.css('dd[id="c-cars.carbodytype_s"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'Year':  self.get_list(response.css('a[id="content-link-cars.caryear_i"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'Km':  self.get_list(response.css('dd[id="c-cars.carmileageinkms_i"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'Trans':  self.get_list(response.css('dd[id="c-cars.cartransmission_s"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'DriveTrain':  self.get_list(response.css('dd[id="c-cars.drivetrain_s"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'Fuel': self.get_list(response.css('dd[id="c-cars.fueltype_s"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'AC':  self.get_list(response.css('dd[id="c-cars.airconditioning_s"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'Cyl':  self.get_list(response.css('span[itemprop="cylinder_configuration"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'EngLit':  self.get_list(response.css('span[itemprop="engine_capacity_litres"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'Reg':  self.get_list(response.css('dd[id="c-cars.registered_s"]::text').extract(),0)\
            .replace('  ','').replace('\n',''),
            'RegExp':  self.get_list(response.css('dd[id="c-cars.registrationexpiry_tdt"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),
            'RegNum':  self.get_list(response.css('dd[id="c-cars.registrationnumber_s"]::text')\
            .extract(),0).replace('  ','').replace('\n',''),

        }
            
