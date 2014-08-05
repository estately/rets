require 'rets'

# Pass the :login_url, :username, :password and :version of RETS
client = Rets::Client.new({
  login_url: 'login_url',
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

puts 'We connected! Lets log out...'
client.logout
