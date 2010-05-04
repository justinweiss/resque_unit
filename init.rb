# Include hook code here
if RAILS_ENV == 'test'
  require 'resque_unit'
end
