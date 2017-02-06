require 'rets'

# Some MLS's don't display actual values in many fields. Instead they return lookup values
# that you must query the metadata with, to find the actual value you're looking for.

# Example: For the Status field, you might see something like this: "QAFID99930002233300003DDFFFFAAW".
# This gem enables you to exchange this value, using the metadata, on the fly for the human-readable
# translation (Like "Active")

# Prepare a normal "find" call
# Pass resolve: true and the gem will reveal the human-readable values in the response

property = client.find :first, {
  search_type: 'Property',
  class: 'CLASS_NAME',
  query: 'RETS_QUERY',
  resolve: true
}

puts 'received property: '
puts property.inspect
client.logout
