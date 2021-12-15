#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'yaml'

url = "https://brownstone.org/articles/more-than-400-studies-on-the-failure-of-compulsory-covid-interventions/"

html = URI.open(url, "Accept-Encoding" => "plain")
doc = Nokogiri::HTML(html)

rows = doc.xpath('//table/tbody/tr')
details = rows.collect do |row|
  detail = {}
  [
    [:credit, 'td[1]/a/@href'],
    [:title, 'td[1]/a/text()'],
    [:rest, 'td[1]/text()'],
    [:description, 'td[2]/text()'],
  ].each do |name, xpath|
    if name == :description
      detail[name] = row.at_xpath(xpath).to_s.strip.delete_prefix('“').delete_suffix(' ').delete_suffix('”')
    elsif name == :title
      detail[name] = row.at_xpath(xpath).to_s.strip.delete_suffix(',')
    else
      detail[name] = row.at_xpath(xpath).to_s.strip
    end
  end
  detail
end

incr = 1
details.each do |row|
  content = %{---
date:        20xx-xx-xx
title:       
authors:     ''
en:
  subtitle:    '#{row[:title]}'
  description: '#{row[:description]}'
de:
  subtitle:    ''
  description: ''
group:       ""
credit:      #{row[:credit]}
link:        #{row[:credit]}
---
<object data="{{ page.link }}" style='height:calc(100vh - 400px); width: 100%' type='application/pdf'></object>%
}
  File.write("kerstin/#{incr}.md", content)
  incr += 1
end
