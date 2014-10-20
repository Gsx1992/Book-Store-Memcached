require_relative 'user_command'

class AuthorSearchCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@author = ''
	end

	def title 
		'Search by author.'
	end

   def input
   	   puts 'Search by Author.'
	   print "Author name? "   
	   @author = STDIN.gets.chomp  
   end

    def execute
       authors = @data_source.authorSearch(@author)
       if authors.length != 0
       	authors.each {|b| puts b }
       else
       	puts "No books could be found for an author with that name"
       end
	end
end

