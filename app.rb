# app.rb
require 'sinatra'
require 'nokogiri'
require 'json'
require 'fileutils'
require 'pry'

set :public_folder, 'public'

helpers do
  def anonymize_name(name)
    last_name = name.split(" ").last
    first_name = name.split(" ").first
    "#{first_name} #{last_name[0]}."
  end
end

get '/' do
  erb :form
end

post '/upload' do
  if params[:file] && (tempfile = params[:file][:tempfile]) && (name = params[:file][:filename])
    FileUtils.mkdir_p('./public/uploads')
    target = "./public/uploads/#{name}"
    File.open(target, 'wb') { |f| f.write(tempfile.read) }
    doc = Nokogiri::HTML(File.read(target))
    File.delete(target)
    erb :results, locals: { runners: parse_runners(doc), volunteers: parse_volunteers(doc) }
  else
    "No file selected"
  end
end

def parse_volunteers(doc)
  volunteers = []
  doc.css('.paddedb').first.search('a').each do |a|
    volunteers << a.text.strip
  end
  volunteers
end

def parse_runners(doc)
  runners = []
  unknown_count = 0

  doc.css('.Results-table tbody tr').each do |row|
    name = row.at_css('.Results-table-td--name').search('.compact').text.strip
    if name == "Nieznan(a)y"
      unknown_count += 1
      next
    end

    parkruns = row.at_css('.Results-table-td--name').search('.detailed').children.first.text.strip.split(" ").first.to_i
    time = row.at_css('.Results-table-td--time').search('.compact').text.strip

    pb = row.at_css('.Results-table-td--time').search('.detailed').text.strip == "Nowy PB!"
    debiut = row.at_css('.Results-table-td--time').search('.detailed').text.strip == "Debiutant"
    category = row.at_css('.Results-table-td--ageGroup').search('.compact').text.strip
    sex = row.at_css('.Results-table-td--gender').search('.compact').text.strip

    runners << {
      name: name,
      time: time,
      category: category,
      sex: sex,
      parkruns: parkruns,
      personal_best: pb,
      debiut: debiut,
    }
  end
  { runners: runners, unknown_count: unknown_count }
end