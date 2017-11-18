require 'sequel'
DB = Sequel.mysql('hana9_development', :host=> "192.168.99.1", :user=> "root")