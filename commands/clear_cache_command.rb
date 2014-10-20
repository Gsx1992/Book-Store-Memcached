require_relative 'user_command'

class ClearCacheCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@continue = ''
	end

	def title 
		'Clear Cache'
	end

   def input
		puts 'This will delete local and server cache'
		print "Continue? Y/N "   
		@continue = STDIN.gets.chomp.downcase
   end

    def execute
    	
    	if @continue.eql? 'y'
    	   @data_source.clearCache
		end

end
end