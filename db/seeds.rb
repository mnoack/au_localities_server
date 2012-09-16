# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'active_record'
require 'locality'
require 'csv' # to parse localities data
require 'activerecord-import' # to bulk import all data
require 'activerecord-import/base'

ABS_BASE         = "http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&"
ABS_POSTCODE_URL = ABS_BASE + "1270055003_poa_2011_aust_csv.zip&1270.0.55.003&Data%20Cubes&7A0CD4B1AD71C814CA2578D40012D4B2&0&July%202011&22.07.2011&Previous"
ABS_SUBURB_URL   = ABS_BASE + "1270055003_ssc_2011_aust_csv.zip&1270.0.55.003&Data%20Cubes&414A81A24C3049A8CA2578D40012D50C&0&July%202011&22.07.2011&Previous"

def abs_localities
  post_codes_by_maincode = {}
  path = get_abs_csv('POA_2011_AUST.csv', ABS_POSTCODE_URL)
  CSV.parse(File.read(path), :headers => :first_row).each do |row|
    post_codes_by_maincode[row['SA1_MAINCODE_2011']] = row['POA_CODE_2011']
  end

  state_codes = %w(NSW VIC QLD SA WA TAS NT ACT)
  suburbs_by_maincode = {}
  path = get_abs_csv('SSC_2011_AUST.csv', ABS_SUBURB_URL)
  CSV.parse(File.read(path), :headers => :first_row).each do |row|
    # ambiguous suburbs show as: Suburb (State), so remove "(State)"
    suburb_name = row['SSC_NAME_2011'].gsub(/\ \(.+\)$/, '')
    state = state_codes[row['SSC_CODE_2011'][0].to_i - 1]
    post_code = post_codes_by_maincode[row['SA1_MAINCODE_2011']]
    uniq = "#{suburb_name}#{state}#{post_code}"
    suburbs_by_maincode[uniq] ||= [post_code, suburb_name, 1, state]
  end
  suburbs_by_maincode.values
end

def aus_post_localities
  full_post_code_csv_as_string = File.read(ENV['AUS_POST_CSV'])
  CSV.parse(full_post_code_csv_as_string, :col_sep => ';', :headers => :first_row).map do |row|
    category = Locality::CATEGORY_STRING_TO_ID[row['Category'].strip]
    [row['Pcode'], row['Locality'], category, row['State']]
  end
end

def get_abs_csv(filename, url)
  path = "#{File.dirname(__FILE__)}/#{filename}"
  unless File.exists?(path)
    raise "Please download #{url}, unzip and store the csv at #{path} then re-run this task"
    #zip = Net::HTTP.get(URI(url))
    #File.open(path+'.zip', 'w+', :encoding => 'BINARY') {|f| f.write(zip)}
    #content = Zip::ZipFile.open(path+".zip", :encoding => 'BINARY') do |zipfile|
    #  zipfile.read(filename)
    #end
    #File.open(path, 'w+', :encoding => 'ASCII-8BIT') {|f| f.write(content)}
  end
  path
end

print "Locality import"
Locality.delete_all
localities = ENV['AUS_POST_CSV'] ? aus_post_localities : abs_localities
print "importing..."
Locality.import [:post_code, :name, :category_id, :subdivision_code], localities
puts "Loaded #{Locality.count} entries"
