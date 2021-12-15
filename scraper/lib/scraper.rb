require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'json'

class Scraper

  def scrape_url(url, date, debug) 

    config = YAML.load_file("config.yml")

    tools = Tools.new
    domain = tools.get_sitename(url, debug)

    if config['country'][domain] 
      tld = config['country'][domain]
    else
      tld = URI(url).hostname.split('.').last.upcase
    end
    puts "TLD: #{tld}" if debug

    if !config['cleanurl'][domain] 
      clean_url = url
    else
      clean_url = url.split('?')[url.split('?').length - 2]
    end

    document = tools.get_filename(url, domain, debug)

    puts "filename: #{document}" if debug

    html = URI.open(url, "Accept-Encoding" => "plain") 
    doc = Nokogiri::HTML(html)

    # read application/ld+json
    if doc.at("script[type='application/ld+json']")
      ld_json = doc.at("script[type='application/ld+json']").text
      if tools.valid_json?(ld_json)
        ld_meta =  JSON.parse(ld_json)
        if ld_meta.kind_of?(Array)
          ld_meta = ld_meta.first
        end
        puts "ld+json found" if debug
      end
    end

    # sitename
    if config['sitename'][domain]
      site_name = config['sitename'][domain]
      puts "Site Name: #{site_name} (config)" if debug
    elsif doc.at("meta[property='og:site_name']")
      site_name = doc.at("meta[property='og:site_name']")['content'].to_s.strip
      puts "Site Name: #{site_name} (og)" if debug
    else
      site_name = domain
      puts "Site Name: #{site_name} (domain)" if debug
    end

    # description
    if doc.at("meta[name='description']")
      description = doc.at("meta[name='description']")['content'].to_s.strip
      if description.match(/<span.*<\/span>/)
        description = description.match(/<span[^>]*>([^<]*)<\/span>/)[1]
      end
      puts "Description: #{description} (meta)" if debug
    elsif doc.at("meta[property='og:description']")
      description = doc.at("meta[property='og:description']")['content'].to_s.strip
      if description.match(//)
        description = description.match(/([^]*)/)[1]
      end
      if description.match(/\[…\]/)
        description = description.match(/([^\[…\]]*\[…\])/)[1].strip
      elsif description.match(/…/)
        description = description.match(/([^…]*…)/)[1].strip
      end
      puts "Description: #{description} (og)" if debug
    else 
      description = ""
      puts "Description not found" if debug
    end

    if config['description'][domain] and description.include? "/"
      description = description[0..description.rindex("/")-1].strip
    end

    # date
    if ld_meta and ld_meta['datePublished']
      published_time = ld_meta['datePublished'].to_s
    elsif doc.at("meta[name='publish-date']")
      published_time = doc.at("meta[name='publish-date']")['content'].to_s.strip
      puts "Date: #{published_time} (meta publish-date)" if debug
    elsif doc.at("meta[name='date']")
      published_time = doc.at("meta[name='date']")['content'].to_s.strip
      puts "Date: #{published_time} (meta date)" if debug
    elsif doc.at("meta[property='article:published_time']")
      published_time = doc.at("meta[property='article:published_time']")['content'].to_s.strip
      puts "Date: #{published_time} (meta article:published_time)" if debug
    elsif doc.at(".date-created") 
      published_time = doc.at(".date-created").text.to_s.strip
      puts "Date: #{published_time} (class:date-created)" if debug
    end

    if doc.at("meta[name='last-modified']")
      last_modified = doc.at("meta[name='last-modified']")['content'].to_s.strip
      last_modified = DateTime.parse(last_modified).strftime("%s")
      published = DateTime.parse(published_time).strftime("%s")
      if last_modified < published
        puts "last-modified earlier than published_time"
        published_time = doc.at("meta[name='last-modified']")['content'].to_s.strip
      end
    end

    if published_time
      published_time.gsub! '- ', '-'
    end

    if date and published_time
      if date != DateTime.parse(published_time.strip).strftime("%Y-%m-%d")
        puts "date #{date} not equal to published_time #{published_time}"
      end
    elsif date and !published_time
      puts "no pubished_time found" if debug
      published_time = date
    elsif !date and !published_time
      puts "no date found"
      exit 1
    end

    tags = Array.new
    domaintag = ""
    if config['tag'][domain]
      tags.push(config['tag'][domain])
      domaintag = config['tag'][domain]
    else
      domaintag = site_name.downcase
    end
 
    published_date = DateTime.parse(published_time.strip)
    date  = published_date.strftime("%Y-%m-%d")

    filename = date + "-" + domain + "_" + document

    # subtitle
    #elsif doc.at("meta[property='og:title']") and config['subtitle'][domain] and config['subtitle'][domain] != "ignore-og"
    subtitle = ""
    if doc.at("meta[property='og:title']")
      subtitle = doc.at("meta[property='og:title']")['content'].to_s.strip
      puts "Title: :#{subtitle}: (meta og:title)" if debug
    elsif doc.at("meta[property='og:title']") and subtitle == ""
      subtitle = doc.at("meta[property='og:title']")['content'].to_s.strip
      puts "Title: :#{subtitle}: (meta og:title)" if debug
    elsif ld_meta and ld_meta['headline'] and subtitle == ""
      subtitle = ld_meta['headline']
      puts "Title: :#{subtitle}: (ld_meta headline)" if debug
    elsif doc.at("/html/head//title") and subtitle == ""
      subtitle = doc.xpath("/html/head/title").first.text.strip.chomp
      puts "Title: :#{subtitle}: (head title)" if debug
    elsif doc.xpath("/html/body//h1") and subtitle == ""
      subtitle = doc.xpath("/html/body//h1").first.text.strip.chomp
      puts "Title: :#{subtitle}: (first h1)" if debug
    elsif doc.xpath("/html/body//h2") and subtitle == ""
      subtitle = doc.xpath("/html/body//h2").first.text.strip.chomp
      puts "Title: :#{subtitle}: (first h2)" if debug
    else
      puts "no title found"
      exit 1
    end

    if config['subtitle'][domain] && config['subtitle'][domain] == 'h2'
      subtitle = doc.xpath("/html/body//h2").first.text.strip.chomp
      puts "Change title to: #{subtitle} cause of h2" if debug
    end

    if config['subtitle'][domain] && config['subtitle'][domain] == 'h1'
      subtitle = doc.xpath("/html/body//h1").first.text.strip.chomp
      puts "Change title to: #{subtitle} cause of h1" if debug
    end

    if config['subtitle'][domain] && config['subtitle'][domain] == 'last'
      subtitle.gsub!(/[\s]+[|][\s]+.*$/, "")
      puts "Change title to: #{subtitle} cause of last" if debug
    end

    if config['subtitle'][domain] && config['subtitle'][domain] == 'last›'
      subtitle = subtitle[0..subtitle.rindex("›")-1] if subtitle.include? "›"
      subtitle.strip!
      puts "Change title to: #{subtitle} cause of last>" if debug
    end

    if config['subtitle'][domain] && config['subtitle'][domain] == 'last–'
      subtitle = subtitle[0..subtitle.rindex("–")-1] if subtitle.include? "–"
      subtitle.strip!
      puts "Change title to: #{subtitle} cause of last-" if debug
    end

    if config['subtitle'][domain] && config['subtitle'][domain] == 'last-'
      subtitle = subtitle[0..subtitle.rindex("-")-1] if subtitle.include? "-"
      subtitle.strip!
      puts "Change title to: #{subtitle} cause of last-" if debug
    end

    if config['subtitle'][domain] && config['subtitle'][domain] == 'last2-'
      subtitle = subtitle[0..subtitle.rindex("-")-1] if subtitle.include? "-"
      subtitle = subtitle[0..subtitle.rindex("-")-1] if subtitle.include? "-"
      subtitle.strip!
      puts "Change title to: #{subtitle} cause of last2-" if debug
    end

    #puts Encoding.name_list
    if subtitle.match(/Ã¤/)
      puts "Converting from Windows-1252 to UTF-8"
      subtitle.encode!('Windows-1252', 'UTF-8')
      puts "Change title to: #{subtitle}" if debug
    end

    if description.match(/Ã¤/)
      puts "Converting from Windows-1252 to UTF-8"
      description.encode!('Windows-1252', 'UTF-8')
      puts "Change description to: #{description}" if debug
    end

    content = ''
    if config['content'][domain] and config['content'][domain] == 'md'
      content = URI.open("#{url}.md", "Accept-Encoding" => "plain").read
      if content.match(//)
        content.gsub!(//,"")
      end
    end

    #title = '' if not (title.force_encoding("UTF-8").valid_encoding?)
    #title = '' if not (title.force_encoding("UTF-8").valid_encoding?)
    #title = title.chars.select(&:valid_encoding?).join
    #puts "Title: :" + title.delete!("^\u{0000}-\u{007F}") + ":"
    #puts "Title: :" + title.strip_control_characters + ":"
    #puts "Title: :" + title.strip_control_and_extended_characters + ":"

    site_data = Hash.new

    site_data['date'] = date
    site_data['redirect'] = clean_url
    site_data['title'] = site_name
    site_data['subtitle'] = subtitle.gsub(/'/, "’")
    site_data['country'] = tld
    site_data['categories'] = []
    site_data['tags'] = tags
    site_data['filename'] = filename
    site_data['domaintag'] = domaintag
    site_data['description'] = description.gsub(/'/, "’")
    site_data['content'] = content

    return site_data

  end
end
