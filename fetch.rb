require 'rubygems'
require 'mechanize'
require 'csv'

agent = Mechanize.new

# Use Padron 2014 as the input list of municipalities to fetch
CSV.foreach("pobmun14.csv") do |row|
  next if not row[0] =~ /^\d/   # Skip lines not starting with digit, i.e. header

  # Build data URL
  # Sample URL: http://resultadoslocales2015.interior.es/99MU/DMU0111900299_L1.htm?d=0&e=0
  # where 01 is region, 11 is province, 9 is constant, 002 is town, 99 is district (99=overall)
  url = "http://resultadoslocales2015.interior.es/99MU/DMU#{row[0]}#{row[1]}9#{row[2]}99_L1.htm"

  # Fetch and store page
  puts "Fetching #{url}..."
  begin
    page = agent.get(url)
    File.open("staging/#{row[1]}#{row[2]}.html", 'w') {|f| f.write(page.content) }
  rescue Mechanize::ResponseCodeError => e
    puts "Ignoring #{url}: #{e}"
  end
end
