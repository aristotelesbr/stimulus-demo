# frozen_string_literal: true

require 'bundler/setup'
require 'erb'
require 'lennarb'
require 'debug'

Bundler.require(:default)

require_relative 'plugins/render'

class CounterApp < Lennarb
  plugin :mount
  plugin :hooks
  plugin :render, templates_path: 'templates', default_layout: 'layout'

  use Rack::Static, urls: ['/assets'], root: 'public'

  before '*' do |_req, _res|
    puts '=' * 50
    puts "Request: #{Time.now}"
  end

  after '*' do |_req, _res|
    puts "Response: #{Time.now}"
    puts '=' * 50
  end

  get '/' do |_req, res|
    # res.html render('index')
    res.status = 200
    res.html render('index')
  end
end
