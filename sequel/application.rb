Dir[File.expand_path('./entity') << '/*.rb'].each {|file| require file}
Dir[File.expand_path('./context') << '/*.rb'].each {|file| require file}
Dir[File.expand_path('./role') << '/*.rb'].each {|file| require file}
