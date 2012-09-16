$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")

require 'sinatra'
require 'active_record'
require 'db/connect'
require 'locality'

get '/:name' do |name|
  localities = Locality.find_matching_search(name)
  res = localities.map do |l|
    [l.name, l.post_code, l.subdivision_code]
  end
  [
    200,
    {'Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*'},
    [res.to_json]
  ]
end
