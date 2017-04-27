require 'rets'

client = Rets::Client.new({
  login_url: 'url',
  username: 'username',
  password: 'password',
  version: 'RETS/1.7.2' 
})

begin
    client.login
rescue => e
    puts 'Error: ' + e.message
    exit!
end

puts 'We connected! Lets get all the photos for a property...'


photos = client.find (:all), {
  search_type: 'Media',
  class: 'Media',
  query: '(ResourceRecordKeyNumeric=117562969),(MediaType=Image)'
}

photos.each_with_index do |data, index|
  photo = open(photo = data['MediaURL'])
  puts data['MediaURL']
  require 'base64'
  image = Base64.encode64(photo.read)
  File.open("property-#{index.to_s}.jpg", 'wb') do |f|
    f.write(Base64.decode64(image))
  end
end


puts photos.length.to_s + ' photos saved.'
client.logout
