require 'csv'
require 'nokogiri'

# Nota sobre las cifras del censo electoral:
# Ejecutamos los scripts por primera vez durante la madrugada electoral, con el escrutinio al ~99.5%.
# Unos días después, ya al 100%, repetimos todo el proceso, y vemos que el censo ha subido en algunos
# municipios (<20), que no habían terminado el recuento en la primera pasada.
# El motivo es que calculamos el censo electoral como el número de votos más la abstención. Ésta última
# sí es final, porque viene -imagino- de las cifras de participación, que entiendo son finales desde que
# se cierran las mesas (aunque habría que comprobarlo en las próximas elecciones). En cambio el número de
# votos va subiendo según avanza el recuento, obviamente.
# Todo esto tiene poca relevancia práctica: estamos obligados a esperar a que termine el recuento para
# poder calcular las subvenciones, sí o sí, porque necesitamos el número de votos. Pero es importante
# aclarar que el censo tampoco es final, lo cual es contraintuitivo a primera vista.

town_data = CSV.open('town_data.csv', "w")
town_data << [
  'ID',
  'ID Region',
  'ID Provincia',
  'ID Municipio',
  'Municipio',
  'Población',
  'Censo',
  'Votos',
  'Votos nulos',
  'Votos en blanco',
  'Escrutado',
  'Fecha'
]

party_data = CSV.open('party_data.csv', "w")
party_data << [
  'ID Municipio',
  'ID Partido',
  'Siglas',
  'Nombre',
  'Votos',
  'Escaños'
]

CSV.foreach("pobmun14.csv") do |row|
  next if not row[0] =~ /^\d/   # Skip lines not starting with digit, i.e. header

  # Read pre-fetched data...
  municipality_id = "#{row[1]}#{row[2]}"
  begin
    input = File.open("staging/#{municipality_id}.html")
  rescue Errno::ENOENT => e
    puts "Skipping #{municipality_id}: file not found"
    next
  end

  # ...and extract basic metadata
  puts "Parsing #{municipality_id}..."
  page = Nokogiri::HTML(input)
  date = page.search("#fecha").text 
  percentage = page.search("#xescrutado span").text.gsub('%', '').strip
  total_votes = page.search("td.totvot").text.gsub('.', '')

  # Getting the abstention is trickier, but should be the second real row in the summary
  metadata_fields = page.search("#TVRESUMEN tr")
  if not metadata_fields[2].text =~ /Abstención/
    puts "ERROR: Unexpected 'abstention' field for #{url}"  
    continue
  end
  abstention = metadata_fields[2].search('td')[0].text.gsub('.', '')

  # Same with other fields
  if not metadata_fields[3].text =~ /Votos nulos/
    puts "ERROR: Unexpected 'votos nulos' field for #{url}"  
    continue
  end
  null_votes = metadata_fields[3].search('td')[0].text.gsub('.', '')

  if not metadata_fields[4].text =~ /Votos en blanco/
    puts "ERROR: Unexpected 'votos en blanco' field for #{url}"  
    continue
  end
  blank_votes = metadata_fields[4].search('td')[0].text.gsub('.', '')

  # Store the data we read
  town_data << ["#{municipality_id}"] + 
                row + 
                [total_votes.to_i+abstention.to_i, total_votes, null_votes, blank_votes, percentage, date]

  # Get the actual results
  page.search("#TVRESULTADOS tr").each_with_index do |result, i|
    next if i<2   # Skip first two rows

    party = result.search('th')[0]
    party_id = party.attr('id')[-4..-1]  # Last four digits
    short_name = party.text
    long_name = party.attr('title')

    votes = result.search('.vots')[0].text.gsub('.', '')
    seats = result.search('.cjal.dip')[0].text.gsub('.', '')

    party_data << ["#{municipality_id}", party_id, short_name, long_name, votes, seats]
  end

  input.close
end

town_data.close
party_data.close