require 'csv'

# 4319 psoe
# 4253 pp
# 1456 C’s
# 0806 Ahora Madrid
# 5426 BeC
# 5163 UPyD
our_party = ARGV[0]

# Count number of municipalities per province
province_stats = {}
towns = {}
CSV.foreach("town_data.csv") do |row|
  next if not row[0] =~ /^\d/   # Skip lines not starting with digit, i.e. header

  province_id = row[2]

  province_stats[province_id] ||= { towns: 0, big_towns: 0 }

  province_stats[province_id][:towns] += 1
  province_stats[province_id][:big_towns] += 1 if row[5].to_i >= 10000

  # Store town data for later use
  towns[row[0]] = row
end

# Read party hierarchies
parent_parties = {}
CSV.foreach("MOLO99_PARTIDOS_43.csv", {col_sep: ";"}) do |row|
  parent_parties[row[0]] = row[1]
end

# Count candidacies
party_stats = {}
CSV.foreach("party_data.csv") do |row|
  next if not row[0] =~ /^\d/   # Skip lines not starting with digit, i.e. header

  # Check it's our party
  party_id = row[1]
  next unless parent_parties[party_id] == our_party

  # Count
  province_id = row[0][0..1]
  party_stats[province_id] ||= { towns: 0, big_towns: 0, got_seats_in_big_towns: 0 }

  party_stats[province_id][:towns] += 1
  party_stats[province_id][:big_towns] += 1 if towns[row[0]][5].to_i >= 10000
end

# We can finally calculate grant amounts
grants = {}
CSV.foreach("party_data.csv") do |row|
  next if not row[0] =~ /^\d/   # Skip lines not starting with digit, i.e. header

  # Check it's our party
  party_id = row[1]
  next unless parent_parties[party_id] == our_party

  # Count
  province_id = row[0][0..1]
  grants[province_id] ||= { grant: 0, limit: 0, mailing: 0, population: 0, census: 0 }

  grants[province_id][:population] += towns[row[0]][5].to_i
  grants[province_id][:census] += towns[row[0]][6].to_i  

  # Calculate grant
  if row[5].to_i > 0
    grants[province_id][:grant] += row[4].to_i * 0.54 + row[5].to_i * 270.90
    grants[province_id][:limit] += towns[row[0]][5].to_i * 0.11

    # Keep track of wins in big towns
    if towns[row[0]][5].to_i >= 10000
      party_stats[province_id][:got_seats_in_big_towns] += 1
    end
  end

  # This is subject to qualifying, which we check later
  grants[province_id][:mailing] += towns[row[0]][6].to_i * 0.22
end

# Extra checks/conditions
grants.each_key do |province_id|
  # Add extra province spending limit
  available_in_towns_percentage = party_stats[province_id][:towns].to_f / province_stats[province_id][:towns].to_f
  if available_in_towns_percentage > 0.5
    grants[province_id][:extra_province_spending] = true
    grants[province_id][:limit] += 150301.11
  end

  # Check mailing grant qualification
  available_in_big_towns_percentage = party_stats[province_id][:big_towns].to_f / province_stats[province_id][:big_towns].to_f
  wins_in_big_towns_percentage = party_stats[province_id][:got_seats_in_big_towns].to_f / party_stats[province_id][:big_towns].to_f

  if available_in_big_towns_percentage < 0.5 || wins_in_big_towns_percentage < 0.5
    grants[province_id][:mailing] = 0 # Gone
  end
end

# Display results
puts "ID Provincia,Subvención,Límite,Papeletas,Población,Censo,Gasto extra provincias"
total = { grant: 0, limit: 0, mailing: 0, population: 0, census: 0}
grants.each_key do |province_id|
  total[:grant] += grants[province_id][:grant]
  total[:limit] += grants[province_id][:limit]
  total[:mailing] += grants[province_id][:mailing]
  total[:population] += grants[province_id][:population]
  total[:census] += grants[province_id][:census]

  puts  "#{province_id},#{grants[province_id][:grant]},#{grants[province_id][:limit]}," \
        "#{grants[province_id][:mailing]},#{grants[province_id][:population]},#{grants[province_id][:census]}," \
        "#{grants[province_id][:extra_province_spending]}"
end

puts
puts  "TOTAL:\nSubvención: #{total[:grant]}\nLímite: #{total[:limit]}\nPapeletas: #{total[:mailing]}"

