require 'sequel'
DB = Sequel.mysql('hana9_test', :host=> "192.168.99.1", :user=> "root")