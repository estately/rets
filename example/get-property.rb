require 'rets'


# Get one property
# Pass :first or :all
# Then :search_type (Property, Agent, ...), :class (Condo, Commerical, ...), :query and :limit
property = client.find :first, {
  search_type: 'Property',
  class: 'CLASS_NAME',
  query: 'RETS_QUERY',
  limit: 1
}

puts 'received property: '
puts property.inspect
client.logout
