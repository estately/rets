require 'rets'

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

puts 'We connected! Lets log out...'
client.logout