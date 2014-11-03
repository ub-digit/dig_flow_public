require 'pathname'
require "#{Rails.root}/app/assets/sources/source_base"
require "#{Rails.root}/app/assets/sources/manuscript"
Pathname.new("#{Rails.root}/app/assets/sources").children.each do |child|
  require child if child.file? && child.extname == "rb"
end
