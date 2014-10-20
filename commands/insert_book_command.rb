require_relative 'user_command'


class InsertBookCommand < UserCommand

	def initialize (data_source)
		super (data_source)
		@isbn  = ''
    	@title = ''
    	@price = ''
		@author = ''
    	@genre = ''
		@quantity = ''
	end

	def title 
		'Insert a new book.'
	end

   def input
   	   puts "Enter Book Information"
	   print "Book ISBN? "   
	   @isbn = STDIN.gets.chomp  
	   print "Book Title? "   
	   @title = STDIN.gets.chomp  
	   print "Book Author? "   
	   @author = STDIN.gets.chomp  
	   print "Book Genre? "   
	   @genre = STDIN.gets.chomp  
	   print "Book Price? "   
	   @price = STDIN.gets.chomp 
	   print "Book Quantity? "   
	   @quantity = STDIN.gets.chomp 
   end

    def execute

       
      a =   @data_source.findISBN @isbn
      if a
      	puts "A book with this ISBN already exists"
      	
      else
      	@data_source.addBook BookInStock.new(@isbn, @title, @author, @genre, @price, @quantity)
      	puts "Book was added!"
       
       
	end
end
end