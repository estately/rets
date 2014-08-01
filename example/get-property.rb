require 'rets'
require 'json'

# Example is based for TREB RETS.
# Pass the :login_url, :username, :password and :version of RETS
client = Rets::Client.new({
    login_url: 'http://rets.torontomls.net:6103/rets-treb3pv/server/login',
    username: 'xxx',
    password: 'xxx',
    version: 'RETS/1.5'
})

begin
    client.login
rescue => e
    puts 'Error: ' + e.message
    exit!
end

puts 'We connected! Lets get a property...'

# Get one property (again, based on TREB requirments)
# Pass :first or :all
# Then :search_type (Property, Agent, ...), :class (Condo, Commerical, ...), :query and :limit
property = client.find :first, {
    search_type: 'Property',
    class: 'ResidentialProperty',
    query: '(Timestamp_sql=2014-01-01T00:00:00+)',
    limit: 1
}

# Save the property to a JSON file.
File.open('property.json', 'w') do |file|
    file.write(JSON.pretty_generate property)
end

puts 'Proprty is saved to property.json'
client.logout