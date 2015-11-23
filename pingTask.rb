require 'net/http'  
uri = URI.parse('APP_URL')  
Net::HTTP.get(uri)
