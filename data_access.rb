require_relative 'book_in_stock'
require_relative 'database'
require 'dalli'

  class DataAccess 
  
    def initialize db_path
        @database = DataBase.new db_path
        @Remote_cache = Dalli::Client.new('localhost:11211')
        @Local_cache = {}
    end
    
    def start 
    	 @database.start 
    end

    def stop
    end
    
    def addBook book
       @database.addBook book
    end
   
    def deleteBook isbn
            
            @Remote_cache.delete "v_#{isbn}"
            @Local_cache.delete "#{isbn}"
            @Local_cache.delete "v_#{isbn}"
            @database.deleteBook isbn
    end

     def findISBN isbn
        local = @Local_cache["v_#{isbn}"]
        version = @Remote_cache.get "v_#{isbn}"
        book = nil
        if (local && version && local.eql?(version)) 
        
          BookInStock.from_cache @Local_cache["#{isbn}"]
  
        elsif version.to_i > local.to_i 
      
          serial = @Remote_cache.get "#{version}_#{isbn}"
          @Local_cache["v_#{isbn}"] = version
          @Local_cache["#{isbn}"] = serial
          BookInStock.from_cache @Local_cache["#{isbn}"]

        else   
          if isbn
             book = @database.findISBN isbn
                if(book)
                    @Local_cache["v_#{isbn}"] = 1
                    @Local_cache["#{isbn}"] = book.to_cache
                    @Remote_cache.set "v_#{isbn}",1
                    @Remote_cache.set "1_#{isbn}", book.to_cache
                    BookInStock.from_cache @Local_cache["#{isbn}"]
                 else
                    nil
                end
          end
      end
    end

    def updateBook book
        @database.updateBook book
        inRemote = @Remote_cache.get "v_#{book.isbn}"
        if inRemote
            version = @Remote_cache.get "v_#{book.isbn}"
            @Remote_cache.set "#{version + 1}_#{book.isbn}", book.to_cache
            @Remote_cache.set("v_#{book.isbn}", version+1)
            inLocal = @Local_cache["v_#{book.isbn}"]
            if inLocal
                @Local_cache["v_#{book.isbn}"] = version+1
                @Local_cache["#{book.isbn}"] = book.to_cache
            end
        end
    end

     def authorSearch author
         
       localAuthor = @Local_cache["bks_#{author}"] 
       serverAuthor = @Remote_cache.get "bks_#{author}"
       bookString = []
       isbnArray = []
   
        if (localAuthor && serverAuthor && localAuthor.eql?(serverAuthor)) 
           bookString = localAuthor.split(":")
            bookString.each do |isbn| 
            if (isbn != '' && findISBN(isbn) != nil)
                isbnArray << isbn 
            end
            end
        updateAll isbnArray, author
        
        elsif serverAuthor!= nil
            bookString = serverAuthor.split(":")
                bookString.each do |isbn| 
                    if (isbn != '' && findISBN(isbn) != nil)
                isbnArray << isbn 
                    end
             end
            updateAll isbnArray, author
        else
            newComplexKey author
        end
    end
    
    def updateAll isbnArray, author
        
       cKeys = []
       complexBooks = []
       isbnString = ""

        cKeys = complexKeyExists isbnArray
        isbnArray.each do |isbn| 
                    a = findISBN isbn
                    complexBooks << a.to_cache.insert(0, ":")
                    isbnString += isbn.insert(0, ":")
        end

            checkLocal =  @Local_cache["#{author}_#{cKeys}"]
            checkServer =  @Remote_cache.get "#{author}_#{cKeys}"
            if checkLocal != nil
                booksFromComplexKey complexBooks
            elsif checkServer != nil
                complexBooks = booksFromComplexKey complexBooks
                @Local_cache["bks_#{author}"] = isbnString
                @Local_cache["#{author}_#{cKeys}"] = complexBooks
                @Local_cache["#{author}_#{cKeys}"]
            else
                @Local_cache["bks_#{author}"] = isbnString
                @Local_cache["#{author}_#{cKeys}"] = complexBooks
                @Remote_cache.set "bks_#{author}",isbnString
                @Remote_cache.set "#{author}_#{cKeys}",complexBooks
                booksFromComplexKey @Local_cache["#{author}_#{cKeys}"]
            end

    end

    def newComplexKey author
       basicISBN = ""
       versionISBN = ""
       bookString = []
            dc = @database.authorSearch author
            if dc
            dc.each do |book|
                     a =  findISBN book.isbn
                     if(a != "" || a != nil)
                        version = @Local_cache["v_#{book.isbn}"]
                        if version
                            basicISBN += "#{book.isbn}".insert(0, ":")
                            versionISBN += "#{version}_#{book.isbn}".insert(0, ":")
                            bookString << bookList= book.to_cache.insert(0, ":") #why is this here?
                        end
                    end
                end
            @Local_cache["bks_#{author}"] = "#{basicISBN}"
            @Local_cache["#{author}_#{versionISBN}"] = bookString
            @Remote_cache.set "bks_#{author}", "#{basicISBN}"
            @Remote_cache.set "#{author}_#{versionISBN}", bookString
            booksFromComplexKey @Local_cache["#{author}_#{versionISBN}"]
            end
    end

    def complexKeyExists isbnList
        demBooks = ""
        isbnList.each do |isbn|
              a =  findISBN isbn
              if a != nil
                  version = @Local_cache["v_#{isbn}"]
                  demBooks += "#{version}_#{isbn}".insert(0, ":")
              end
          end
         demBooks
    end
    def booksFromComplexKey books
        bookArray = []
         books.each do |book|
               if book != nil
                book.slice!(0)
                newBook =  BookInStock.from_cache book
                bookArray << newBook
               end
         end
         bookArray
    end
    def clearCache
       @Local_cache.clear
       @Remote_cache.flush
    end
end 

