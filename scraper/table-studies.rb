#!/usr/bin/env ruby

require 'yaml'

require File.join(__dir__, 'lib/tools')
files = Dir.glob("../_studies/*.md")

def build_network(files)

  studies = Hash.new
  files.each do |filename|

    meta_data = YAML.load_file(filename)

    file_name = filename.split('/').last
    file_name = File.basename(file_name,File.extname(file_name))

    studies[file_name] = Hash.new
    studies[file_name]['date'] = meta_data['date']
    studies[file_name]['publisher'] = meta_data['title']
    studies[file_name]['authors'] = meta_data['authors']
    studies[file_name]['titel'] = meta_data['de']['subtitle']
    studies[file_name]['beschreibung'] = meta_data['de']['description']
    studies[file_name]['title'] = meta_data['en']['subtitle']
    studies[file_name]['description'] = meta_data['en']['description']
    studies[file_name]['group'] = meta_data['group']
    studies[file_name]['credit'] = meta_data['credit']

  end

  studies = studies.sort_by { |k, v| v['date'] }

  studies_file_name = "../tables/studies.txt"
  fileHandle = File.new(studies_file_name, "w+")
  if fileHandle
    fileHandle.syswrite("|File|URL|\n")
    fileHandle.syswrite("|----|---|\n")
    studies.sort.each do |node, values|
      fileHandle.syswrite("|#{node}.md|#{values['credit']}|\n")
    end
  else
    puts "Not able to access the file"
  end


  studies_file_name = "../tables/studies.csv"
  CSV.open(studies_file_name, "wb") do |csv|
    csv << ["filename", "date", "publisher", "authors", "title", "beschreibung", "title", "description", "group", "credit"]
    studies.sort.each do |node, values|
      csv << ["#{node}.md", values['date'], values['publisher'], values['authors'], values['titel'], values['beschreibung'], values['title'], values['description'], values['group'], values['credit']]
    end
  end

end

build_network(files)

