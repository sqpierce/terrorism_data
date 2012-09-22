#!/usr/bin/env ruby

RAILS_ENV = 'development'
require File.dirname(__FILE__) + '/../config/environment'

Variable.find(:all).each do |v|
  puts "Variable is #{v.inspect}"
end
