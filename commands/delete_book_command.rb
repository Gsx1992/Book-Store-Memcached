require_relative 'user_command'

class DeleteBookCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@isbn = ''
	end

	def title 
		'Delete book'
	end

   def input
		puts 'Delete book.'
		print "ISBN? "   
		@isbn = STDIN.gets.chomp  
   end

    def execute
	del = @data_source.deleteBook @isbn
	if del != 0
		puts "Book Deleted"
	else
	  puts "Error deleting book, or book does not exist"	
	end
end

end