require 'rets'
require 'json'
require 'thread'

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

puts 'We connected! Lets get all the photos for a property...'

# Get all photos (*) for MLS ID 'W2920691'
# Pass :object_id (ie '0', '1,2', wildcard '*')
# The pass :resource (Property, Agent, MetaData, ...), :object_type (Photo, PhotoLarge), :rescource_id (ID of agent, MLS, ...)
photo_list = client.object '*', {
    resource: 'Property',
    object_type: 'Photo',
    resource_id: 'W2920691'
}

# Loop photos, split the response & save each photo (again, based on TREB requirments)
photos = Rets::Parser::Multipart.parse photo_list, 'StratusRETS-XYZZY'
photos.each_with_index do |data, index|
    Thread.new do
        File.open("property-#{index.to_s}.jpg", 'w') do |file|
            file.write data.body
        end
    end
end

puts photos.length.to_s + ' photos saved.'
client.logout